FROM ubuntu:20.04
MAINTAINER Tyler

EXPOSE 6379

RUN apt-get update && apt-get install -y stunnel4

VOLUME /stunnel
ADD ./stunnel.conf /stunnel/
ADD ./start.sh /

CMD [ "/start.sh" ]
