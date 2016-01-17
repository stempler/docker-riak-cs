#!/bin/bash
if [ -z "$1" ]
then
  echo "Error: Please provide Riak CS container name as first argument"
  exit 1
else
  echo "Getting credentials from Riak CS on $1 ..."
fi

echo "Access Key: "
docker exec $1 egrep "admin_key" /etc/riak-cs/app.config | cut -d'"' -f2
echo "Secret Key:"
docker exec $1 egrep "admin_secret" /etc/riak-cs/app.config | cut -d'"' -f2
