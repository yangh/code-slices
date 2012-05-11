#!/bin/sh

PLUGINPATH="`pwd`/`dirname $0`"
GEDIT2_PLUGPATH="$HOME/.gnome2/gedit/plugins/"

mkdir -p $GEDIT2_PLUGPATH
ln -s -f $PLUGINPATH/android-dumpstate-viewer.gedit-plugin $GEDIT2_PLUGPATH
ln -s -f $PLUGINPATH/dumpstate-viewer.py $GEDIT2_PLUGPATH

