#!/usr/bin/env bash

function push_variables {
    if [[ "$BALENA_DEVICE_UUID" != "" ]]
    then

        ID=$(curl -sX GET "https://api.balena-cloud.com/v5/device?\$filter=uuid%20eq%20'$BALENA_DEVICE_UUID'" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $BALENA_API_KEY" | \
            jq ".d | .[0] | .id")

        TAG=$(curl -sX POST \
            "https://api.balena-cloud.com/v5/device_tag" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $BALENA_API_KEY" \
            --data "{ \"device\": \"$ID\", \"tag_key\": \"EUI\", \"value\": \"$GATEWAY_EUI\" }" > /dev/null)

    fi
}

function idle {
   [[ "$BALENA_DEVICE_UUID" != "" ]] && balena-idle || exit 1
}

# Load variables
source ./info.sh

# Check we have defined a concentrator
if [[ -z ${CONCENTRATOR} ]] ;
then
    echo -e "\033[91mERROR: CONCENTRATOR variable not set.\nSet the CONCENTRATOR or the gateway MODEL you are using.\033[0m"
	idle
fi

# Check we have an EUI
if [[ -z ${GATEWAY_EUI} ]] ;
then
    echo -e "\033[91mERROR: GATEWAY_EUI not set.\033[0m"
	idle
fi

# Check we have a valid BAND
declare -a BANDS=( as_923_1, as_923_2, as_923_3, as_923_4, au_915_928, cn_470_510, eu_433, eu_863_870, in_865_867, kr_920_923, ru_864_870, us_902_928 )
#declare -a BANDS=( as_915_921, as_915_928, as_917_920, as_920_923, au_915_928, cn_470_510, eu_433, eu_863_870, in_865_867, kr_920_923, ru_864_870, us_902_928 )

if [[ ! " ${BANDS[*]} " =~ "${BAND}" ]]; then
    echo -e "\033[91mERROR: Wrong BAND setting ($BAND).\033[0m"
	idle
fi

# Push variables to Balena
push_variables

# Now we can get the FOLDER and GLOBAL_CONF variables
if [[ "$CONCENTRATOR" == "SX1301" ]]; then
    if [[ $HAS_GPS -eq 1 ]]; then
        FOLDER="rak7243"
        if [[ $HAS_LTE -eq 1 ]]; then
            GLOBAL_CONF="global_conf_i2c"
        else
            GLOBAL_CONF="global_conf_uart"
        fi
    else
        if [[ "$INTERFACE" == "SPI" ]]; then
            FOLDER="rak2247_spi"
        else
            FOLDER="rak2247_usb"
        fi
        GLOBAL_CONF="global_conf"
    fi
elif [[ "$CONCENTRATOR" == "SX1302" ]]; then
    FOLDER="rak2287"
    if [[ "$INTERFACE" == "SPI" ]]; then
        if [[ $HAS_LTE -eq 1 ]]; then
            GLOBAL_CONF="global_conf_i2c"
        else
            GLOBAL_CONF="global_conf_uart"
        fi
    else
        GLOBAL_CONF="global_conf_usb"
    fi
elif [[ "$CONCENTRATOR" == "SX1303" ]]; then
    FOLDER="rak5146"
    if [[ "$INTERFACE" == "SPI" ]]; then
        if [[ $HAS_LTE -eq 1 ]]; then
            GLOBAL_CONF="global_conf_i2c"
        else
            GLOBAL_CONF="global_conf_uart"
        fi
    else
        GLOBAL_CONF="global_conf_usb"
    fi
elif [[ "$CONCENTRATOR" == "SX1308" ]]; then
    FOLDER="rak2246"
    GLOBAL_CONF="global_conf"
fi

# Copy binaries based on configuration
INSTALL_DIR=/opt/ttn-gateway
mkdir -p $INSTALL_DIR
if [[ -d ./$FOLDER/lora_gateway ]]; then
    cp -rf ./$FOLDER/lora_gateway $INSTALL_DIR/
fi
cp -rf ./$FOLDER/packet_forwarder $INSTALL_DIR/

# We are resetting the concentrator from outside the lora_pkt_fwd
echo "exit 0" > $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/reset_lgw.sh

# Global configuration file
GLOBAL_CONFIG_FILE=$INSTALL_DIR/packet_forwarder/lora_pkt_fwd/global_conf.json
if [[ -f ./global_conf.json ]]; then
    cp -f ./global_conf.json $GLOBAL_CONFIG_FILE
else
    if [ "$BAND" == "as_923_1" ]; then
        BAND="as_915_928"
    fi
    if [ "$BAND" == "as_923_2" ]; then
        BAND="as_920_923"
    fi
    if [ "$BAND" == "as_923_3" ]; then
        BAND="as_915_921"
    fi
    if [ "$BAND" == "as_923_4" ]; then
        BAND="as_917_920"
    fi  
    cp -f ./$FOLDER/$GLOBAL_CONF/global_conf.$BAND.json $GLOBAL_CONFIG_FILE
    if [ -n $RADIO_DEV ]; then
        sed -i "s#\"com_path\":\s*.*,#\"com_path\": \"$RADIO_DEV\",#"  $GLOBAL_CONFIG_FILE
    fi
fi

# Modify local configuration file
LOCAL_CONFIG_FILE=$INSTALL_DIR/packet_forwarder/lora_pkt_fwd/local_conf.json
cat > $LOCAL_CONFIG_FILE << EOL
{
    "gateway_conf": {
        "gateway_ID": "$GATEWAY_EUI",
        "server_address": "$SERVER_HOST",
        "serv_port_up": $SERVER_PORT,
        "serv_port_down": $SERVER_PORT,
        "gps_tty_path": "$GPS_DEV",
        "fake_gps": $FAKE_GPS,
        "ref_latitude": ${GPS_LATITUDE:-0},
        "ref_longitude": ${GPS_LONGITUDE:-0},
        "ref_altitude": ${GPS_ALTITUDE:-0}
    }
}
EOL

# Setup libraries and USB rules
ldconfig
udevadm control --reload-rules && udevadm trigger

# Reset the concentrator
RESET_GPIO=$RESET_GPIO POWER_EN_GPIO=$POWER_EN_GPIO POWER_EN_LOGIC=$POWER_EN_LOGIC ./reset.sh

# Start packet forwarder
cd $INSTALL_DIR/packet_forwarder/lora_pkt_fwd
./lora_pkt_fwd

