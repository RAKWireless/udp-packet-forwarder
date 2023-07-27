#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------

COLOR_INFO="\e[32m" # green
COLOR_WARNING="\e[33m" # yellow
COLOR_ERROR="\e[31m" # red
COLOR_END="\e[0m"

# -----------------------------------------------------------------------------
# Balena methods
# -----------------------------------------------------------------------------

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
   [[ "$BALENA_DEVICE_UUID" != "" ]] && balena-idle || sleep 2; exit 1
}

# -----------------------------------------------------------------------------
# Chip ID
# -----------------------------------------------------------------------------

function chip_id {

    local DESIGN=$1
    local DEVICE=$2
    
    CHIP_ID_COMMAND="./artifacts/${DESIGN,,}/chip_id"

    if [[ -f $CHIP_ID_COMMAND ]]; then
        
        if [[ "$DESIGN" == "2g4" ]]; then
            echo $( $CHIP_ID_COMMAND -d $DEVICE | grep 'EUI' | sed 's/^.*0x//' | tr [a-z] [A-Z] )
            return
        fi
        
        if [[ "$DESIGN" == "corecell" ]]; then
            if [[ "$DEVICE" == *"tty"* ]]; then COM_TYPE="-u"; fi
            echo $( $CHIP_ID_COMMAND $COM_TYPE -d $DEVICE | grep 'EUI' | sed 's/^.*0x//' | tr [a-z] [A-Z] )
            return
        fi
        
        #if [[ "$DESIGN" == "picocell" ]]; then
        #    echo $( $CHIP_ID_COMMAND | sed 's/^.*0x//' | tr [a-z] [A-Z] )
        #    return
        #fi
        
    fi
    
    echo ""
    
}

# -----------------------------------------------------------------------------
# Identify concentrator
# -----------------------------------------------------------------------------

# MODEL is the only required variable
if [[ -z ${MODEL} ]]; then
    echo -e "${COLOR_ERROR}ERROR: MODEL variable not set${COLOR_END}"
	idle
fi

# Get the concentrator based on MODEL
declare -A MODEL_MAP=(
    [RAK7243]=SX1301 [RAK7243C]=SX1301 [RAK7244]=SX1301 [RAK7244C]=SX1301 [RAK7246]=SX1308 [RAK7246G]=SX1308 [RAK7248]=SX1302 [RAK7248C]=SX1302 [RAK7271]=SX1302 [RAK7371]=SX1303 
    [RAK831]=SX1301 [RAK833]=SX1301 [RAK2245]=SX1301 [RAK2246]=SX1308 [RAK2247]=SX1301 [RAK2287]=SX1302 [RAK5146]=SX1303 [RAK5148]=SX1280
    [IC880A]=SX1301 [WM1302]=SX1302 [R11E-LR8]=SX1308 [R11E-LR9]=SX1308 [R11E-LR2]=SX1280 [SX1280ZXXXXGW1]=SX1280
    [SX1301]=SX1301 [SX1302]=SX1302 [SX1303]=SX1303 [SX1308]=SX1308
)
CONCENTRATOR=${MODEL_MAP[$MODEL]}
if [[ "${CONCENTRATOR}" == "" ]]; then
    echo -e "${COLOR_ERROR}ERROR: Unknown MODEL value ($MODEL). Valid values are: ${!MODEL_MAP[@]}${COLOR_END}"
	idle
fi

# -----------------------------------------------------------------------------
# Identify interface
# -----------------------------------------------------------------------------

# Models with USB interface
MODELS_WITH_USB="RAK7271 RAK7371 RAK5148 R11E-LR2 R11E-LR8 R11E-LR9 SX1280ZXXXXGW1"
if [[ $MODELS_WITH_USB =~ (^|[[:space:]])$MODEL($|[[:space:]]) ]]; then
    INTERFACE="${INTERFACE:-"USB"}"
elif [[ "${CONCENTRATOR}" == "SX1301" ]] || [[ "${CONCENTRATOR}" == "SX1308" ]]; then
    INTERFACE=${INTERFACE:-"SPI"}
