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
# Elements of each array, slice and map to load. What's loaded grows roughly as
# MAXELEMS^DEPTH; 64 was tested up to ARGMATCH_DEPTH=10
ARG ARGMATCH_MAXELEMS=64
# Fields of each struct to load, in declaration order; -1 = all. Later fields
# aren't searched
ARG ARGMATCH_MAXFIELDS=-1
# Check only the first MAXCALLS calls of each function (0 = all); later calls
# skip the check, so they don't slow the program down
ARG ARGMATCH_MAXCALLS=3
# Absolute path (in the build stage) of a file of match strings, one per line.
# Files under prometheus/ are at /src/.
ARG ARGMATCH_MATCHFILE=
# Absolute path (in the build stage) of a log of connection stacktraces; every
# function in its stacks is checked too. Files under prometheus/ are at /src/.
ARG ARGMATCH_STACKLOG=
# Set to 1 (or true) to check only method receivers, not parameters
ARG ARGMATCH_RECVONLY=
# Set to false to also report values that contain a match string, not just
# values equal to one
ARG ARGMATCH_EXACT=true
# Set to false to also check the variables captured by closures and method values
ARG ARGMATCH_IGNORECLOSURES=true
# File (inside the container) that Prometheus writes matches to, overwriting it; empty means stderr
ARG ARGMATCH_OUT=
# Build argmatch, keeping the stack log parser at the same relative path
COPY golang.org-x-tools/gopls/conftamer/stacklog/ /golang.org-x-tools/gopls/conftamer/stacklog/
COPY dump_ancestors/argmatch/ /dump_ancestors/argmatch/
RUN cd /dump_ancestors/argmatch && go build -o argmatch .
# Copy in local Prom source
COPY prometheus/ /src/
RUN cd /src && \
    ARGMATCH_FUNC="${ARGMATCH_FUNC}" ARGMATCH_MATCH="${ARGMATCH_MATCH}" ARGMATCH_MATCHFILE="${ARGMATCH_MATCHFILE}" ARGMATCH_STACKLOG="${ARGMATCH_STACKLOG}" ARGMATCH_RECVONLY="${ARGMATCH_RECVONLY}" ARGMATCH_EXACT="${ARGMATCH_EXACT}" ARGMATCH_IGNORECLOSURES="${ARGMATCH_IGNORECLOSURES}" ARGMATCH_DEPTH="${ARGMATCH_DEPTH}" ARGMATCH_MAXELEMS="${ARGMATCH_MAXELEMS}" ARGMATCH_MAXFIELDS="${ARGMATCH_MAXFIELDS}" ARGMATCH_MAXCALLS="${ARGMATCH_MAXCALLS}" ARGMATCH_OUT="${ARGMATCH_OUT}" \
    GOFLAGS=-toolexec=/dump_ancestors/argmatch/argmatch \
    make build PROMU_BINARIES=prometheus

FROM quay.io/prometheus/prometheus:${VERSION}
COPY --from=build /src/prometheus /bin/prometheus
