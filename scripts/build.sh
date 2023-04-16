#!/usr/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))

docker build -t lovr-apps:latest $SCRIPT_DIR
