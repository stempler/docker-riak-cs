# Riak CS
#
# VERSION       0.7.0

FROM phusion/baseimage:0.9.15
# Original MAINTAINER Hector Castro hectcastro@gmail.com
MAINTAINER Jason Stillwell dragonfax@gmail.com

# Environmental variables
ENV DEBIAN_FRONTEND noninteractive
ENV RIAK_VERSION 2.0.5
ENV RIAK_SHORT_VERSION 2.0
ENV RIAK_CS_VERSION 2.0.1
ENV RIAK_CS_SHORT_VERSION 2.0
ENV STANCHION_VERSION 2.0.0
ENV STANCHION_SHORT_VERSION 2.0
ENV SERF_VERSION 0.6.4

# Install dependencies
RUN apt-get update -qq && apt-get install unzip -y

# Install Riak
RUN curl --output /riak_${RIAK_VERSION}-1_amd64.deb http://s3.amazonaws.com/downloads.basho.com/riak/${RIAK_SHORT_VERSION}/${RIAK_VERSION}/ubuntu/precise/riak_${RIAK_VERSION}-1_amd64.deb
RUN (cd / && dpkg -i "riak_${RIAK_VERSION}-1_amd64.deb")

# Setup the Riak service
RUN mkdir -p /etc/service/riak
ADD bin/riak.sh /etc/service/riak/run

# Install Riak CS
RUN curl --output /riak-cs_${RIAK_CS_VERSION}-1_amd64.deb http://s3.amazonaws.com/downloads.basho.com/riak-cs/${RIAK_CS_SHORT_VERSION}/${RIAK_CS_VERSION}/ubuntu/trusty/riak-cs_${RIAK_CS_VERSION}-1_amd64.deb
RUN (cd / && dpkg -i "riak-cs_${RIAK_CS_VERSION}-1_amd64.deb")

# Setup the Riak CS service
RUN mkdir -p /etc/service/riak-cs
ADD bin/riak-cs.sh /etc/service/riak-cs/run

# Install Stanchion
RUN curl --output /stanchion_${STANCHION_VERSION}-1_amd64.deb http://s3.amazonaws.com/downloads.basho.com/stanchion/${STANCHION_SHORT_VERSION}/${STANCHION_VERSION}/ubuntu/trusty/stanchion_${STANCHION_VERSION}-1_amd64.deb
RUN (cd / && dpkg -i "stanchion_${STANCHION_VERSION}-1_amd64.deb")

# Setup the Stanchion service
RUN mkdir -p /etc/service/stanchion
ADD bin/stanchion.sh /etc/service/stanchion/run

# Setup automatic clustering for Riak
ADD bin/automatic_clustering.sh /etc/my_init.d/99_automatic_clustering.sh

# Install Serf
RUN curl -L --output /${SERF_VERSION}_linux_amd64.zip https://dl.bintray.com/mitchellh/serf/${SERF_VERSION}_linux_amd64.zip
RUN (cd / && unzip ${SERF_VERSION}_linux_amd64.zip -d /usr/bin/)

# Setup the Serf service
RUN mkdir -p /etc/service/serf && \
    adduser --system --disabled-password --no-create-home \
            --quiet --force-badname --shell /bin/bash --group serf && \
    echo "serf ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_serf && \
    chmod 0440 /etc/sudoers.d/99_serf
ADD bin/serf.sh /etc/service/serf/run
ADD bin/peer-member-join.sh /etc/service/serf/
ADD bin/seed-member-join.sh /etc/service/serf/

# Tune Riak and Riak CS configuration settings for the container
ADD etc/riak.conf /etc/riak/riak.conf
ADD etc/riak-cs.conf /etc/riak-cs/riak-cs.conf
ADD etc/riak-app.config /etc/riak/app.config
ADD etc/riak-cs-advanced.config /etc/riak-cs/advanced.config

# Make the Riak, Riak CS, and Stanchion log directories into volumes
VOLUME /var/lib/riak
VOLUME /var/log/riak
VOLUME /var/log/riak-cs
VOLUME /var/log/stanchion

# Open the HTTP port for Riak and Riak CS (S3)
EXPOSE 8098 8080 22

# Enable insecure SSH key
# See: https://github.com/phusion/baseimage-docker#using_the_insecure_key_for_one_container_only
RUN /usr/sbin/enable_insecure_key

# Cleanup
RUN rm "/riak_${RIAK_VERSION}-1_amd64.deb" && \
    rm "/riak-cs_${RIAK_CS_VERSION}-1_amd64.deb" && \
    rm "/stanchion_${STANCHION_VERSION}-1_amd64.deb" && \
    rm "/${SERF_VERSION}_linux_amd64.zip"
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Leverage the baseimage-docker init system
CMD ["/sbin/my_init", "--quiet"]
