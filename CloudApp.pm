#! /usr/bin/env perl
###################################################
#
#  Copyright (C) 2016 Djordje Ungar contact@djordjeungar.com
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Shutter is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
###################################################

package CloudApp;

use lib $ENV{'SHUTTER_ROOT'}.'/share/shutter/resources/modules';

use utf8;
use strict;
use POSIX qw/setlocale/;
use Locale::gettext;
use Glib qw/TRUE FALSE/;
use Data::Dumper;
use File::Basename;
use Tie::IxHash; # Preserve insertion order of the hash

use Shutter::Upload::Shared;
our @ISA = qw(Shutter::Upload::Shared);

my $d = Locale::gettext->domain("shutter-plugins");
$d->dir( $ENV{'SHUTTER_INTL'} );

my %upload_plugin_info = (
    'module'                        => "CloudApp",
    'url'                           => "https://cl.ly/",
    'registration'                  => "https://my.cl.ly/register",
    'name'                          => "CloudApp",
    'description'                   => "Upload screenshots to CloudApp",
    'supports_anonymous_upload'     => FALSE,
    'supports_authorized_upload'    => TRUE,
    'supports_oauth_upload'         => FALSE,
);

binmode( STDOUT, ":utf8" );
if ( exists $upload_plugin_info{$ARGV[ 0 ]} ) {
    print $upload_plugin_info{$ARGV[ 0 ]};
    exit;
}


#don't touch this
sub new {
    my $class = shift;

    #call constructor of super class (host, debug_cparam, shutter_root, gettext_object, main_gtk_window, ua)
    my $self = $class->SUPER::new( shift, shift, shift, shift, shift, shift );

    bless $self, $class;
    return $self;
}

#load some custom modules here (or do other custom stuff)    
sub init {
    my $self = shift;

    use JSON;                   #example1
    use LWP::UserAgent;         #example2
    use HTTP::Request::Common;  #example3

    return TRUE;    
}

#handle 
sub upload {
    my ( $self, $upload_filename, $username, $password ) = @_;

    $self->{_filename} = $upload_filename;
    $self->{_username} = $username;
    $self->{_password} = $password;

    utf8::encode $upload_filename;
    utf8::encode $password;
    utf8::encode $username;

    # Digest auth realm
    my $realm = 'Application';

    my $json_coder = JSON::XS->new->allow_nonref;

    my $ua = LWP::UserAgent->new(
        'timeout'    => 20,
        'keep_alive' => 10,
        'env_proxy'  => 1,
    );

    # Debug responses
    # $ua->add_handler( response_header => sub { my($response, $ua, $h) = @_; print " Response: " . Dumper($response) . "\n"; }, owner => 'myreshandler');

    # if username/password are provided
    if ( $username ne "" && $password ne "" ) {
        eval {
            $ua->credentials("my.cl.ly:443", $realm, $username, $password);

            # To make the CloudApp process as fast as possible, files are
            # uploaded directly to S3. The process involves 3 steps: 
            #  1. making an initial request to CloudApp, retrieving a few parameters,
            #  2. Passing those parameters along with the file itself to S3
            #  3. Pinging back the CloudApp servers, informing them that the upload is done

            # 1. Request to upload
            my $name = basename($upload_filename);
            my @params = (
                'https://my.cl.ly/v3/items',
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'Content' => $json_coder->encode([ name => $name ]),
            );
            my $req1 = HTTP::Request::Common::POST(@params);
            my $rsp1 = $ua->request($req1);
            if ($rsp1->is_success) {
                my $content = $rsp1->decoded_content;
                $content =~ s/Infinity/"Infinity"/g;
                my $response1 = decode_json($content);
                my $slug = $response1->{'slug'};
                my $s3 = $response1->{'s3'};

                # 2. Upload the file to S3
                # The order of the params is important.
                # 'File' needs to be the last param.
                my %oparams;
                tie %oparams, 'Tie::IxHash';
                foreach my $key ( keys %{$s3}) {
                    $oparams{$key} = $s3->{$key};
                }
                $oparams{'file'} = [ $upload_filename => $name ];
                @params = (
                    $response1->{'url'},
                    'Content_Type' => 'multipart/form-data',
                    'Content' => [%oparams],
                );

                my $req2 = HTTP::Request::Common::POST(@params);
                my $rsp2 = $ua->request($req2);
                # Status: 303 See Other
                if ($rsp2->code == 303) {
                    # 3. Ping back the CloudApp servers
                    # The thing is, S3 redirects back to CloudApp servers automatically, 
                    # but over http not https, and hence, our digest authentication fails. 
                    # Luckily, we can ping the server manually using the location url from the previous response.
                    # But we also need to update the port in our credentials.
                    $ua->credentials("my.cl.ly:80", $realm, $username, $password);
                    @params = (
                        $rsp2->header('location'),
                        'Accept' => 'application/json',
                    );
                    my $req3 = HTTP::Request::Common::GET(@params);
                    my $rsp3 = $ua->request($req3);
                    if ($rsp3->is_success) {
                        my $content3 = decode_json($rsp3->decoded_content);
                        $self->{_links}->{'direct_link'} = $content3->{'content_url'};
                    }
                    $self->{_links}{'status'} = $rsp3->status_line;
                } else {
                    $self->{_links}{'status'} = $rsp2->code;
                }
            } else {
                $self->{_links}{'status'} = $rsp1->code;
            }
        };
        if($@){
            $self->{_links}{'status'} = $@;
            return %{ $self->{_links} };
        }
        if($self->{_links}{'status'} == 999){
            return %{ $self->{_links} };
        }

    }

    #and return links
    return %{ $self->{_links} };
}

1;
