#!/bin/bash
set -e

usage() {
cat <<EOF
Usage: $(basename "$0") [wget options...] <URL> <output_file>

Arguments:
  [wget options...]  Any options passed directly to wget (optional)
  URL                The file URL to download
  output_file        Path where the downloaded file should be saved

Description:
  Downloads a file using wget with a simple local cache. If the URL was
  downloaded before, the file is copied from the cache instead of being
  downloaded again.

Cache locations:
  ~/.cache/cwget     when run as normal user
  /var/cache/cwget   when run as root
EOF
}

if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

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

