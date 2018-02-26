#!/bin/sh
cd ..
jazzy \
  --clean \
  --config 'Scripts/jazzy.yml'

rm -rf build
