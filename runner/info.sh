#!/usr/bin/env bash

# Retrieve the configuration based on the model
# Public variables:
#  MODEL: this is the RAKwireless gateway model
#  CONCENTRATOR: this is the concentrator type (SX1301, SX1302, SX1303 or SX1308)
#  INTERFACE: this is the interface (SPI or USB, defaults to SPI)
#  HAS_GPS: whether the gateway has GPS capabilities (0 or 1, defaults to 0)
#  HAS_LTE: whether the gateway has LTE capabilities, if yes it will try to use the GPS in the gateway via I2C (0 or 1, defaults to 0)
#  RESET_GPIO: defaults to 17 if SPI, 0 otherwise
#  POWER_EN_GPIO: defaults to 0
#  POWER_EN_LOGIC: defaults to 1
# Private variables
#  MODULE: this is the RAKwireless module used in the gateway
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

# RAK2247 and RAK833 have no GPS
if [[ "$MODULE" == "RAK2247" ]] || [[ "$MODULE" == "RAK833" ]]; then
    HAS_GPS=${HAS_GPS:-0}
fi

# The rest default to SPI, with GPS and without LTE
INTERFACE=${INTERFACE:-"SPI"}
HAS_GPS=${HAS_GPS:-1}
HAS_LTE=${HAS_LTE:-0}

# If interface is USB disable RESET_GPIO, otherwise default to 17
if [[ "$INTERFACE" == "SPI" ]]; then
    RESET_GPIO=${RESET_GPIO:-17}
else
    RESET_GPIO=${RESET_GPIO:-0}
fi

# The RAK833-SPI/USB has a SPDT to select USB/SPI interfaces
# If used with RAK2247 or RAK2287 hats this is wired to GPIO20
if [[ "$MODULE" == "RAK833" ]]; then
    if [[ "$INTERFACE" == "SPI" ]]; then
        POWER_EN_GPIO=${POWER_EN_GPIO:-20}
        POWER_EN_LOGIC=${POWER_EN_LOGIC:-0}
    fi
fi

# Otherwise the default is no power enable pin
POWER_EN_GPIO=${POWER_EN_GPIO:-0}
POWER_EN_LOGIC=${POWER_EN_LOGIC:-1}

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
        echo -e "\033[91mERROR: No network interface found. Cannot set gateway EUI.\033[0m"
    fi
    GATEWAY_EUI=$(ip link show $GATEWAY_EUI_NIC | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"FFFE"$4$5$6}')
fi
GATEWAY_EUI=${GATEWAY_EUI^^}

# Defaults to TTN server v3, EU1 region, use a custom SERVER_HOST and SERVER_PORT to change this
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

# Radio device
if [[ "${INTERFACE}" == "SPI" ]]; then

    RADIO_DEV=${RADIO_DEV:-"/dev/spidev0.0"}
    export LORAGW_SPI=$RADIO_DEV

    # Set default SPI speed for SX1301/8 concentrators to 2MHz
    if [[ "${CONCENTRATOR}" == "SX1301" ]] || [[ "${CONCENTRATOR}" == "SX1308" ]]; then
        SPI_SPEED=${SPI_SPEED:-2000000}
    fi
    export LORAGW_SPI_SPEED=${SPI_SPEED:-8000000}

else

    RADIO_DEV=${RADIO_DEV:-"/dev/ttyACM0"}

fi

# Default GPS device based on LTE presence
if [[ $HAS_LTE -eq 1 ]]; then
    GPS_DEV=${GPS_DEV:-"/dev/i2c-1"}
else
    GPS_DEV=${GPS_DEV:-"/dev/ttyAMA0"}
fi

# Debug
echo "------------------------------------------------------------------"

echo "Model:         $MODEL"
echo "Module:        $MODULE"
echo "Concentrator:  $CONCENTRATOR"
echo "Interface:     $INTERFACE"
echo "Radio Device:  $RADIO_DEV"
if [[ "$INTERFACE" == "SPI" ]]; then
echo "SPI Speed:     $LORAGW_SPI_SPEED"
fi
echo "Has GPS:       $HAS_GPS"
if [[ $HAS_GPS -eq 1 ]]; then
echo "GPS Device:    $GPS_DEV"
fi

echo "Has LTE:       $HAS_LTE"

if [[ "$INTERFACE" == "SPI" ]]; then
echo "Reset GPIO:    $RESET_GPIO"
echo "Enable GPIO:   $POWER_EN_GPIO"
if [[ $POWER_EN_GPIO -ne 0 ]]; then
echo "Enable Logic:  $POWER_EN_LOGIC"
fi
fi

echo "Main NIC:      $GATEWAY_EUI_NIC"
echo "Gateway EUI:   $GATEWAY_EUI"
echo "Server:        $SERVER_HOST:$SERVER_PORT"
echo "Band:          $BAND"
echo "Use fake GPS:  $FAKE_GPS"

if [[ "$FAKE_GPS" == "true" ]]; then
echo "Latitude:      $GPS_LATITUDE"
echo "Longitude:     $GPS_LONGITUDE"
echo "Altitude:      $GPS_ALTITUDE"
fi 

if [[ -f ./global_conf.json ]]; then
echo "Custom global_conf.json found!"
fi

echo "------------------------------------------------------------------"

