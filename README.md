***How to deploy docker stack***

Initialize swarm:
```
docker swarm init

docker network create --driver=overlay --attachable pcp
```

Deploy:
```
LOGLEVEL=<DEBUG,INFO,WARN,ERROR,CRITICAL> docker stack deploy -c docker/docker-compose.yml <stack_name>
```