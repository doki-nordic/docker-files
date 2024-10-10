#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
	defcache=~/.cache/cwget
else
	defcache=/var/cache/cwget
fi

mkdir -p $defcache
rm -f $defcache/tmp-*

args=${@:1:$#-2}
url=${@:$#-1:1}
file=${@: -1}
hash=`echo $url | xargs echo -n | md5sum | cut -f 1 -d " " | xargs echo -n`

if [ -f /var/cache/cwget/$hash ]; then
	echo Coping from cache /var/cache/cwget/$hash
	cp /var/cache/cwget/$hash $file
elif [ -f ~/.cache/cwget/$hash ]; then
	echo Coping from cache ~/.cache/cwget/$hash
	cp ~/.cache/cwget/$hash $file
else
	wget $args -O $defcache/tmp-$hash $url || rm -Rf $defcache/tmp-$hash || true
	mv $defcache/tmp-$hash $defcache/$hash
	cp $defcache/$hash $file
fi

