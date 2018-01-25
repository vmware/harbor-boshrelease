#!/bin/bash

set -e

files_dir=/tmp/harbor_files
mkdir -p $files_dir
cd $files_dir
if [ "$1" != "--skip-download" ]; then
  wget https://download.docker.com/linux/static/stable/x86_64/docker-17.06.2-ce.tgz
  wget -O docker-compose-Linux-x86_64-1.16.1 https://github.com/docker/compose/releases/download/1.16.1/docker-compose-Linux-x86_64
  wget https://www.openssl.org/source/openssl-1.0.2l.tar.gz
  wget -O harbor-offline-installer-latest.tgz https://storage.googleapis.com/harbor-builds/harbor-offline-installer-v1.3.0-rc1-267-gdb8511b.tgz
  wget https://dl.google.com/go/go1.9.2.linux-amd64.tar.gz
fi
cd -
cd ..
bosh add-blob $files_dir/docker-17.06.2-ce.tgz docker/docker-17.06.2-ce.tgz
bosh add-blob $files_dir/docker-compose-Linux-x86_64-1.16.1 docker/docker-compose-Linux-x86_64-1.16.1
bosh add-blob $files_dir/openssl-1.0.2l.tar.gz library/openssl-1.0.2l.tar.gz
bosh add-blob $files_dir/harbor-offline-installer-latest.tgz harbor/harbor-offline-installer-latest.tgz
bosh add-blob $files_dir/go1.9.2.linux-amd64.tar.gz go/go1.9.2.linux-amd64.tar.gz

