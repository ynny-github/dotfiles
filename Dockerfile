FROM ubuntu:latest

RUN apt update -y  && \
    apt install -y git micro

ENTRYPOINT /bin/sh -c "while sleep 1000; do :; done"
