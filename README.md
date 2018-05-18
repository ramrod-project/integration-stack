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

## Stack deployment

1. Initialize swarm:

Since we are deploying this application as a docker stack, we must initialize the host as a docker swarm node. An attachable network must also be created for the stack, so that containers can be dynamically added to it.

```
docker swarm init

docker network create --driver=overlay --attachable pcp
```

2. Deploy:

Deploying the application is a simple `docker stack` command using the provided docker-compose.yml configuration file. This file requires the `TAG` and `LOGLEVEL` environment variables to be set.

```
TAG=<dev|qa|latest> LOGLEVEL=<DEBUG|INFO|WARN|ERROR|CRITICAL> docker stack deploy -c docker/docker-compose.yml <stack_name>
```