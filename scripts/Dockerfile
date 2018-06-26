ARG TAG=latest
ARG PLUGINS=./code/
ARG PORTS

FROM ramrodpcp/interpreter-plugin:${TAG}

COPY ${PLUGINS} /opt/app-root/src/plugins

EXPOSE ${PORTS}