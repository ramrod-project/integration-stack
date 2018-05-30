# Dockerfile for the robot framework test container image

FROM ramrodpcp/robot-framework-xvfb:latest

COPY ./Robot/* /opt/robotframework/tests/

ENTRYPOINT robot -d /opt/robotframework/reports/ /opt/robotframework/tests/