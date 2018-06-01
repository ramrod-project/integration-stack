[![Build Status](https://travis-ci.org/ramrod-project/integration-stack.svg?branch=dev)](https://travis-ci.org/ramrod-project/integration-stack)


# PCP stack deployment guide

## Docker installation from package

**_Ubuntu 16.04_**

Install on Ubuntu via deb package.

1. Download latest stable release from https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/

Replace \<version\> with the version you find in the link above.

```
curl https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_<version>~ce-0~ubuntu_amd64.deb -o docker-ce_<version>-0~ubuntu_amd64.deb
```

2. Install using dpkg.

```
sudo dpkg -i docker-ce_<version>-0~ubuntu_amd64.deb
```

3. Verify installation

```
sudo docker run hello-world
```

4. (Optional but helpful) Add user to docker group.

```
usermod -aG docker <user>
```

So you don't have to `sudo` every docker command. Replace \<user\> with your username.

**_CentOS 7_**

Install on Centos7 via rpm package.

1. Download latest stable relase from https://download.docker.com/linux/centos/7/x86_64/stable/Packages/.

Replace \<version\> with the version you find in the link above.

```
curl https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-<version>.ce-1.el7.centos.x86_64.rpm -o docker-ce-<version>.ce-1.el7.centos.x86_64.rpm
```

2. Install via yum package manager.

```
sudo yum install -y docker-ce-<version>.ce-1.el7.centos.x86_64.rpm
```

3. Start docker and test.

```
sudo systemctl start docker
sudo systemctl enable docker

sudo docker run hello-world
```

4. (Optional but helpful) Add user to docker group.

```
usermod -aG docker <user>
```

So you don't have to `sudo` every docker command. Replace \<user\> with your username.

## Exporting images/repos for offline use

1. Run the export script and select the appropriate tag from the prompt

```
$ ./pull-export.sh
1) dev
2) qa
3) latest
4) exit
```

2. Latest images are pulled based on provided tag and repos are cloned similarly. 

These are all compressed and stored in an export archive: ramrodpcp-exports.tar.gz.

```
$ tar -t -f ramrodpcp-exports.tar.gz
./exports/
./exports/image-database-brain-124531-05-23-18-CDT.tar.gz
./exports/repo-clone-database-brain-124659-05-23-18-CDT.tar.gz
./exports/image-interpreter-plugin-124612-05-23-18-CDT.tar.gz
./exports/image-backend-interpreter-124526-05-23-18-CDT.tar.gz
./exports/repo-clone-integration-stack-124702-05-23-18-CDT.tar.gz
./exports/repo-clone-frontend-ui-124648-05-23-18-CDT.tar.gz
./exports/repo-clone-backend-interpreter-124657-05-23-18-CDT.tar.gz
./exports/image-frontend-ui-124600-05-23-18-CDT.tar.gz
```

## Load images from files for offline use

1. Load images from .tar.gz

Run the 'setup.sh script, passing the directory to the export archive.'

```
$ ./setup.sh <export_directory>
```

This finds and loads the images 

```
Loading ./exports/image-database-brain-124531-05-23-18-CDT.tar.gz...
Loaded image: ramrodpcp/database-brain:dev
Loading ./exports/image-interpreter-plugin-124612-05-23-18-CDT.tar.gz...
Loaded image: ramrodpcp/interpreter-plugin:dev
Loading ./exports/image-backend-interpreter-124526-05-23-18-CDT.tar.gz...
Loaded image: ramrodpcp/backend-interpreter:dev
Loading ./exports/image-frontend-ui-124600-05-23-18-CDT.tar.gz...
Loaded image: ramrodpcp/frontend-ui:dev
```

## Stack deployment (Automated)

1. Run the deployment script

```
$ sudo ./deploy.sh --tag <dev|qa|latest> --loglevel <DEBUG|INFO|WARN|ERROR|CRITICAL>
```

2. Press `<CTRL-C>` to tear down the stack.

```
You can reach the frontend at 'http://frontend:8080'.
If you need to access from another machine or VM host, be sure to add this machine's IP to the hostfile as 'frontend'
Running stack, press <CRTL-C> to stop...
ID                  NAME                  IMAGE                               NODE
   DESIRED STATE       CURRENT STATE           ERROR               PORTS
qku16axjcq4d        pcp-test_database.1   ramrodpcp/database-brain:dev        blackarch
   Running             Running 5 seconds ago
0jx6wp2kwtxe        pcp-test_frontend.1   ramrodpcp/frontend-ui:dev           blackarch
   Running             Running 7 seconds ago
mjhhmkx3gt0i        pcp-test_backend.1    ramrodpcp/backend-interpreter:dev   blackarch
   Running             Running 9 seconds ago
Tearing down stack...
Removing leftover containers...
Pruning networks...
Restoring hosts file...
```

## Stack deployment (Manual)

1. Prepare system:

Open up any ports or disable firewall if necessary. Manually stop and remove any leftover docker containers before deploying.

```
docker ps | grep -v CONTAINER | awk '{print $1}' | xargs -I {} bash -c 'if [[ {} ]]; then docker stop {} 2>&1; fi >>/dev/null'
docker ps -a | grep -v CONTAINER | awk '{print $1}' | xargs -I {} bash -c 'if [[ {} ]]; then docker rm {} 2>&1; fi >>/dev/null'
```

2. Initialize swarm:

Since we are deploying this application as a docker stack, we must initialize the host as a docker swarm node. An attachable network must also be created for the stack, so that containers can be dynamically added to it.

```
docker swarm init

docker network create --driver=overlay --attachable pcp
```

3. Deploy:

Deploying the application is a simple `docker stack` command using the provided docker-compose.yml configuration file. This file requires the `TAG` and `LOGLEVEL` environment variables to be set. 

```
TAG=<dev|qa|latest> LOGLEVEL=<DEBUG|INFO|WARN|ERROR|CRITICAL> docker stack deploy -c docker/docker-compose.yml <stack_name>
```

4. Tear down stack:

Tear down docker stack.

```
docker stack rm <stack_name>
```

5. Remove leftover containers:

Execute commands from step 1 again to stop and remove dangling containers.