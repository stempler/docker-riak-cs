#!/bin/sh
riak start && stanchion start && riak-cs start && tail -f /var/log/riak-cs/console.log
