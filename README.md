Alternative controller for the QuickDrawBot.

Requires a QuickDrawBot, available for sale as a kit or fully assembled here (http://www.quickdrawbot.com/).

The Raspberry Pi comes loaded with the default "Sketchy" controller software. Also open source, found here (https://github.com/MHAVLOVICK/Sketchy).

This project provides an alternative controller that allows finer control of the QuickDrawBot by using SVG files as the raw pathing data. It also provides a nicer web interface for interacting with your QuickDrawBot.


## Installation

Installation take just a few minutes. The overview is:

1. Install npm on the Raspberry Pi
1. Install this package
1. Restart

### Connect

Connect to your Raspberry Pi over SSH. Use putty on Windows or on OSX or Linux do:

    ssh pi@192.168.x.x

Where '192.168.x.x' is the IP of your Raspberry Pi. It should be same as the one you would use to access Sketchy.

The default password is `raspberry`.

#### Make some room

The default Raspberry Pi installation includes some large unused packages. Remove the `wolfram-engine` package to recover about 400 MB of precious space.

    dpkg --purge wolfram-engine

#### Install node.js and npm

I had trouble installing nodejs using apt-get, and compiling from source could literally take DAYS, so I used one of the pre-built binaries available here (https://gist.github.com/adammw/3245130)

I used this method:

    cd
    wget https://gist.github.com/raw/3245130/v0.10.24/node-v0.10.24-linux-arm-armv6j-vfp-hard.tar.gz
    cd /usr/local
    tar xzvf ~/node-v0.10.24-linux-arm-armv6j-vfp-hard.tar.gz --strip=1

#### Install this package via npm

    cd
    npm install -g vecdraw

#### Restart!

Restart the RasbperryPi

    shutdown -r now

When it boots up, you should be able to access this web app at http://192.168.x.x:8080/

## Preparing SVG Files
This library does not handle text and fonts in SVGs. So, if you would like your text to show up, you must first convert it to paths.

Tutorials
* Inkscape http://google.com/?q=convert+text+paths+inkscape
* Illustrator http://google.com/?q=convert+text+paths+illustrator

To utilize the data in an SVG file, we tesselate (convert curves to straight line segments) all the paths and shapes in the file.