else
    INTERFACE=${INTERFACE:-"ANY"}
fi

# -----------------------------------------------------------------------------
# Identify concentrator design
# -----------------------------------------------------------------------------

# Get the DESIGN based on MODEL, CONCENTRATOR and INTERFACE
if [[ "$MODEL" == "R11E-LR8" ]] || [[ "$MODEL" == "R11E-LR9" ]]; then
    DESIGN=${DESIGN:-"picocell"}
elif [[ "$CONCENTRATOR" == "SX1302" ]] || [[ "$CONCENTRATOR" == "SX1303" ]]; then
    DESIGN=${DESIGN:-"corecell"}
elif [[ "$CONCENTRATOR" == "SX1280" ]]; then
    DESIGN=${DESIGN:-"2g4"}
elif [[ "$INTERFACE" == "SPI" ]]; then
    DESIGN=${DESIGN:-"v2/native"}
else
    DESIGN=${DESIGN:-"v2/ftdi"}
fi

# -----------------------------------------------------------------------------
# Radio device identification
# -----------------------------------------------------------------------------

# Auto detect
if [[ "${RADIO_DEV:-AUTO}" == "AUTO" ]]; then

    unset RADIO_DEV

    if [[ "${DESIGN}" != *"v2"* ]]; then

        if [[ "${INTERFACE}" == "ANY" ]]; then
            DEVICES=$( ls /dev/spidev* /dev/ttyACM* /dev/ttyUSB* 2> /dev/null )
        elif [[ "${INTERFACE}" == "SPI" ]]; then
            DEVICES=$( ls /dev/spidev* 2> /dev/null )
        else
            DEVICES=$( ls /dev/ttyACM* /dev/ttyUSB* 2> /dev/null )
        fi

        FOUND=0
        RADIO_NUM=${RADIO_NUM:-1}
        for DEVICE in $DEVICES; do
            #echo "Checking $DESIGN on $DEVICE"
            RESPONSE=$( chip_id $DESIGN $DEVICE )
            if [[ "${RESPONSE}" != "" ]]; then
                FOUND=$(( $FOUND + 1 ))
                if [[ ${FOUND} -eq $RADIO_NUM ]]; then
                    RADIO_DEV=$DEVICE
                    break
                fi
            fi
        done

        if [[ ${FOUND} -eq 0 ]]; then
            echo -e "${COLOR_WARNING}ERROR: RADIO_DEV set to auto discover but no concentrator found! (INTERFACE set to $INTERFACE) ${COLOR_END}"
        else
            if [[ "${INTERFACE}" == "ANY" ]]; then
                if [[ "${RADIO_DEV}" == *"spi"* ]]; then 
                    INTERFACE="SPI"
                else 
                    INTERFACE="USB"
                fi
            fi
        fi
    
    fi
fi

# -----------------------------------------------------------------------------
# Radio device defaults
# -----------------------------------------------------------------------------

# Radio device
if [[ "${INTERFACE}" == "SPI" ]]; then

    RADIO_DEV=${RADIO_DEV:-"/dev/spidev0.0"}

    # Set default SPI speed for SX1301/8 concentrators to 2MHz
    if [[ "${CONCENTRATOR}" == "SX1301" ]] || [[ "${CONCENTRATOR}" == "SX1308" ]]; then
        SPI_SPEED=${SPI_SPEED:-2000000}
    fi
    export LORAGW_SPI_SPEED=${SPI_SPEED:-8000000}

else

    MODELS_WITHOUT_ACM="RAK833 RAK2247"
    if [[ $MODELS_WITHOUT_ACM =~ (^|[[:space:]])$MODEL($|[[:space:]]) ]]; then
        RADIO_DEV=${RADIO_DEV:-"/dev/ttyUSB0"}
    fi
    RADIO_DEV=${RADIO_DEV:-"/dev/ttyACM0"}

fi

if [[ ! -e $RADIO_DEV ]]; then
    echo -e "${COLOR_ERROR}ERROR: $RADIO_DEV does not exist${COLOR_END}"
    idle
