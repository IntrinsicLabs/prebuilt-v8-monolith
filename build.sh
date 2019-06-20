#!/usr/bin/env bash
set -e

WORKDIR=$(dirname $V8_DIR)
cd $WORKDIR

LIBFILE=$V8_DIR/out.gn/obj/libv8_monolith.a
if [ -f "$LIBFILE" ]; then
  zip -q -r prebuilt-v8-$TRAVIS_OS_NAME-$V8_VERSION.zip v8/include v8/out.gn
  mv prebuilt-v8-$TRAVIS_OS_NAME-$V8_VERSION.zip $TRAVIS_BUILD_DIR
  exit 0
fi

# https://gist.github.com/jaytaylor/6527607
function _timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }
TIMEOUT=timeout && [ "$(uname)" == "Darwin" ] && TIMEOUT=_timeout

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=PATH=$PATH:$WORKDIR/depot_tools

if [ ! -d "$V8_DIR/out.gn/x64.release" ]; then
  if [ ! -d "$V8_DIR/.git" ]; then
    rm -rf v8
    fetch v8
  fi
  cd v8
  git checkout $V8_VERSION
  gclient sync
  tools/dev/v8gen.py x64.release -- v8_monolithic=true v8_use_external_startup_data=false use_custom_libcxx=false
fi
cd $V8_DIR/out.gn/x64.release
echo "starting build"
$TIMEOUT 2400 ninja # 40 min timeout
cd $WORKDIR

zip -q -r prebuilt-v8-$TRAVIS_OS_NAME-$V8_VERSION.zip v8/include v8/out.gn
mv prebuilt-v8-$TRAVIS_OS_NAME-$V8_VERSION.zip $TRAVIS_BUILD_DIR
