#!/bin/bash

set -e

files_dir=/tmp/harbor_files
mkdir -p $files_dir
cd $files_dir
if [ "$1" != "--skip-download" ]; then
  wget https://download.docker.com/linux/static/stable/x86_64/docker-18.06.0-ce.tgz
  wget -O docker-compose-Linux-x86_64 https://github.com/docker/compose/releases/download/1.22.0/docker-compose-Linux-x86_64
  #wget -O harbor-offline-installer-latest.tgz https://storage.googleapis.com/harbor-builds/harbor-offline-installer-latest.tgz
  wget -O harbor-offline-installer-latest.tgz https://storage.googleapis.com/harbor-releases/release-1.6.0/harbor-offline-installer-v1.6.0-build.340.tgz
  wget https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tgz
  wget http://mirrors.kernel.org/ubuntu/pool/main/n/nfs-utils/nfs-common_1.2.8-9ubuntu12_amd64.deb
  wget http://security.ubuntu.com/ubuntu/pool/main/libe/libevent/libevent-2.0-5_2.0.21-stable-2ubuntu0.16.04.1_amd64.deb
  wget http://mirrors.kernel.org/ubuntu/pool/main/libn/libnfsidmap/libnfsidmap2_0.25-5_amd64.deb
  wget http://mirrors.kernel.org/ubuntu/pool/main/r/rpcbind/rpcbind_0.2.3-0.2_amd64.deb
  wget http://mirrors.kernel.org/ubuntu/pool/main/k/keyutils/keyutils_1.5.9-8ubuntu1_amd64.deb

fi
cd -
cd ..
bosh add-blob $files_dir/smoke-test  smoke-test/smoke-test
bosh add-blob $files_dir/docker-18.06.0-ce.tgz docker/docker-18.06.0-ce.tgz
bosh add-blob $files_dir/docker-compose-Linux-x86_64 docker/docker-compose-Linux-x86_64
bosh add-blob $files_dir/harbor-offline-installer-latest.tgz harbor/harbor-offline-installer-latest.tgz
bosh add-blob $files_dir/Python-2.7.15.tgz python/Python-2.7.15.tgz
bosh add-blob $files_dir/nfs-common_1.2.8-9ubuntu12_amd64.deb nfs-common/nfs-common_1.2.8-9ubuntu12_amd64.deb
bosh add-blob $files_dir/libevent-2.0-5_2.0.21-stable-2ubuntu0.16.04.1_amd64.deb nfs-common/libevent-2.0-5_2.0.21-stable-2ubuntu0.16.04.1_amd64.deb
bosh add-blob $files_dir/rpcbind_0.2.3-0.2_amd64.deb nfs-common/rpcbind_0.2.3-0.2_amd64.deb
bosh add-blob $files_dir/keyutils_1.5.9-8ubuntu1_amd64.deb nfs-common/keyutils_1.5.9-8ubuntu1_amd64.deb
bosh add-blob $files_dir/libnfsidmap2_0.25-5_amd64.deb nfs-common/libnfsidmap2_0.25-5_amd64.deb



