Shutter Upload Plugin for CloudApp
==================================

[Shutter](http://shutter-project.org/) is an awesome screenshot tool for Linux.  [CloudApp](http://getcloudapp.com) is an awesome screenshot sharing tool, but it lacks a Linux client.  This plugin tries to solve that problem.

##Installation

Download `CloudApp.pm` and extract it to Shutter upload plugins directory. On Ubuntu, thats:
```
/usr/share/shutter/resources/system/upload_plugins/upload/
```

Restart Shutter. You can force plugin reinitialization by clearing the cache, like so:
```
shutter --clear_cache
```

Enter your CloudApp username/password in Edit->Preferences->Upload->CloudApp:
![Shutter plugin preferences](https://cl.ly/1B442j0o3B34/shutter.prefs.png)

