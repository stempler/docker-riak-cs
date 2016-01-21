#! /bin/sh

IP_ADDRESS=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

# Ensure correct ownership and permissions on volumes
chown riakcs:riak /var/log/riak-cs
chmod 755 /var/log/riak-cs

# Open file descriptor limit
ulimit -n 4096

# Ensure the Erlang node name is set correctly
sed -i.bak "s/127.0.0.1/${IP_ADDRESS}/" /etc/riak-cs/riak-cs.conf

# Connect Riak CS instances to Stanchion
if env | egrep -q "SEED_PORT_8080_TCP_ADDR"; then
  sed -i.bak "s/stanchion_host = 0.0.0.0:8085/stanchion_host = ${SEED_PORT_8080_TCP_ADDR}:8085/" /etc/riak-cs/riak-cs.conf
fi

# Start Riak CS
exec /sbin/setuser riakcs riak-cs start
