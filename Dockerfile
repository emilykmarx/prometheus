ARG ARCH="amd64"
ARG OS="linux"
FROM ubuntu:latest
# Expects prometheus to have already been built
# (with `go build -gcflags="all=-N -l" ./cmd/prometheus/`)
# may also need `make assets` for web UI
LABEL maintainer="The Prometheus Authors <prometheus-developers@googlegroups.com>"
LABEL org.opencontainers.image.source="https://github.com/prometheus/prometheus"

ARG ARCH="amd64"
ARG OS="linux"
# Copy source code for web UI
COPY . /home/ubuntu/prometheus/
COPY documentation/examples/prometheus.yml  /etc/prometheus/prometheus.yml
COPY LICENSE                                /LICENSE
COPY NOTICE                                 /NOTICE
COPY npm_licenses.tar.bz2                   /npm_licenses.tar.bz2

WORKDIR /home/ubuntu/prometheus

EXPOSE     9090
VOLUME     [ "/prometheus" ]
ENTRYPOINT [ "/home/ubuntu/prometheus/prometheus" ]
CMD        [ "--config.file=/etc/prometheus/prometheus.yml", \
             "--storage.tsdb.path=/prometheus" ]
