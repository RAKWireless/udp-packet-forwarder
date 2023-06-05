#!/usr/bin/env bash 
cat /app/local_conf.json | jq '.gateway_conf.gateway_ID' | sed 's/"//g'
