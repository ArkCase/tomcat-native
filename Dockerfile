###########################################################################################################
#
# How to build:
#
# docker build -t arkcase/pentaho-ce-install:latest .
#
###########################################################################################################

ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG VER="1.0.0"

ARG TOMCAT_NATIVE_KEYS_URL="https://downloads.apache.org/tomcat/tomcat-connectors/KEYS"
ARG BUILD_HOME="/tomcat-native"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base-java"
ARG BASE_VER="24.04"
ARG BASE_VER_PFX=""
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}:${BASE_VER_PFX}${BASE_VER}"

FROM "${BASE_IMG}" AS builder

ARG TOMCAT_NATIVE_KEYS_URL
ARG BUILD_HOME

RUN apt-get -y install \
        libapr1-dev \
        libssl-dev \
      && \
    apt-get clean

#
# Build the Tomcat native APR connector
#
# We use a space-separated list of all the versions available
# to make sure we build them all, so it's easy for downstream
# installations to cherrypick whatever they want to use.
#
# For example: Pentaho uses Tomcat 9, but requires version 1.2.39,
# while ArkCase is perfectly happy with 1.3.5 or 2.0.12 (when on
# Tomcat 11).
ARG TOMCAT_NATIVE_ALL="1.2.39 1.3.5 2.0.12"

COPY --chown=root:root --chmod=0755 build-script /usr/local/bin
RUN for TOMCAT_NATIVE_VER in ${TOMCAT_NATIVE_ALL} ; do \
      export TOMCAT_NATIVE_BUILD_HOME="${BUILD_HOME}/${TOMCAT_NATIVE_VER}" ; \
      export TOMCAT_NATIVE_URL="https://archive.apache.org/dist/tomcat/tomcat-connectors/native/${TOMCAT_NATIVE_VER}/source/tomcat-native-${TOMCAT_NATIVE_VER}-src.tar.gz" ; \
      mkdir -p "${TOMCAT_NATIVE_BUILD_HOME}" ; \
      build-script ; \
      ( cd "${BUILD_HOME}" && ln -sv "${TOMCAT_NATIVE_VER}" "${TOMCAT_NATIVE_VER%.*}" ) ; \
    done

FROM scratch

ARG BUILD_HOME

COPY --from=builder "${BUILD_HOME}" "/"
