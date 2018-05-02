***How to deploy docker stack***

Initialize swarm:
```
docker swarm init

docker network create --driver=overlay --attachable pcp
```

Select log level:
```
export LOGLEVEL=<DEBUG,INFO,WARN,ERROR,CRITICAL>
```

Dev:
```
export STAGE=DEV
docker stack deploy -c docker/docker-compose.yml <stack_name>
```

Prod:
```
export STAGE=PROD
docker stack deploy -c docker/docker-compose.yml <stack_name>
```