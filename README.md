# Harbor BOSH release

Project Harbor is an enterprise-class registry server that stores and distributes Docker images. Harbor extends the open source Docker Distribution by adding the functionalities usually required by an enterprise, such as security, identity and management. As an enterprise private registry, Harbor offers better performance and security. Having a registry closer to the build and run environment improves the image transfer efficiency. Harbor supports the setup of multiple registries and has images replicated between them. In addition, Harbor offers advanced security features, such as user management, access control and activity auditing.

This repository uses the [Harbor](https://github.com/vmware/harbor) offline installation package to create the [BOSH](https://bosh.io) release which can be used to quickly deploy a standalone Harbor. The main idea of this Harbor BOSH release is running the Harbor components as containers on top of Docker and docker-compose. Please be noted here that **it's not a HA architecture of the Harbor deployed with this Harbor BOSH release.**

## Repository Contents

This repository is structured for use with BOSH; an open source tool for release engineering, deployment and lifecycle management of large scale distributed services. 

### packages
Packaging instructions used by BOSH to build each of the dependencies. The following 4 packages are contained in this repository:
* common: provide some utility scripts like pid operations
* docker: provide installation for Docker
* docker-compose: provide docker-compose tool
* harbor-app: harbor application packages including templates and all the docker images of harbor components

### jobs
Start and stop commands for each of the jobs (processes) running on Harbor nodes. Currently, only 1 job named **harbor** in this repository because we start harbor via docker-compose.
The job 'harbor' is composed by the following things:
* **templates/config/harbor.cfg:** The base configuration file template of harbor. The real content will come from the properties user provided when deploying.
* **templates/tls/server.*:** The server certificate and key file template. The real content of the cert and key will also provided by user in the deployment manifest.
* **templates/bin/pre-start.erb:** The script is executed in the pre-start stage of the job lifecycle and used to prepare the running environment:
  * Set cgroup mount point
  * Start docker daemon process
  * Load docker images of harbor components into docker
  * Execute harbor prepare scripts
* **templates/bin/ctl.erb:** Provide start/stop harbor process commands. 'start' command is based on docker-compose. 'stop' is directly kill the process keep in the pid file.
* **templates/bin/status_check.erb:** Check if the harbor is working well. Besides checking the container status, it will also issue http request to call the harbor api.
* **spec:** Define the package dependencies and properties.
* **monit:** Provide monit way for BOSH to check the status of harbor process.

### config
URLs and access credentials to the bosh blobstore for storing final releases. Currently, only contain configuration for local blob.

### src
Provide the utility script source code for the **common** package.

### templates
Provide deployment manifest templates and related manifest generation scripts. Currently, only manifest file for vCenter/vSphere.
* **deployment_vsphere.yml:** Deploy harbor with BOSH to vCenter/vSphere.

### .final_builds
References into the public blobstore for final jobs & packages (each referenced by one or more **releases**)

### releases
yml files containing the references to blobs for each package in a given release; these are solved within **.final_builds**.

## Deploy Harbor with BOSH

### Install BOSH CLI V2
[Download](https://bosh.io/docs/cli-v2.html#install) the binary for your platform and place it on your **PATH**.

### Create BOSH env
Here we just provide the command for vCenter/vSphere, for other IaaS platform, please refer to [BOSH doc](https://bosh.io/docs/init.html).
```
# Create directory to keep state
$ mkdir bosh-1 && cd bosh-1

# Clone Director templates
$ git clone https://github.com/cloudfoundry/bosh-deployment

# Fill below variables (replace example values) and deploy the Director
$ bosh create-env bosh-deployment/bosh.yml \
    --state=state.json \
    --vars-store=creds.yml \
    -o bosh-deployment/vsphere/cpi.yml \
    -o bosh-deployment/uaa.yml \
    -o bosh-deployment/misc/config-server.yml \
    -v director_name=bosh-1 \
    -v internal_cidr=10.0.0.0/24 \
    -v internal_gw=10.0.0.1 \
    -v internal_ip=10.0.0.6 \
    -v network_name="VM Network" \
    -v vcenter_dc=my-dc \
    -v vcenter_ds=datastore0 \
    -v vcenter_ip=192.168.0.10 \
    -v vcenter_user=root \
    -v vcenter_password=vmware \
    -v vcenter_templates=bosh-1-templates \
    -v vcenter_vms=bosh-1-vms \
    -v vcenter_disks=bosh-1-disks \
    -v vcenter_cluster=cluster1
    -o bosh-deployment/vsphere/resource-pool.yml \
    -v vcenter_rp=bosh-rp1

# Create alias for the created env
bosh alias-env <alias name> -e <director IP> --ca-cert <(bosh int ./creds.yml --path /director_ssl/ca)

# Set env
$ export BOSH_CLIENT=admin
$ export BOSH_CLIENT_SECRET=`bosh int ./creds.yml --path /admin_password`

bosh -e <alias name> env

```

### Create the release
Before deploy, we need to create and upload the bosh release. You need to git clone this repository before going on.
```
#Clone repostiry
git clone https://gitlab.eng.vmware.com/harbor/habo.git

#Download blobs
cd harbor-bosh-release/scripts
bash download_blobs.sh

#Create a dev release
bosh create-release --force

#Or create a final release
#bosh -e <env> create-release --name <release name> --version <version> --final

#Upload your release
#Current workdir is the release dir
bosh -e <env> upload-release

#Additionally you can specify the release name and version
#bosh -e <env> upload-release --name <name> --version <version> <PATH>

```

### Make a deployment
Before triggering deployment, confirm the release is there.
```
bosh -e <env> releases

```
Now, make the deployment.
**NOTES: deployment_vsphere.yml is not a manifest file template yet, you need to change some of the contents such as network, director uuid, release and certifications etc. according to your environment.**

```
#Make sure current workdir is the harbor bosh release dir
bosh -n update-cloud-config templates/cloud_config.yml
bosh -e <env> -d harbor-deployment deploy templates/deployment_vsphere.yml --vars-store /path/to/creds.yml -v hostname=<harbor_vm_fqdn_or_ip>

```
After the deployment is completed, you can check the status of the deployment:

```
#See current deployments
bosh -e <env> deployments

#Check the status of vms
bosh -e <env> vms

#Check the status of instances
bosh -e <env> instances

```

### Delete deployment
If you want to delete the specified deployment, execute

```
## --force ignore the errors when deleting
bosh -e <env> -d <deployment name> delete-deployment --force

```

## Next work
* **Verify version upgrade process via BOSH [P0]**
* **Keep on refactoring the whole process [P0]**
* Add smoke tests job [P1]
* Make deployment on aws and gcp (Create cloud_config file for aws and gcp)[P1]
* Extract manifest to templates and cloud_config files and provide manifest file generating script tool [P2]
* Create Pivotal tile based on this BOSH release [P3]

The job is tracked by issue [#3184: BOSH release for Harbor](https://github.com/vmware/harbor/issues/3184).
