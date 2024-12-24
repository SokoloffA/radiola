# Radiola - lightweight Internet radio player for macOS.

[![Generic badge](https://img.shields.io/badge/-Download-blue.svg?style=for-the-badge)](https://github.com/SokoloffA/radiola/releases)

## About
While most music players provide an option for Internet streaming, you might not always want to run your resource hungry media player.

Radiola is a lightweight Internet radio player for macOS, it's located in the status bar and allows you to listen to Internet radio stations quickly and without complications.

Most often, you use the **menu in the status bar**.

![Radiola menu](https://user-images.githubusercontent.com/854935/182122940-a42de641-3377-4728-bd95-b3b6e54f2ea9.png)  


In the **station window** you can both manage the station list and use it as an Internet radio player.

![Radiola Main Window](https://user-images.githubusercontent.com/854935/182121740-67f47916-85a7-4d3d-8742-a0ea06c511c9.png)


The **history window** allows you to find out what song is playing now or has played recently.

![Radiola History Window](https://user-images.githubusercontent.com/854935/182125735-6dd7494a-c899-471e-a617-1dd09dbe497c.png)

## Radiola features
* Very light, less than 2 megabytes.
* Easy to use, just click on the icon in the status bar, select station and enjoy.
* Absolutely free.

___
## Installation
You can download the latest version of the program from the [Releases page](https://github.com/SokoloffA/radiola/releases).

Or you can install the program using Homebrew. 
The program has not currently reached the popularity threshold for inclusion in the official Homebrew repositories. You can help by giving the [Radiola](https://github.com/SokoloffA/radiola) project a star and/or start a watch. Right now you can use my *Tap* to install the program using Homebrew.

First, make sure you have installed [`Homebrew`](https://brew.sh) if you haven't yet.

Then add the Radiola tap. You only need to do this once.
```
brew tap sokoloffa/radiola
```

Install the program
```
brew install --cask --no-quarantine radiola
```

*Why do you need the **"--no-quarantine"** parameter?
macOS marks all files downloaded from the Internet as quarantined. When you run a quarantined program, macOS displays the message **"Radiola can’t be opened because Apple cannot check it for malicious software"**. 
Of course, the new program is downloaded from the Internet, so don't mark it as quarantined using the **"--no-quarantine"** option. 
The **"--no-quarantine"** option is also required when upgrading (`brew upgrade`) or reinstalling (`brew reinstall`).





## If you want to thank me
* You can star this project
* Or advise the program on social networks

