#!/bin/bash
set -e

if [ ! -f ~/.my-dockers-startup/.startup_done ]; then
	mkdir -p ~/.cache
	sudo apt update
	sudo DEBIAN_FRONTEND=noninteractive apt install -y -qq /opt/nrf-command-line-tools/share/JLink_Linux_V794e_x86_64.deb --fix-broken
	touch ~/.my-dockers-startup/.startup_done
fi

find_file () {
	_path=. && [ -f $_path/$1 ] || \
	_path=.. && [ -f $_path/$1 ] || \
	_path=../.. && [ -f $_path/$1 ] || \
	_path=../../.. && [ -f $_path/$1 ] || \
	_path=../../../.. && [ -f $_path/$1 ] || \
	_path=../../../../.. && [ -f $_path/$1 ] || \
	_path=../../../../../.. && [ -f $_path/$1 ] || \
	_path=../../../../../../.. && [ -f $_path/$1 ] || \
	_path=../../../../../../../.. && [ -f $_path/$1 ] || \
	_path=../../../../../../../../.. && [ -f $_path/$1 ] || \
	_path=../../../../../../../../../.. && [ -f $_path/$1 ] || \
	_path=../../../../../../../../../../.. && [ -f $_path/$1 ] || \
	_path=../../../../../../../../../../../.. && [ -f $_path/$1 ] || \
	_path=../../../../../../../../../../../../.. && [ -f $_path/$1 ] || \
	_path=../../../../../../../../../../../../../.. && [ -f $_path/$1 ] || \
	_path=../../../../../../../../../../../../../../.. && [ -f $_path/$1 ] || \
	_path=
}

process_requirements() {
	mkdir -p ~/.my-req
	_hash_file=~/.my-req/`echo $2 | xargs echo -n | md5sum | cut -f 1 -d " " | xargs echo -n`
	_hash_cur=`cat $_hash_file 2> /dev/null || true`
	_hash_exp=`cat $1/$2 | md5sum | cut -f 1 -d " " | xargs echo -n`
	if [[ "$_hash_cur" != "$_hash_exp" ]]; then
		echo Installing dependencies from $1/$2
		pip install -r $1/$2
		echo -n $_hash_exp > $_hash_file
	fi
}

find_file zephyr/scripts/requirements.txt
if [ ! -z "$_path" ]; then
	process_requirements $_path zephyr/scripts/requirements.txt
	source $_path/zephyr/zephyr-env.sh
fi

find_file nrf/scripts/requirements.txt
if [ ! -z "$_path" ]; then
	process_requirements $_path nrf/scripts/requirements.txt
fi
