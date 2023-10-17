#!/bin/bash

tar --exclude=_build \
    --exclude=*.tar.gz \
    --exclude=couch_data \
    --exclude=caddy_data \
    -cvf readingtree.tar.gz \
    ../readingtree.app
