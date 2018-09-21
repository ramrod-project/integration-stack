# PCP stack deployment guide

[![Build Status](https://travis-ci.org/ramrod-project/integration-stack.svg?branch=dev)](https://travis-ci.org/ramrod-project/integration-stack)

## Table of Contents

[Export files (QA)](#exportqa)  
[Export files with plugins (production)](#exportprod)  
[Load images](#load)  
[Deploy stack (auto)](#stackauto)  
[Deploy stack (manual)](#stackmanual)  

### Exporting images/repos (for QA)<a name="exportqa"></a>

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
$ tar -t -f ramrodpcp-exports-***_***.tar.gz
./exports/
./exports/image-database-brain-124531-05-23-18-CDT.tar.gz
./exports/repo-clone-database-brain-124659-05-23-18-CDT.tar.gz
./exports/image-interpreter-plugin-124612-05-23-18-CDT.tar.gz
./exports/image-backend-interpreter-124526-05-23-18-CDT.tar.gz
./exports/repo-clone-integration-stack-124702-05-23-18-CDT.tar.gz
...
```

### Exporting images/repos from dev to production<a name="exportprod"></a>

1. After plugin development is complete, place all plugin `.py` files into a folder located in the `./.scripts/` folder (Assuming you've already un-tarred the main exports tarfile to your working directory - see [Load images](#load)).

```
$ mkdir ./.scripts/plugins
$ cp ../backend-interpreter/plugins/* ./.scripts/plugins (optional, if you want to deploy Harness)
$ cp <plugin1>.py ./.scripts/plugins
$ cp <__plugin1_extras_dir/*> ./.scripts/plugins/__plugin1_extras_dir (if extra files are needed)
```

2. Run the dev-export.sh script to save production files to a .tar.gz file.

```
$ ./.scripts/dev-export.sh ./exports/ ./.scripts/plugins
1) dev
2) qa
3) latest
4) exit
...
```

This will generate a ramrod-deployment-package-*.tar.gz file with the container images and scripts needed to run the stack. 

### Load images from files<a name="load"></a>

1. Extract the main archive

```
$ tar -xzvf ramrodpcp-exports-***_***.tar.gz
```

2. Load images from .tar.gz

Run the 'setup.sh script, passing the directory to the export archive.'

```
$ ./.scripts/setup.sh ./exports/
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

### Stack deployment (Automated)<a name="stackauto"></a>

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

### Stack deployment (Manual)<a name="stackmanual"></a>

1. Prepare system:

Open up any ports or disable firewall if necessary. Manually stop and remove any leftover docker containers before deploying.

```
docker ps | grep -v CONTAINER | awk '{print $1}' | xargs -I {} bash -c 'if [[ {} ]]; then docker stop {} 2>&1; fi >>/dev/null'
docker ps -a | grep -v CONTAINER | awk '{print $1}' | xargs -I {} bash -c 'if [[ {} ]]; then docker rm {} 2>&1; fi >>/dev/null'
```

2. Initialize swarm:

Since we are deploying this application as a docker stack, we must initialize the host as a docker swarm node. An attachable network must also be created for the stack, so that containers can be dynamically added to it.

```
docker swarm init --listen-addr <host_ip>:2377 --advertise-addr <host_ip>

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