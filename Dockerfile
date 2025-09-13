FROM ubuntu:latest
# Expects prometheus to have already been built (with `go build -gcflags="all=-N -l" ./cmd/prometheus/`)

# Copy executables and whatnot (may eventually want promtool)
COPY prometheus        /bin/prometheus
COPY documentation/examples/prometheus.yml  /etc/prometheus/prometheus.yml
COPY LICENSE                                /LICENSE
COPY NOTICE                                 /NOTICE
COPY npm_licenses.tar.bz2                   /npm_licenses.tar.bz2

WORKDIR /prometheus

EXPOSE     9090
VOLUME     [ "/prometheus" ]
ENTRYPOINT [ "/bin/prometheus" ]
CMD        [ "--config.file=/etc/prometheus/prometheus.yml", \
             "--storage.tsdb.path=/prometheus" ]
