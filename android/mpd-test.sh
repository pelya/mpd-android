#!/system/bin/sh

env LD_LIBRARY_PATH=`pwd` HOME=/sdcard ./mpd -v --no-daemon --stderr mpd.conf
