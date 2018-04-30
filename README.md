Shutter Upload Plugin for CloudApp
==================================

[Shutter](http://shutter-project.org/) is an awesome screenshot tool for Linux.  [CloudApp](http://getcloudapp.com) is an awesome screenshot sharing tool, but it lacks a Linux client.  This plugin tries to solve that problem.

## Installation

Download `CloudApp.pm` and move it to the Shutter upload plugins directory, and make it executable.
On Ubuntu, that's:
```
cd /usr/share/shutter/resources/system/upload_plugins/upload
sudo mv ~/Downloads/CloudApp.pm .
sudo chown root:root CloudApp.pm
sudo chmod a+x CloudApp.pm
```

Restart Shutter. You can force plugin reinitialization by clearing the cache, like so:
```
shutter --clear_cache
```

Enter your CloudApp username/password in Edit->Preferences->Upload->CloudApp:

![Shutter plugin preferences](https://cl.ly/1B442j0o3B34/shutter.prefs.png)

## Usage

Take a Shutter screenshot as usual, and click export.

![Shutter export to CloudApp](https://cl.ly/3H46242g340T/shutter.export.png)

Wait for the image to upload, and copy the public URL.

![Shutter export completed](https://cl.ly/1K1i1f1Q1130/shutter.success.png)

That's it.
Enjoy.


