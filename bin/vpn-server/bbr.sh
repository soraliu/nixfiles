#!/usr/bin/env bash

tmp_file=/tmp/tcpx.sh

if [ ! -f $tmp_file ]; then
  wget -O $tmp_file "https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh"
  chmod +x $tmp_file
fi

. $tmp_file
