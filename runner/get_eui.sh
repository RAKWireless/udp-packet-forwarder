#!/usr/bin/env bash 
cat /opt/ttn-gateway/packet_forwarder/lora_pkt_fwd/local_conf.json | jq '.gateway_conf.gateway_ID' | sed 's/"//g'
