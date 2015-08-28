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

# Install dependencies
RUN apt-get update -qq && apt-get install unzip -y

# Install Riak
RUN curl --output /riak_${RIAK_VERSION}-1_amd64.deb http://s3.amazonaws.com/downloads.basho.com/riak/${RIAK_SHORT_VERSION}/${RIAK_VERSION}/ubuntu/precise/riak_${RIAK_VERSION}-1_amd64.deb
RUN (cd / && dpkg -i "riak_${RIAK_VERSION}-1_amd64.deb")

# Install Riak CS
RUN curl --output /riak-cs_${RIAK_CS_VERSION}-1_amd64.deb http://s3.amazonaws.com/downloads.basho.com/riak-cs/${RIAK_CS_SHORT_VERSION}/${RIAK_CS_VERSION}/ubuntu/trusty/riak-cs_${RIAK_CS_VERSION}-1_amd64.deb
RUN (cd / && dpkg -i "riak-cs_${RIAK_CS_VERSION}-1_amd64.deb")

# Install Stanchion
RUN curl --output /stanchion_${STANCHION_VERSION}-1_amd64.deb http://s3.amazonaws.com/downloads.basho.com/stanchion/${STANCHION_SHORT_VERSION}/${STANCHION_VERSION}/ubuntu/trusty/stanchion_${STANCHION_VERSION}-1_amd64.deb
RUN (cd / && dpkg -i "stanchion_${STANCHION_VERSION}-1_amd64.deb")

ADD bin/startup.sh /bin/startup.sh

# Tune Riak and Riak CS configuration settings for the container
ADD etc/riak.conf /etc/riak/riak.conf
ADD etc/riak-cs.conf /etc/riak-cs/riak-cs.conf
ADD etc/riak-advanced.config /etc/riak/advanced.config
ADD etc/riak-cs-advanced.config /etc/riak-cs/advanced.config

# Make the Riak, Riak CS, and Stanchion log directories into volumes
VOLUME /var/lib/riak
VOLUME /var/log/riak
VOLUME /var/log/riak-cs
VOLUME /var/log/stanchion

# Open the HTTP port for Riak and Riak CS (S3)
EXPOSE 8098 8080 22

# Cleanup
RUN rm "/riak_${RIAK_VERSION}-1_amd64.deb" && \
    rm "/riak-cs_${RIAK_CS_VERSION}-1_amd64.deb" && \
    rm "/stanchion_${STANCHION_VERSION}-1_amd64.deb"
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create the Riak CS User.
#
# requires starting riak-cs.
# all in one line so it gets cached as a whole.
# necessary as docker can't cache running background processes.
RUN riak start && stanchion start && riak-cs start && (curl -X POST http://127.0.0.1:8080/riak-cs/user -H 'Content-Type: application/json' --data '{"email":"foobar@example.com", "name":"foo bar"}'  > /CREDENTIALS ) && (riak-cs stop; stanchion stop; riak stop)

# Leverage the baseimage-docker init system
CMD "/bin/startup.sh"