fi

export LORAGW_SPI=$RADIO_DEV

# -----------------------------------------------------------------------------
# GPIO configuration
# -----------------------------------------------------------------------------

# If interface is USB disable RESET_GPIO, otherwise default to 17
if [[ "$INTERFACE" == "SPI" ]]; then
    RESET_GPIO=${RESET_GPIO:-17}
else
    RESET_GPIO=${RESET_GPIO:-0}
fi

# The RAK833-SPI/USB has a SPDT to select USB/SPI interfaces
# If used with RAK2247 or RAK2287 hats this is wired to GPIO20
if [[ "$MODEL" == "RAK833" ]]; then
    if [[ "$INTERFACE" == "SPI" ]]; then
        POWER_EN_GPIO=${POWER_EN_GPIO:-20}
        POWER_EN_LOGIC=${POWER_EN_LOGIC:-0}
    fi
fi

# Otherwise the default is no power enable pin
POWER_EN_GPIO=${POWER_EN_GPIO:-0}
POWER_EN_LOGIC=${POWER_EN_LOGIC:-1}

# -----------------------------------------------------------------------------
# Copy binaries and scripts
# -----------------------------------------------------------------------------

# Copy binaries based on configuration
cp -rf ./artifacts/${DESIGN,,}/* ./

# Create reset file
USE_LIBGPIOD=${USE_LIBGPIOD:-0}
if [[ $USE_LIBGPIOD -eq 0 ]]; then
    cp reset_lgw.sh.legacy reset_lgw.sh
else
    cp reset_lgw.sh.gpiod reset_lgw.sh
fi
sed -i "s#{{RESET_GPIO}}#${RESET_GPIO:-17}#" reset_lgw.sh
sed -i "s#{{POWER_EN_GPIO}}#${POWER_EN_GPIO:-0}#" reset_lgw.sh
sed -i "s#{{POWER_EN_LOGIC}}#${POWER_EN_LOGIC:-1}#" reset_lgw.sh
chmod +x reset_lgw.sh

# -----------------------------------------------------------------------------
# Gateway EUI configuration
# -----------------------------------------------------------------------------

# Get the CHIP ID
CHIP_ID=$( chip_id $DESIGN $RADIO_DEV )

# Source to check for EUI
GATEWAY_EUI_NIC=${GATEWAY_EUI_NIC:-"manual"} # deprecated
GATEWAY_EUI_SOURCE=${GATEWAY_EUI_SOURCE:-$GATEWAY_EUI_NIC}

# Get the Gateway EUI
if [[ "$GATEWAY_EUI" == "" ]]; then

    if [[ "$GATEWAY_EUI_SOURCE" == "chip" ]]; then
        GATEWAY_EUI=$CHIP_ID
    fi

    if [[ "$GATEWAY_EUI" == "" ]]; then

        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            GATEWAY_EUI_SOURCE="eth0"
        fi
        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            GATEWAY_EUI_SOURCE="wlan0"
        fi
        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            GATEWAY_EUI_SOURCE="usb0"
        fi
        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            GATEWAY_EUI_SOURCE="eth1"
        fi
        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            # Last chance: get the most used NIC based on received bytes
            GATEWAY_EUI_SOURCE=$(cat /proc/net/dev | tail -n+3 | sort -k2 -nr | head -n1 | cut -d ":" -f1 | sed 's/ //g')
        fi
        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            echo -e "${COLOR_ERROR}ERROR: No network interface found. Cannot set gateway EUI.${COLOR_END}"
        fi
        GATEWAY_EUI=$(ip link show $GATEWAY_EUI_SOURCE | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"FFFE"$4$5$6}')
    
    fi

fi
GATEWAY_EUI=${GATEWAY_EUI^^}

# Check we have an EUI
if [[ -z ${GATEWAY_EUI} ]] ; then
    echo -e "${COLOR_ERROR}ERROR: GATEWAY_EUI not set.${COLOR_END}"
	idle
fi

# -----------------------------------------------------------------------------
# Server configuration
# -----------------------------------------------------------------------------

# Defaults to TTN server v3, EU1 region, use a custom SERVER_HOST and SERVER_PORT to change this
TTN_REGION=${TTN_REGION:-"eu1"}
SERVER_HOST=${SERVER_HOST:-"${TTN_REGION}.cloud.thethings.network"} 
SERVER_PORT=${SERVER_PORT:-1700}

# -----------------------------------------------------------------------------
# Band configuration
# -----------------------------------------------------------------------------

# Get the band to use (must be lowercase)
if [[ "$CONCENTRATOR" == "SX1280" ]]; then
    BAND="global"
fi
BAND=${BAND:-"eu_863_870"}
BAND=${BAND,,}

# Map AS bands common names to standard name
if [ "$BAND" == "as_923_1" ]; then BAND="as_915_928"; fi
if [ "$BAND" == "as_923_2" ]; then BAND="as_920_923"; fi
if [ "$BAND" == "as_923_3" ]; then BAND="as_915_921"; fi
if [ "$BAND" == "as_923_4" ]; then BAND="as_917_920"; fi  

# Check we have a valid BAND
declare -a BANDS=( as_915_921, as_915_928, as_917_920, as_920_923, au_915_928, cn_470_510, eu_433, eu_863_870, in_865_867, kr_920_923, ru_864_870, us_902_928, global )
if [[ ! " ${BANDS[*]} " =~ "${BAND}" ]]; then
    echo -e "${COLOR_ERROR}ERROR: Wrong BAND setting ($BAND).${COLOR_END}"
	idle
fi

# -----------------------------------------------------------------------------
# GPS Configuration
# -----------------------------------------------------------------------------

# Models with GPS
MODELS_WITH_GPS="RAK7243 RAK7243C RAK7244 RAK7244C RAK7246G RAK7248 RAK7248C RAK831 RAK2245 RAK2287 RAK5146"
if [[ $MODELS_WITH_GPS =~ (^|[[:space:]])$MODEL($|[[:space:]]) ]]; then
    HAS_GPS=${HAS_GPS:-1}
fi
HAS_GPS=${HAS_GPS:-0}

# Even if the gateway has a GPS, you can fake it
[[ $HAS_GPS -eq 1 ]] && FAKE_GPS="false" || FAKE_GPS="true"
if [[ ! -z ${GPS_LATITUDE} ]]; then
    FAKE_GPS="true"
fi

# Models with LTE board on it (hence GPS will use I2C)
MODELS_WITH_LTE="RAK7243C RAK7244C RAK7248C"
if [[ $MODELS_WITH_LTE =~ (^|[[:space:]])$MODEL($|[[:space:]]) ]]; then
    GPS_DEV=${GPS_DEV:-"/dev/i2c-1"}
fi
GPS_DEV=${GPS_DEV:-"/dev/ttyAMA0"}

# -----------------------------------------------------------------------------
# Debug
# -----------------------------------------------------------------------------

echo -e "${COLOR_INFO}------------------------------------------------------------------${COLOR_END}"

echo -e "${COLOR_INFO}Model:         $MODEL${COLOR_END}"
echo -e "${COLOR_INFO}Concentrator:  $CONCENTRATOR${COLOR_END}"
echo -e "${COLOR_INFO}Design:        ${DESIGN^^}${COLOR_END}"
echo -e "${COLOR_INFO}Interface:     $INTERFACE${COLOR_END}"
echo -e "${COLOR_INFO}Radio Device:  $RADIO_DEV${COLOR_END}"
if [[ "$INTERFACE" == "SPI" ]]; then
echo -e "${COLOR_INFO}SPI Speed:     $LORAGW_SPI_SPEED${COLOR_END}"
fi
echo -e "${COLOR_INFO}Has GPS:       $HAS_GPS${COLOR_END}"
if [[ $HAS_GPS -eq 1 ]]; then
echo -e "${COLOR_INFO}GPS Device:    $GPS_DEV${COLOR_END}"
fi
if [[ "$INTERFACE" == "SPI" ]]; then
echo -e "${COLOR_INFO}Reset GPIO:    $RESET_GPIO${COLOR_END}"
echo -e "${COLOR_INFO}Enable GPIO:   $POWER_EN_GPIO${COLOR_END}"
if [[ $POWER_EN_GPIO -ne 0 ]]; then
echo -e "${COLOR_INFO}Enable Logic:  $POWER_EN_LOGIC${COLOR_END}"
fi
fi
if [[ "$CHIP_ID" != "" ]]; then
echo -e "${COLOR_INFO}Chip ID:       $CHIP_ID${COLOR_END}"
fi
echo -e "${COLOR_INFO}Gateway EUI:   $GATEWAY_EUI${COLOR_END}"
echo -e "${COLOR_INFO}EUI Source:    $GATEWAY_EUI_SOURCE${COLOR_END}"
echo -e "${COLOR_INFO}Server:        $SERVER_HOST:$SERVER_PORT${COLOR_END}"
echo -e "${COLOR_INFO}Band:          $BAND${COLOR_END}"
echo -e "${COLOR_INFO}Use fake GPS:  $FAKE_GPS${COLOR_END}"
if [[ "$FAKE_GPS" == "true" ]]; then
echo -e "${COLOR_INFO}Latitude:      $GPS_LATITUDE${COLOR_END}"
echo -e "${COLOR_INFO}Longitude:     $GPS_LONGITUDE${COLOR_END}"
echo -e "${COLOR_INFO}Altitude:      $GPS_ALTITUDE${COLOR_END}"
fi 
if [[ -f ./global_conf.json ]]; then
echo -e "${COLOR_INFO}Custom global_conf.json found!${COLOR_END}"
fi

echo -e "${COLOR_INFO}------------------------------------------------------------------${COLOR_END}"

# -----------------------------------------------------------------------------
# Push variables to Balena
# -----------------------------------------------------------------------------

push_variables

# -----------------------------------------------------------------------------
# Prepare custom configuration
# -----------------------------------------------------------------------------

# Global configuration file
GLOBAL_CONFIG_FILE=global_conf.json
if [[ ! -f $GLOBAL_CONFIG_FILE ]]; then
    cp -f ./config/${CONCENTRATOR,,}/global_conf.$BAND.json $GLOBAL_CONFIG_FILE
    if [[ "$CONCENTRATOR" != "SX1280" ]]; then
        sed -i "s#\"com_type\":\s*.*,#\"com_type\": \"$INTERFACE\",#" $GLOBAL_CONFIG_FILE
        sed -i "s#\"com_path\":\s*.*,#\"com_path\": \"$RADIO_DEV\",#" $GLOBAL_CONFIG_FILE
        sed -i "s#\"gps_tty_path\":\s*.*,#\"gps_tty_path\": \"$GPS_DEV\",#" $GLOBAL_CONFIG_FILE
    else
        sed -i "s#\"tty_path\":\s*.*,#\"tty_path\": \"$RADIO_DEV\",#" $GLOBAL_CONFIG_FILE
        sed -i "s#\"gateway_ID\":\s*.*,#\"gateway_ID\": \"$GATEWAY_EUI\",#" $GLOBAL_CONFIG_FILE
        sed -i "s#\"server_address\":\s*.*,#\"server_address\": \"$SERVER_HOST\",#" $GLOBAL_CONFIG_FILE
        sed -i "s#\"serv_port_up\":\s*.*,#\"serv_port_up\": $SERVER_PORT,#" $GLOBAL_CONFIG_FILE
        sed -i "s#\"serv_port_down\":\s*.*,#\"serv_port_down\": $SERVER_PORT,#" $GLOBAL_CONFIG_FILE
    fi
fi

# Modify local configuration file
LOCAL_CONFIG_FILE=local_conf.json
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

# -----------------------------------------------------------------------------
# Start packet forwarder
# -----------------------------------------------------------------------------
./reset_lgw.sh
stdbuf -oL ./lora_pkt_fwd
