#!/bin/bash
set -e

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

REQ_DIR=`dirname $MY_DOCKERS_DOCKERFILE`/_tmp/req

rm -Rf $REQ_DIR
mkdir -p $REQ_DIR/z
mkdir -p $REQ_DIR/n
touch $REQ_DIR/z/requirements.txt
touch $REQ_DIR/n/requirements.txt

find_file zephyr/scripts/requirements.txt
if [ ! -z "$_path" ]; then
	cp $_path/zephyr/scripts/*.txt $REQ_DIR/z
fi

find_file nrf/scripts/requirements.txt
if [ ! -z "$_path" ]; then
	cp $_path/zephyr/scripts/*.txt $REQ_DIR/n
fi
