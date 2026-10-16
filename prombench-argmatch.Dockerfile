# prombench.Dockerfile, with Prometheus built under argmatch
# (../dump_ancestors/argmatch). Build from the parent directory:
#   docker build -f prometheus/prombench-argmatch.Dockerfile --build-arg VERSION=v3.2.1 -t prometheus-argmatch:v3.2.1 .
ARG BUILDER=prometheus-builder:conftamer
ARG VERSION=v3.2.1

FROM ${BUILDER} AS build
ARG VERSION=v3.2.1
ARG ARGMATCH_FUNC=main.reloadConfig
ARG ARGMATCH_MATCH=/etc/prometheus/prometheus.yml
ARG ARGMATCH_DEPTH=5
# File (inside the container) that Prometheus appends matches to; empty means stderr
ARG ARGMATCH_OUT=
# Copy in local modules
COPY prom-common/ /prom-common/
COPY prom-exporter-toolkit/ /prom-exporter-toolkit/
# Build argmatch
COPY dump_ancestors/argmatch/ /argmatch/
RUN cd /argmatch && go build -o argmatch .
# Copy in local Prom source
COPY prometheus/ /src/
RUN cd /src && \
    ARGMATCH_FUNC="${ARGMATCH_FUNC}" ARGMATCH_MATCH="${ARGMATCH_MATCH}" ARGMATCH_DEPTH="${ARGMATCH_DEPTH}" ARGMATCH_OUT="${ARGMATCH_OUT}" \
    GOFLAGS=-toolexec=/argmatch/argmatch \
    make build PROMU_BINARIES=prometheus

FROM quay.io/prometheus/prometheus:${VERSION}
COPY --from=build /src/prometheus /bin/prometheus
