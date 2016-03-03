#!/bin/bash -e

# Build
./configure
make clean
make

# Test
./test.sh

# Package
strip rsync
mkdir -p install-root/usr/bin
cp rsync install-root/usr/bin/rsync-onapp

fpm -s dir -t deb -n rsync-onapp -v $ONAPPVER \
    --depends libacl1 \
    --depends libpopt0 \
    --depends zlib1g \
    -C install-root/ .
