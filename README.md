# Harbor BOSH Release

Project Harbor is an enterprise-class registry server that stores and distributes Docker images. Harbor extends the open source Docker Distribution by adding the functionalities usually required by an enterprise, such as security, identity and management. As an enterprise private registry, Harbor offers better performance and security. Having a registry closer to the build and run environment improves the image transfer efficiency. Harbor supports the setup of multiple registries and has images replicated between them. In addition, Harbor offers advanced security features, such as user management, access control and activity auditing.

This repository uses the [Harbor](https://github.com/vmware/harbor) offline installation package to create the [BOSH](https://bosh.io) release for Harbor, which can be used to quickly deploy a standalone Harbor. The main idea of this Harbor BOSH release is running the Harbor components as containers on top of Docker and docker-compose. Please be noted here that **it's not a HA architecture deployed with this Harbor BOSH release.**

This BOSH release for Harbor is open sourced under Apache License Version 2.0.

## Repository Contents

This repository consists of the following file directories.

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

### manifests
Provide deployment manifest templates and related manifest generation scripts. Currently, only provides manifest file for vSphere vCenter.
* **deployment-vsphere.yml:** Deploy Harbor to vSphere vCenter.

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
mkdir bosh-1 && cd bosh-1

# Clone Director templates
git clone https://github.com/cloudfoundry/bosh-deployment

# Fill below variables (replace example values) and deploy the Director
bosh create-env bosh-deployment/bosh.yml \
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
bosh int ./creds.yml --path /director_ssl/ca > root_ca_certificate
export BOSH_CA_CERT=root_ca_certificate
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int ./creds.yml --path /admin_password`
export BOSH_ENVIRONMENT=<director IP>
```

### Create the BOSH release
Before deploy, we need to create the harbor bosh release. You need to git clone this repository before going on.
```
#Clone repostiry
git clone git@github.com:vmware/harbor-boshrelease.git

#Download blobs
cd harbor-boshrelease/scripts
bash add_blobs.sh

#Create a dev release
bosh create-release --force

#Or create a final release
bosh create-release --final [--version <version>]
```

### Make a deployment

#### Deploy pre-build final release

You can deploy the published pre-build final release without creating a local dev release:
```
bosh -n -d harbor-deployment deploy manifests/harbor.yml -v hostname=harbor.local
```

#### Deploy dev release

Upload the created dev release:
```
bosh upload-release
```

Confirm the release is uploaded.
```
bosh releases
```

You can find the bosh cloud config file, bosh runtime config file and deployment manifest samples in directory manifests.
**NOTES:**
* Change cloud-config-vsphere.yml per your environment.
* Change configuration in the deployment manifest sample file deployment-vsphere.yml (e.g. azs name, networks name) per your environment.
* Change the version of harbor-container-registry release in runtime-config-harbor.yml.

Upload cloud-config and runtime-config, then kick off the deployment:
```
bosh -n update-cloud-config   manifests/cloud-config-vsphere.yml
bosh -n update-runtime-config manifests/runtime-config-bosh-dns.yml --name bosh-dns
bosh -n update-runtime-config manifests/runtime-config-harbor.yml   --name harbor
bosh -n -d harbor-deployment deploy templates/deployment-vsphere.yml -v hostname=harbor.local [--vars-store /path/to/creds.yml]
bosh run-errand smoke-test -d harbor-deployment
```
After the deployment is completed, you can check the status of the deployment:
```
#See current deployments
bosh deployments

#Check the status of vms
bosh vms

#Check the status of instances
bosh instances
```

### Delete deployment
If you want to delete the specified deployment, execute:
```
## --force ignore the errors when deleting
bosh -d harbor-deployment delete-deployment --force
```

## Maintainers

- Jesse Hu [huh at vmware.com]
- Steven Zou [szou at vmware.com]
- Daniel Jiang [jiangd at vmware.com]

## Contributing

The harbor-boshrelease project team welcomes contributions from the community. If you wish to contribute code and you have not
signed our contributor license agreement (CLA), our bot will update the issue when you open a Pull Request. For any
questions about the CLA process, please refer to our [FAQ](https://cla.vmware.com/faq). For more detailed information,
refer to [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Refer to [LICENSE](LICENSE).
