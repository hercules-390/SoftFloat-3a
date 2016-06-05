#! /usr/bin/env bash
if [[ "$TRAVIS_OS_NAME" != "osx" ]]; then exit ; fi

rm  -rf .travis_build.dir
mkdir   .travis_build.dir
cd      .travis_build.dir
cmake   ../ -DCMAKE_INSTALL_PREFIX=$HOME/noinst -DCMAKE_BUILD_TYPE=Release
make
exit