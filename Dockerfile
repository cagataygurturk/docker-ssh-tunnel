FROM alpine:3.2
MAINTAINER Cagatay Gurturk <cguertuerk@ebay.de>

RUN apk add --update openssh-client && rm -rf /var/cache/apk/*

CMD rm -rf /root/.ssh && mkdir /root/.ssh && cp -R /root/ssh/* /root/.ssh/ && chmod -R 600 /root/.ssh/* && \
ssh \
-vv \
-o StrictHostKeyChecking=no \
-N $TUNNEL_HOST \
-L *:$LOCAL_PORT:$REMOTE_HOST:$REMOTE_PORT \
&& while true; do sleep 30; done;
EXPOSE 1-65535