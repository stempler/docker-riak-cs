#!/bin/sh
riak start && stanchion start && riak-cs start 
echo "Credentials" 
cat /CREDENTIALS
echo
tail -f /var/log/riak-cs/console.log
