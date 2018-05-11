# PCP stack deployment guide

## Docker installation from package

**_Ubuntu_**



**_CentOS 7_**

1. Install dependency packages

```
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```

2. Configure docker-ce repo

## Stack deployment

Initialize swarm:
```
docker swarm init

docker network create --driver=overlay --attachable pcp
```

Deploy:
```
TAG=<dev|qa|latest> LOGLEVEL=<DEBUG|INFO|WARN|ERROR|CRITICAL> docker stack deploy -c docker/docker-compose.yml <stack_name>
```