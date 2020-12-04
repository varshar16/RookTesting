#!/bin/bash -e

echo "Installing ceph"
git clone --recursive https://github.com/ceph/ceph.git
cd ~/ceph
git submodule update --force --init --recursive
./install-deps.sh
./do_cmake.sh
cd build
make -j$(nproc)
