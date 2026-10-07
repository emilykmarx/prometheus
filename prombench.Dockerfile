ARG BUILDER=prometheus-builder:conftamer
ARG VERSION=v3.2.1

FROM ${BUILDER} AS build
ARG VERSION=v3.2.1
# Copy in local modules
COPY prom-common/ /prom-common/
COPY prom-exporter-toolkit/ /prom-exporter-toolkit/
# Copy in local Prom source
COPY prometheus/ /src/
RUN cd /src && make build PROMU_BINARIES=prometheus

FROM quay.io/prometheus/prometheus:${VERSION}
COPY --from=build /src/prometheus /bin/prometheus
