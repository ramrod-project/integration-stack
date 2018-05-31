FROM alpine:3.7

RUN apk add --no-cache bash curl dbus firefox-esr fontconfig python ttf-freefont xvfb py-pip

# Prevent time drift RUN ntpd -dqnp pool.ntp.org

# Add gecko driver

ARG GECKODRIVER_VERSION=0.15.0 
ARG GECKODRIVER_FILE=v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz 

RUN curl -s -o /tmp/geckodriver.tar.gz -L \
    https://github.com/mozilla/geckodriver/releases/download/$GECKODRIVER_FILE \
    && rm -rf /usr/bin/geckodriver \
    && tar -C /usr/bin -zxf /tmp/geckodriver.tar.gz \
    && rm /tmp/geckodriver.tar.gz \
    && mv /usr/bin/geckodriver /usr/bin/geckodriver-$GECKODRIVER_VERSION \
    && chmod 755 /usr/bin/geckodriver-$GECKODRIVER_VERSION \
    && ln -fs /usr/bin/geckodriver-$GECKODRIVER_VERSION /usr/bin/geckodriver

RUN pip install -U \
    pip \
    robotframework \
    robotframework-selenium2library==3.0.0 \
    robotframework-xvfb==1.2.2

ENTRYPOINT robot -d /opt/robotframework/reports/ /opt/robotframework/tests/