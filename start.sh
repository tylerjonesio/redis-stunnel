#!/bin/sh

echo "connect = $REDIS_PORT_6379_TCP_ADDR:$REDIS_PORT_6379_TCP_PORT" >> /stunnel/stunnel.conf
stunnel4 /stunnel/stunnel.conf
