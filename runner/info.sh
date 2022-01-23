#!/usr/bin/env bash

# Retrieve the configuration based on the model
# Public variables:
#  MODEL: this is the RAKwireless gateway model
#  CONCENTRATOR: this is the concentrator type (SX1301, SX1302, SX1303 or SX1308)
#  INTERFACE: this is the interface (SPI or USB, defaults to SPI)
#  GPS: whether the gateway has GPS capabilities (0 or 1, defaults to 0)
#  LTE: whether the gateway has LTE capabilities, if yes it will try to use the GPS in the gateway via I2C (0 or 1, defaults to 0)
#  GW_RESET_GPIO: defaults to 17
#  GW_POWER_EN_GPIO: defaults to 0
# Private variables
#  MODULE: this is the RAKwireless module usedin the gateway
#  FOLDER: this is the folder with the binaries
#  GLOBAL_CONF: this is the global_conf folder to use

# First we look for the model
if [[ "$MODEL" == "RAK7243" ]] || [[ "$MODEL" == "RAK7244" ]]; then
    MODULE="RAK2245"
elif [[ "$MODEL" == "RAK7243C" ]] || [[ "$MODEL" == "RAK7244C" ]]; then
    MODULE="RAK2245"
    HAS_LTE=${HAS_LTE:-1}
elif [[ "$MODEL" == "RAK7246" ]]; then
    MODULE="RAK2246"
    HAS_GPS=${HAS_GPS:-0}
elif [[ "$MODEL" == "RAK7246G" ]]; then
    MODULE="RAK2246"
elif [[ "$MODEL" == "RAK7248" ]]; then
    MODULE="RAK2287"
elif [[ "$MODEL" == "RAK7248C" ]]; then
    MODULE="RAK2287"
    HAS_LTE=${HAS_LTE:-1}
elif [[ "$MODEL" == "RAK7271" ]]; then
    MODULE="RAK2287"
    INTERFACE=${INTERFACE:-"USB"}
elif [[ "$MODEL" == "RAK7371" ]]; then
    MODULE="RAK5146"
    INTERFACE=${INTERFACE:-"USB"}
fi

# Get the concentrator based on MODEL/MODULE
declare -A MODULE_CONCENTRATOR_MAP=([RAK831]=SX1301 [RAK833]=SX1301 [RAK2245]=SX1301 [RAK2246]=SX1308 [RAK2247]=SX1301 [RAK2287]=SX1302 [RAK5146]=SX1303)
if [[ -z ${MODULE} ]]; then
    MODULES=${!MODULE_CONCENTRATOR_MAP[@]}
    if [[ " ${MODULES[*]} " =~ " ${MODEL}" ]]; then
        MODULE=$MODEL
    fi
fi
CONCENTRATOR=${CONCENTRATOR:-${MODULE_CONCENTRATOR_MAP[$MODULE]}}

# Exceptions
if [[ "$MODULE" == "RAK2247" ]]; then
    HAS_GPS=${HAS_GPS:-0}
fi

# Defaults
INTERFACE=${INTERFACE:-"SPI"}
HAS_GPS=${HAS_GPS:-1}
HAS_LTE=${HAS_LTE:-0}

# Map hardware pins to GPIO on Raspberry Pi
declare -a GPIO_MAP=( -1 -1 -1 2 -1 3 -1 4 14 -1 15 17 18 27 -1 22 23 -1 24 10 -1 9 25 11 8 -1 7 0 1 5 -1 6 12 13 -1 19 16 26 20 -1 21 )
GW_RESET_PIN=${GW_RESET_PIN:-11}
GW_RESET_GPIO=${GW_RESET_GPIO:-${GPIO_MAP[$GW_RESET_PIN]}}

# Some board might have an enable GPIO
GW_POWER_EN_GPIO=${GW_POWER_EN_GPIO:-0}

# Get the Gateway EUI
if [[ -z $GATEWAY_EUI ]]; then
    GATEWAY_EUI_NIC=${GATEWAY_EUI_NIC:-"eth0"}
    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        GATEWAY_EUI_NIC="eth0"
    fi
    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        GATEWAY_EUI_NIC="wlan0"
    fi
    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        GATEWAY_EUI_NIC="usb0"
    fi
    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        # Last chance: get the most used NIC based on received bytes
        GATEWAY_EUI_NIC=$(cat /proc/net/dev | tail -n+3 | sort -k2 -nr | head -n1 | cut -d ":" -f1 | sed 's/ //g')
    fi
    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        echo -e "\033[91mERROR: No network interface found. Cannot set gateway ID.\033[0m"
    fi
    GATEWAY_EUI=$(ip link show $GATEWAY_EUI_NIC | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"FFFE"$4$5$6}')
fi
GATEWAY_EUI=${GATEWAY_EUI^^}

# Defaults to TTN server v3, EU1 region, use a custom SERVER_HOST to change this
TTN_REGION=${TTN_REGION:-"eu1"}
SERVER_HOST=${SERVER_HOST:-"${TTN_REGION}.cloud.thethings.network"} 
SERVER_PORT=${SERVER_PORT:-1700}

# Get the band to use (must be lowercase)
BAND=${BAND:-"eu_863_870"}
BAND=${BAND,,}

# Even if the gateway has a GPS, you can fake it
[[ $HAS_GPS -eq 1 ]] && FAKE_GPS="false" || FAKE_GPS="true"
if [[ ! -z ${GPS_LATITUDE} ]]; then
    FAKE_GPS="true"
fi

# Debug
echo "------------------------------------------------------------------"
echo "Model:         $MODEL"
echo "Module:        $MODULE"
echo "Concentrator:  $CONCENTRATOR"
echo "Interface:     $INTERFACE"
echo "Has GPS:       $HAS_GPS"
echo "Has LTE:       $HAS_LTE"
echo "Main NIC:      $GATEWAY_EUI_NIC"
echo "Gateway EUI:   $GATEWAY_EUI"
echo "Reset GPIO:    $GW_RESET_GPIO"
echo "Enable GPIO:   $GW_POWER_EN_GPIO"
echo "Server:        $SERVER_HOST:$SERVER_PORT"
echo "Band:          $BAND"
echo "Use fake GPS:  $FAKE_GPS"
if [[ "$FAKE_GPS" == "true" ]]; then
echo "Latitude:      $GPS_LATITUDE"
echo "Longitude:     $GPS_LONGITUDE"
echo "Altitude:      $GPS_ALTITUDE"
fi 
echo "Contact email: $EMAIL"
echo "Description:   $DESCRIPTION"
echo "------------------------------------------------------------------"

