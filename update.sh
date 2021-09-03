#!/bin/bash

current_path="$(pwd)"

cd /usr/local/lib/python3.8/dist-packages/

sudo rm -rf gmatch4py GMatch4py-0.2.5b*

cd $current_path

sudo pip3 install .
