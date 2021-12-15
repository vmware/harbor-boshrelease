#!/bin/bash

set -e

files_dir=/tmp/harbor_files
mkdir -p $files_dir
cd $files_dir
if [ "$1" != "--skip-download" ]; then
  wget https://download.docker.com/linux/static/stable/x86_64/docker-19.03.12.tgz
  wget -O docker-compose-Linux-x86_64 https://github.com/docker/compose/releases/download/1.27.0/docker-compose-Linux-x86_64
  wget -O harbor-offline-installer-latest.tgz https://github.com/goharbor/harbor/releases/download/v2.1.0-rc3/harbor-offline-installer-v2.1.0-rc3.tgz
  wget https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tgz
  wget http://mirrors.kernel.org/ubuntu/pool/main/n/nfs-utils/nfs-common_1.2.8-9ubuntu12_amd64.deb
  wget http://security.ubuntu.com/ubuntu/pool/main/libe/libevent/libevent-2.0-5_2.0.21-stable-2ubuntu0.16.04.1_amd64.deb
  wget http://mirrors.kernel.org/ubuntu/pool/main/libn/libnfsidmap/libnfsidmap2_0.25-5_amd64.deb
  wget http://mirrors.kernel.org/ubuntu/pool/main/r/rpcbind/rpcbind_0.2.3-0.2_amd64.deb
  wget http://mirrors.kernel.org/ubuntu/pool/main/k/keyutils/keyutils_1.5.9-8ubuntu1_amd64.deb
  wget https://storage.googleapis.com/harbor-ci-pipeline-store/build-artifacts/harbor-wavefront-bundle-2.0.2.tgz
fi
cd -
cd ..
bosh add-blob $files_dir/smoke-test  smoke-test/smoke-test
bosh add-blob $files_dir/docker-19.03.12.tgz docker/docker.tgz
bosh add-blob $files_dir/docker-compose-Linux-x86_64 docker/docker-compose-Linux-x86_64
bosh add-blob $files_dir/harbor-offline-installer-latest.tgz harbor/harbor-offline-installer-latest.tgz
bosh add-blob $files_dir/Python-2.7.15.tgz python/Python-2.7.15.tgz
bosh add-blob $files_dir/nfs-common_1.2.8-9ubuntu12_amd64.deb nfs-common/nfs-common_1.2.8-9ubuntu12_amd64.deb
bosh add-blob $files_dir/libevent-2.0-5_2.0.21-stable-2ubuntu0.16.04.1_amd64.deb nfs-common/libevent-2.0-5_2.0.21-stable-2ubuntu0.16.04.1_amd64.deb
bosh add-blob $files_dir/rpcbind_0.2.3-0.2_amd64.deb nfs-common/rpcbind_0.2.3-0.2_amd64.deb
bosh add-blob $files_dir/keyutils_1.5.9-8ubuntu1_amd64.deb nfs-common/keyutils_1.5.9-8ubuntu1_amd64.deb
bosh add-blob $files_dir/libnfsidmap2_0.25-5_amd64.deb nfs-common/libnfsidmap2_0.25-5_amd64.deb
bosh add-blob $files_dir/harbor-wavefront-bundle-2.0.1.tgz wavefront/harbor-wavefront-bundle-2.0.1.tgz
