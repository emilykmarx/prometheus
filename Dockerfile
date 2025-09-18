ARG ARCH="amd64"
ARG OS="linux"
FROM ubuntu:latest
# Expects prometheus to have already been built
# (with `go build -gcflags="all=-N -l" ./cmd/prometheus/`)
# may also need `make assets` for web UI
LABEL maintainer="The Prometheus Authors <prometheus-developers@googlegroups.com>"
LABEL org.opencontainers.image.source="https://github.com/prometheus/prometheus"

RUN apt-get update && apt-get install -y build-essential git wget vim

# Install go
ENV GO_VERSION=1.22.7
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
   rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Install dlv as non-root so it doesn't end up in root dir
USER ubuntu
WORKDIR /home/ubuntu

# Install dlv
RUN git clone https://github.com/emilykmarx/go-set.git && \
  git clone https://github.com/emilykmarx/graph.git && \
  git clone https://github.com/emilykmarx/delve.git && \
  cd delve;  go install github.com/go-delve/delve/cmd/dlv

# dlv is installed here
ENV PATH=$PATH:/home/ubuntu/go/bin

# This directory ends up with rwx perms for ubuntu user even after the operator's shenanigans
# Notes that may matter later: `kubectl exec` works but gives `groups: cannot find name for group ID 2000`
# dlv cannot create /home/ubuntu/.config due to `read-only file system` - neither can ubuntu, despite stat saying ubuntu has rwx
WORKDIR /home/ubuntu/prometheus

# Copy whole Prometheus source, so dlv can do things like list
# (Will also copy the executable, and stuff in web/ui/static)
COPY . .

# Copy the config file created by operator (for use in `docker run`)
COPY kube-prometheus-stack/kps_prom_config.yaml /etc/prometheus/prometheus.yml

COPY LICENSE                                /LICENSE
COPY NOTICE                                 /NOTICE
COPY npm_licenses.tar.bz2                   /npm_licenses.tar.bz2

# Back to root so can create data dir when run with `docker run` (doesn't matter when run with operator I think)
USER root
EXPOSE     9090
VOLUME     [ "/prometheus" ]
ENTRYPOINT ["/bin/sh", "-c" , "sleep infinity"]
# dlv exec ./prometheus -- --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus
