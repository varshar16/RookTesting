#!/bin/bash -e

echo "Installing ceph"
git clone --recursive https://github.com/ceph/ceph.git
cd ~/ceph
git submodule update --force --init --recursive
git remote add vr https://github.com/varshar16/ceph.git
git fetch vr
git checkout -b vr/rook-testing
git rebase origin/master
./install-deps.sh
./do_cmake.sh
cd build
make -j$(nproc)
