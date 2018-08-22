#!/bin/bash

set -e

files_dir=/tmp/harbor_files
mkdir -p $files_dir
cd $files_dir
if [ "$1" != "--skip-download" ]; then
  wget https://download.docker.com/linux/static/stable/x86_64/docker-18.06.0-ce.tgz
  wget -O docker-compose-Linux-x86_64-1.16.1 https://github.com/docker/compose/releases/download/1.16.1/docker-compose-Linux-x86_64
  #wget -O harbor-offline-installer-latest.tgz https://storage.googleapis.com/harbor-builds/harbor-offline-installer-latest.tgz
  wget -O harbor-offline-installer-latest.tgz https://storage.googleapis.com/harbor-builds/harbor-offline-installer-v1.6.0-build.204.tgz
  wget https://dl.google.com/go/go1.9.2.linux-amd64.tar.gz
fi
cd -
cd ..
bosh add-blob $files_dir/docker-18.06.0-ce.tgz docker/docker-18.06.0-ce.tgz
bosh add-blob $files_dir/docker-compose-Linux-x86_64-1.16.1 docker/docker-compose-Linux-x86_64-1.16.1
bosh add-blob $files_dir/harbor-offline-installer-latest.tgz harbor/harbor-offline-installer-latest.tgz
bosh add-blob $files_dir/go1.9.2.linux-amd64.tar.gz go/go1.9.2.linux-amd64.tar.gz

