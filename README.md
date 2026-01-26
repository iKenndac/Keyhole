<p align="center"><img src="Documentation%20Images/KeyholeIcon.png?raw=true" width="256" /></p>

## Keyhole

Have you ever been annoyed by your Mac's media keys triggering a random video in your web browser, doing something else weird, or by them doing… nothing? Even though your music player is *right there*?

Me too! And so Keyhole was born.

Keyhole is simple app to keep your media keys under control — simply choose which media player you'd like your media keys to control, and… well, that's it. Your media keys will control that app. Simple!

This GitHub repository is the project's open-source home. If you'd just like to download the app and use it, you'll be best served by [Keyhole's page on my website](https://ikennd.ac/keyhole/).

### App Icon

Keyhole's icon was created by [Matthew Skiles](https://matthewskiles.com).

It's important to note that Keyhole's open-source license **does not** extend to the app's icon, and it must not be used for anything but *this* version of Keyhole (owned and published by Daniel Kennett) without permission.

### Help Wanted: Translations

Keynote currently supports English. If you'd like to support Keyhole by adding your language, that'd be wonderful! Most of the app's strings are in the `Localizable.xcstrings` file in the project, and I'll happily merge pull requests adding a new language. 

If you'd like to help but don't know what those words mean, [open up an issue](https://github.com/iKenndac/Keyhole/issues) and I can help you get started.

### Supported Media Players

Keyhole currently supports [Cog][cog], [Doppler][doppler], [Spotify][spotify], and the Music app built-in to your Mac.

[cog]: https://cog.losno.co
[doppler]: https://brushedtype.co/doppler/
[spotify]: https://spotify.com

### How To Ask For A New Media Player

**🚨🚨🚨 IMPORTANT: 🚨🚨🚨** You **must** read this first before opening an issue asking for support for a new media player app!

I'd be happy to support your favourite media player **if** it is capable of being supported. To be supported, the media player must be a "real" Mac app (i.e., it can't be something running in your web browser), and it must be capable of receiving commands from other apps via some sort of automation system.

Keyhole already has robust support for AppleScript-capable ("scriptable") apps, so if your media player is scriptable, adding support *should* be reasonably easy.

How to tell if an app is scriptable: 

- Open the **Script Editor** app on your Mac, then choose **File** → **Open Dictionary…**

- Find the media player app in the list of apps presented to you and click **Choose**.

- In the window that appears, look for commands like `playpause`, `previous track`, `next track`, etc. You may have to look through one or more "suites" of commands — for example, Spotify has its commands under the "Spotify Suite".

If you you see appropriate commands, that's great news! Adding support should be easy. [Open up an issue](https://github.com/iKenndac/Keyhole/issues) using the **Request Support for a Media Player** template and fill out the form. Please note that since this is a free app and I'm donating my time to keep it maintained, I can't promise I'll get to it immediately.

If you **don't** see appropriate commands, or Script Editor doesn't allow you to open a dictionary for the app, unfortunately adding support for it to Keyhole will be somewhere between hard and impossible. If this is the case, please contact the app's developers directly to see if it can be automated, or if automation support can be added. Please **do not open an issue if an app can't be supported**. Once the developer for that app adds automation support, we can then add it to Keyhole.


