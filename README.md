# LoRaWAN UDP Packet Forwarder Protocol for Docker

This project deploys a LoRaWAN gateway with UDP Packet Forwarder protocol using Docker. It runs on any amd64/x86_64 PC, or a SBC like a Raspberry Pi 3/4, Compute Module 3/4 or balenaFin using SX1301, SX1302, SX1303 or SX1308 LoRa concentrators.

## Table of Contents

- [Introduction](#introduction)
- [Requirements](#requirements)
    - [Hardware](#hardware)
        - [LoRa Concentrators](#lora-concentrators)
    - [Software](#software)
- [Installing docker & docker-compose on the OS](#installing-docker--docker-compose-on-the-os)
- [Deploy the code](#deploy-the-code)
    - [Via docker-compose](#via-docker-compose)
    - [Build the image not required](#build-the-image-not-required)
    - [Deploy with balena](#deploy-with-balena)
- [Configure the Gateway](#configure-the-gateway)
    - [Service Variables](#service-variables)
    - [Auto-discover](#auto-discover)
    - [Raspberry Pi 5](#raspberry-pi-5)
    - [Find the concentrator](#find-the-concentrator)
    - [Get the EUI of the Gateway](#get-the-eui-of-the-gateway)
    - [Use a custom radio configuration](#use-a-custom-radio-configuration)
    - [Running with less privileges](#running-with-less-privileges)
    - [Whitelisting](#whitelisting)
    - [Auto-provision your gateway](#auto-provision-your-gateway)
        - [Auto-provision your gateway on TTN/TTI](#auto-provision-your-gateway-on-ttntti)
        - [Auto-provision your gateway on ChirpStack](#auto-provision-your-gateway-on-chirpstack)
    - [Connect to a concentrator remotely](#connect-to-a-concentrator-remotely)
- [Troubleshoothing](#troubleshoothing)


## Introduction

Deploy a LoRaWAN gateway running the UDP Packet Forwarder protocol in a docker container in your computer, Raspberry Pi or compatible SBC.

Main features:

* Support for AMD64 (x86_64), ARMv8, ARMv7 and ARMv6 architectures.
* Support for SX1301, SX1302, SX1303 and SX1308 concentrators.
* Support for 2.4GHz LoRa concentrators based on Semtech's reference design (SX1280).
* Support for SPI and USB concentrators.
* Auto-discover concentrator for Corecell, Picocell and 2g4 concentrators.
* Compatible with The Things Stack v3 or Chirpstack v4 LNS amongst others.
* Auto-provision gateway on TTSv3 and ChirpStackv4.
* Almost one click deploy with auto-provision and auto-discover features and at the same time highly configurable.

This project is available on Docker Hub (https://hub.docker.com/r/rakwireless/udp-packet-forwarder) and GitHub (https://github.com/RAKWireless/udp-packet-forwarder).

This project has been tested with The Things Stack Community Edition (TTSCE / TTNv3) and ChirpStack v4.


## Requirements

### Hardware

As long as the host can run docker containers, the UDP Packet Forwarder service can run on:

* AMD64: most PCs out there
* ARMv8: Raspberry Pi 3/4/5, 400, Compute Module 3/4, Zero 2 W,...
* ARMv7: Raspberry Pi 2,...
* ARMv6: Raspberry Pi 1, Zero W, Compute Module 1,...

> **NOTE**: you will need an OS in the host machine, for some SBC like a Raspberry Pi that means and SD card with an OS (like Rasperry Pi OS) flashed on it.


#### LoRa Concentrators

Supported RAK gateways:

* [RAK7243 & RAK7243C](https://store.rakwireless.com/collections/wisgate-developer/products/rak7243c-pilot-gateway)
* [RAK7244 & RAK7244C](https://store.rakwireless.com/collections/wisgate-developer/products/rak7244-lpwan-developer-gateway)
* [RAK7246 & RAK7246G](https://store.rakwireless.com/collections/wisgate-developer/products/rak7246-lpwan-developer-gateway)
* [RAK7248 & RAK7248C](https://store.rakwireless.com/collections/wisgate-developer/products/rak7248)
* [RAK7271 & RAK7371](https://store.rakwireless.com/collections/wisgate-developer/products/wisgate-developer-base)

Supported RAK LoRa concentrators:

* SX1301 
  * [RAK831](https://store.rakwireless.com/products/rak831-gateway-module)
  * [RAK833](https://store.rakwireless.com/products/rak833-gateway-module)
  * [RAK2245](https://store.rakwireless.com/products/rak2245-pi-hat)
  * [RAK2247](https://store.rakwireless.com/products/rak2247-lpwan-gateway-concentrator-module)
* SX1302
  * [RAK2287](https://store.rakwireless.com/products/rak2287-lpwan-gateway-concentrator-module)
* SX1303
  * [RAK5146](https://store.rakwireless.com/collections/wislink-lpwan/products/wislink-lpwan-concentrator-rak5146)
* SX1308
  * [RAK2287](https://store.rakwireless.com/products/rak2287-lpwan-gateway-concentrator-module)
  * RAK2246
* SX1280
  * [RAK5148](https://store.rakwireless.com/products/2-4-ghz-mini-pcie-concentrator-module-for-lora-based-on-sx1280-rak5148)

> **NOTE**: This project focuses on RAKwireless products but products from other manufacturers should also work. You will have to provide the some information to configure them properly, like concentrator type, interface type, reset GPIO,...

> **NOTE**: SPI concentrators in MiniPCIe form factor will require a special Hat or adapter to connect them to the SPI interface in the SBC. USB concentrators in MiniPCIe form factor will require a USB adapter to connect them to a USB2/3 socket on the SBC. Other form factors might also require an adaptor for the target host.


### Software

You will need docker and docker-compose (optional but recommended) on the machine (see below for instal·lation instructions). You will also need a an account at a LoRaWAN Network Server, for instance a [The Things Network account](https://console.cloud.thethings.network/).

> You can also deploy this using balenaCloud, check the `Deploy with balena` section below.


## Installing docker & docker-compose on the OS

If you don't have docker running on the machine you will need to install docker on the OS first. This is pretty straight forward, just follow these instructions:

```
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ${USER}
newgrp docker
sudo systemctl enable docker
```

Once done, you should be able to check the instalation is alright by testing:

```
docker --version
```

Note than on previous versions of docker, compose was a 3rd party utility you had to install manually (`sudo pip3 install docker-compose`).

## Deploy the code

### Via docker-compose

You can use the `docker-compose.yml` file below to configure and run your instance of UDP Packet Forwarder:

```
version: '2.0'

services:

  udp-packet-forwarder:
    image: rakwireless/udp-packet-forwarder:latest
    container_name: udp-packet-forwarder
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      MODEL: "RAK7248"
```

Modify the environment variables to match your setup (see the `Service Variables` section below). You will need to know the Gateway EUI to register it in your LoraWAN Network Server. Check the `Get the EUI of the LoRa Gateway` section below to know how. Otherwise, check the logs messages when the service starts to know the Gateway EUI to use.

Once you have it configured deploy the service via:

```
docker compose up
```

It will show you the service log as it boots and starts receiving packages. You can `Ctrl+C` to stop it. To run it in the background (once you check everything works OK) just do:

```
docker compose up -d
```

Since the `restart` property in the `docker-compose.yml` file is set to `unless-stopped` the machine will start the container every time it reboots. To stop the container just type (while in the same folder):

```
docker compose down
```

or

```
docker stop udp-packet-forwarder
```

### Build the image (not required)

In case you can not pull the already built image from Docker Hub or if you want to customize the cose, you can easily build the image by using the [buildx extension](https://docs.docker.com/buildx/working-with-buildx/) of docker and push it to your local repository by doing:

```
docker buildx bake --load aarch64
```

Once built (it will take some minutes) you can bring it up by using `xoseperez/udp-packet-forwarder:aarch64` as the image name in your `docker-compose.yml` file. If you are not in an ARMv8 64 bits machine (like a Raspberry Pi 4) you can change the `aarch64` with `armv7hf` (ARMv7), `armv6l` (ARMv6) or `amd64` (AMD64).

The included build script in the root folder can be user to build all architectures and (optionally) push the to a repository. The default repository is `https://hub.docker.com/r/rakwireless/udp-packet-forwarder` which you don't have permissions to push to (obviously), but you can easily push the images to your own repo by doing:

```
REGISTRY="registry.example.com/udp-packet-forwarder" ./build.sh --push
```




### Deploy with balena

[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/RAKWireless/udp-packet-forwarder/)

You need to set the variables upon deployment according to your installed concentrator / gateway. Example for a RAK 5146 USB installed on a RAK 2287 Pi Hat on a RPi 3:

````
INTERFACE: "USB"
HAS_LTE: "0"
RESET_GPIO: 0
DEVICE: "/dev/ttyUSB0"
GPS_DEV: "/dev/ttyAMA0"
GATEWAY_EUI: "<YourGatewayEUI>"
TTN_REGION: "eu1"
BAND: "eu_863_870"
# leave the remaining variables as default
````

You can also set other variables like `GPS_LATITUDE`, `GPS_LONGITUDE` and `GPS_ALTITUDE` for fake GPS.

For more details, read the `Service Variables` section below.

## Configure the Gateway

### Service Variables

These variables you can set them under the `environment` tag in the `docker-compose.yml` file or using an environment file (with the `env_file` tag). 

Variable Name | Value | Description | Default
------------ | ------------- | ------------- | -------------
**`MODEL`** | `STRING` | RAKwireless Developer gateway model or WisLink LPWAN module. Leave it empty or set it to 'AUTO' for auto-discover.  | 
**`DESIGN`** | `STRING` | Reference design for the concentrator (`v2/native`, `v2/ftdi`, `corecell`, `2g4`, `picocell`) | Based on `MODEL`
**`INTERFACE`** | `SPI`, `USB`, `NET` or `AUTO` | Concentrator interface. Set to `AUTO` to use with auto-discover feature. | If `MODEL` is defined it will get the interface type from it if possible, defaults to `AUTO` if the auto-discover feature is enabled or `SPI` otherwise.
**`DEVICE`** | `STRING` or `AUTO` | Where the concentrator is connected to. Set to `AUTO` for auto-discover. | `/dev/spidev0.0` for SPI concentrators, `/dev/ttyUSB0` or `/dev/ttyACM0` for USB concentrators, the host IP port 3333 for `NET` connections
**`SPI_SPEED`** | `INT` | Speed of the SPI interface | `2000000` (2MHz) for SX1301/8 concentrators, `8000000` (8Mhz) for the rest
**`USE_LIBGPIOD`** | `INT` | Use new gpiod library to access GPIO or old filesystem (sooon deprecated) | `0` (`1` for Raspberry Pi 5)
**`GPIO_CHIP`** | `STRING` | Chip ID to use with gpiod | `gpiochip0` (`gpiochip4` for Raspberry Pi 5)
**`RESET_GPIO`** | `INT` | GPIO number that resets (Broadcom pin number) | `17`
**`POWER_EN_GPIO`** | `INT` | GPIO number that enables power (by pulling HIGH) to the concentrator (Broadcom pin number). 0 means not required | `0`
**`POWER_EN_LOGIC`** | `INT` | If `POWER_EN_GPIO` is not 0, the corresponding GPIO will be set to this value | `1`
**`GATEWAY_EUI_SOURCE`** | `STRING` | Interface to use when generating the EUI, set to `chip` for SX1302/3/8 and SX1280 chips to get the EUI from the radio chip | `eth0`
**`GATEWAY_EUI`** | `STRING` | Gateway EUI to use | Autogenerated from `GATEWAY_EUI_SOURCE` if defined, otherwise in order from: `eth0`, `wlan0`, `usb0`
**`RADIO_NUM`** | `INT` | When using auto-discover feature, select the N-th concentrator found | `1`
**`TTS_REGION`** | `STRING` | Region of the TTNv3 server to use | `eu1`
**`TTS_TENANT`** | `STRING` | Tenant you are using (only if using TTI) | `ttn`
**`SERVER_HOST`** | `STRING` | URL of the server | Based on `TTS_REGION` and `TTS_TENANT`
**`SERVER_PORT`** | `INT` | Port the server is listening to | `1700`
**`BAND`** | `STRING` | Regional parameters identifier | `eu_863_870`
**`HAS_GPS`** | 0 or 1 | Set to 0 to disable onbard GPS | `0`, if `GPS_DEV` is defined and exists it will be set to `1` by default
**`GPS_DEV`** | `STRING` | Where the GPS is connected to. Don't set it if you don't know what this means | `/dev/ttyAMA0` or `/dev/i2c-1` for known models
**`GPS_LATITUDE`** | `DOUBLE` | Report this latitude for the gateway | 
**`GPS_LONGITUDE`** | `DOUBLE` | Report this longitude for the gateway | 
**`GPS_ALTITUDE`** | `DOUBLE` | Report this altitude for the gateway | 
**`WHITELIST_NETIDS`** | `STRING` | List of NetIDs to whitelist, filters uplinks | *empty*
**`WHITELIST_OUIS`** | `STRING` | List of OUIs to whitelist, filters join requests | *empty*
**`GATEWAY_PREFIX`** | `STRING` | Prefix to autogenerate GATEWAY_ID for TTS/TTI/TTN auto-provision | `eui`
**`GATEWAY_ID`** | `STRING` | ID to use when auto-provisioning the gateway on TTS/TTI/TTN | `GATEWAY_PREFIX` + `-` + `GATEWAY_EUI`
**`GATEWAY_NAME`** | `STRING` | Name to use when auto-provisioning the gateway on TTS/TTI/TTN | `GATEWAY_ID`
**`TTS_USERNAME`** | `STRING` | Name of your user on the TTS instance you want to register the gateway | Paste your username
**`TTS_PERSONAL_KEY`** | `STRING` | Unique key to create the gateway and its key | Paste personal API key from your TTS instance (check section about auto-provision below)
**`TTS_FREQUENCY_PLAN_ID`** | `STRING` | The Things Stack frequency plan (https://www.thethingsindustries.com/docs/reference/frequency-plans/) | "EU_863_870_TTN"
**`CS_API_URL`** | `STRING` | ChripStack REST API URL | `http://<SERVER_HOST>:8090`
**`CS_TENANT_ID`** | `STRING` | ChirpStack tenant UID to register the gateway | *empty*
**`CS_TOKEN`** | `STRING` | ChirpStack API key with permissions to create a gateway on the tenant above | *empty*
**`TTN_REGION`** | **Deprecated** | Use TTS_REGION instead |
**`GATEWAY_EUI_NIC`** | **Deprecated** | Use GATEWAY_EUI_SOURCE instead |
**`RADIO_DEV`** | **Deprecated** | Use DEVICE instead |

Notes: 

> No setting is mandatory but `MODEL` and `DEVICE` are recommended for better performance. The service can auto-discover the concentrator but this feature takes some time on boot to walk through all the possible devices, designs and interfaces. Mind that not all concentrator types support auto-discover, defining a `MODEL` and `DEVICE` is mandatory for SX1301-concentrators.

> The list of supported modules is at the top of this page (either RAK Wisgate Developer model numbers or RAK WisLink modules). If your device is not in the list you can manually define `DESIGN`, `INTERFACE`, `GPS_DEV`, `HAS_LTE` and `RESET_GPIO`.

> The service will generate a Gateway EUI based on an existing interface if none provided. It will try to find `eth0`, `wlan0` or `usb0`. If neither of these is available it will try to identify the most used existing interface. But this approach is not recommended, instead define a specific and unique custom `GATEWAY_EUI` or identify the method you want the service to use to generate it by setting `GATEWAY_EUI_SOURCE`.

> The `BAND` can be one of these values: `as_915_921(as_923_3)`, `as_915_928(as_915_1)`, `as_917_920(as_923_4)`, `as_920_923(as_923_2)`, `au_915_928`, `cn_470_510`, `eu_433`, `eu_863_870`, `in_865_867`, `kr_920_923`, `ru_864_870`, and `us_902_928`.

> `SERVER_HOST` and `SERVER_PORT` values default to The Things Stack Community Edition european server (`udp://eu1.cloud.thethings.network:1700`). If your region is not EU you can change it using `TTN_REGION`. At the moment only these regions are available: `eu1`, `nam1` and `au1`.

> If you have more than one concentrator on the same device, you will have to set different GATEWAY_EUI for each one and different `DEVICE` values. Setting the `DEVICE` only works with SX1302 and SX1303 concentrators. So you cannot use two SPI SX1301/SX1308 or two USB SX1301/SX1308 concentrators on the same device since they will both try to use the same port. But you can mix USB and SPI SX1301/SX1308 concentrators without problem. You can also provide a custom `global_conf.json` file to customize how every concentrator should behave. Check the `Use a custom radio configuration` section below.

### Auto-discover

The auto-discover feature is capable of finding connected concentrators to SPI and USB ports as long as they are Corecell, Picocell or 2g4 ones (SX1302, SX1303, SX1308 and SX1280-based). 

This feature walks the corresponding interfaces until it finds the required concentrator and then resets the `DEVICE` and `INTERFACE` variables accordingly. Doing so takes some time on boot (up to 3 seconds for each device it checks), if you want to speed up the boot process you can set the `DEVICE` explicitly after looking for it with the `find_concentrator` utility (see `Find the concentrator` section below).

Auto-discovery is triggered in different situations:

* No `MODEL` defined or set to `AUTO`: It will search for a concentrator on all interfaces. Interfaces to check can be narrow by using the `INTERFACE` setting. Also the concentrator type to search for can be specified using the `DESIGN` setting (`corecell`, `picocell` or `2g4` are supported).
* `MODEL` defined but no `DEVICE` or set to `AUTO`:  It will search for the specific concentrator type (based on `MODEL`) on all interfaces. Interfaces to check can be narrow by using the `INTERFACE` setting. 

The following example will start a Corecell concentrator (RAK5146 is based on SX1303) on whatever first interface it finds it (SPI or USB).

```
version: '2.0'

services:

  udp-packet-forwarder:
    image: rakwireless/udp-packet-forwarder:latest
    container_name: udp-packet-forwarder
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      MODEL: "RAK5146"
```

### Raspberry Pi 5

The new Raspberry Pi 5 requires using the `gpiod` library to access the GPIO to reset SPI concentrators. The service automatically detects the Raspberry Pi 5 and sets these default like in the example below, but you can still override them:

```
version: '2.0'

services:

  udp-packet-forwarder:
    image: rakwireless/udp-packet-forwarder:latest
    container_name: udp-packet-forwarder
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      MODEL: "RAK5146"
      USE_LIBGPIOD: 1
      GPIO_CHIP: "gpiochip4"
```

### Find the concentrator

The service comes with an utility that tries to find existing concentrators connected to the device. It works with CoreCell, PicoCell and 2.4GHz concentrators.

You can run the tool (with the service shut down) by: 

```
docker run --privileged --rm rakwireless/udp-packet-forwarder find_concentrator
```

You can also run it from a docker-compose.yml file folder:

```
docker compose run udp-packet-forwarder find_concentrator
```

By default it will reset the concentrator using GPIO6 and GPIO17, if you know the reset pin is connected to any other GPIO(S) you can use the RESET_GPIO environment variable:

```
docker run --privileged --rm -e RESET_GPIO="12 13" rakwireless/udp-packet-forwarder find_concentrator
```

Finally, you can also limit the interfaces to scan by setting SCAN_USB or SCAN_SPI to 0, so this command below will only scan for USB concentrators:

```
docker run --privileged --rm -e SCAN_SPI=0 rakwireless/udp-packet-forwarder find_concentrator
```

The output will be a list of concentrators with the port they are connected to and the EUI:

```
Looking for devices, this might take some time...

DEVICE            DESIGN      ID            
--------------------------------------------------
/dev/spidev0.0    corecell    0016C001FFXXXXXX
/dev/ttyUSB0      2g4         54112205FFXXXXXX
/dev/ttyACM0      corecell    0016C001FFXXXXXX 
/dev/ttyACM1      picocell    5031395343XXXXXX    

4 device(s) found!
```

### Get the EUI of the Gateway

LoRaWAN gateways are identified with a unique 64 bits (8 bytes) number, called EUI, which can be used to register the gateway on the LoRaWAN Network Server. You can check the gateway EUI (and other data) by inspecting the service logs or running the command below while the container is up (`--network host` is required to get the EUI from the host's NICs):

```
docker run -it --network host --rm rakwireless/udp-packet-forwarder gateway_eui
```

You can do so before bringing up the service, so you first get the EUI, register the gateway and get the KEY to populate it on the `docker-compose.yml` file. If you are specifying a different source to create the EUI from (see the GATEWAY_EUI_SOURCE variable above), you can do it like this:

```
docker run -it --network host --rm -e GATEWAY_EUI_SOURCE=wlan0 rakwireless/udp-packet-forwarder:latest gateway_eui
```

Or query what will the EUI be using the chip ID (only for Corecell concentrators), here with `--privileged` to have access to host's devices:

```
docker run -it --privileged --rm -e GATEWAY_EUI_SOURCE=chip rakwireless/udp-packet-forwarder:latest gateway_eui
```

If using balenaCloud the ```EUI``` will be visible as a TAG on the device dashboard. Be careful when you copy the tag, as other characters will be copied.

The output will one or more possible EUIs (if using `GATEWAY_EUI_SOURCE=chip` with more than once concentrator plugged-in):

```
Gateway EUI: 8045DDFFFE010203 (based on interface wlp2s0)
```


### Use a custom radio configuration

In some special cases you might want to specify the radio configuration in detail (frequencies, power, ...). You can do that by providing a custom `global_conf.json` file. You can start by copying the default one based on your current configuration from a running instance of the service:

```
docker cp udp-packet-forwarder:/opt/ttn-gateway/packet_forwarder/lora_pkt_fwd/global_conf.json global_conf.json
```

Now you can modify it to match your needs. And finally define it as a mounted file in your `docker-compose.yml` file. When you do a `docker-compose up -d` it will use your custom file instead of a generated one.

```
version: '3.7'

services:

  udp-packet-forwarder:
    image: rakwireless/udp-packet-forwarder:latest
    container_name: udp-packet-forwarder
    restart: unless-stopped
    privileged: true
    network_mode: host
    volumes:
      - ./config:/app/config
    environment:
      MODEL: "RAK7248"
```

Please note that a `local_conf.json` file will still be generated inside the `config` folder and will overwrite some of the settings in the `global_conf.json`, but only in the `gateway_conf` section.


### Running with less privileges

You might have seen that on the examples above we are running docker in privileged mode and using host network. This is the simplest, more straight-forward way, but there are ways to run it without these. Let's see how.

On one side, the host network is required to access the MAC of the host interface instead of that of the virtual interface. This MAC is used to create the Gateway EUI. The virtual MAC changes everytime the container is created, so we need to access the physical interface because that one does not change. But if you set the Gateway EUI manually, using the `GATEWAY_EUI` variable, then this is not needed anymore.

On the other side privileged mode is required to access the port where the concentrator is listening to (either SPI or USB) and the GPIOs to reset the concentrator for SPI modules. You can get rid of these too by mounting the right device in the container and also the `/sys` root so the container can reset the concentrator.

Therefore, an example of this workaround for an SPI concentrator would be:

```
version: '2.0'

services:

  udp-packet-forwarder:
    image: rakwireless/udp-packet-forwarder:latest
    container_name: udp-packet-forwarder
    restart: unless-stopped
    devices:
      - /dev/spidev0.0
    volumes:
      - /sys:/sys
    environment:
      MODEL: "RAK5146"
      GATEWAY_EUI: "E45F01FFFE517BA8"
```

For a USB concentrator you would mount the USB port instead of the SPI port and you won't need to mount the `/sys` volume, but remember to set `RESET_GPIO` to 0 to avoid unwanted errors in the logs.

### Whitelisting

From version 2.4.2, the service supports message filtering via white lists. There are two whitelists: by NetID and by OUI.

To filter only devices belonging to your network you can add the NetID of your LNS to the `WHITELIST_NETIDS` setting. More than one NetID can be added (comman or space separated). They can also be added in decimal (TTN is 19) or hexadecimal with leading `0x` (TTN is 0x000013). If `WHITELIST_NETIDS` is nt set or empty, no filtering happens. 

The example below filters out all messages from devices not belonging to TTN/TTI:

```
version: '2.0'

services:

  udp-packet-forwarder:
    image: rakwireless/udp-packet-forwarder:latest
    container_name: udp-packet-forwarder
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      MODEL: "RAK5146"
      GATEWAY_EUI: "E45F01FFFE517BA8"
      WHITELIST_NETIDS: "0x000013"
```

The NetID is identified by the device address (devAdrr). But if the device has not yet joined the network it does not have a DevAddr. If you want to filter join requests from unknown devices you can do so filtering by OUI. OUI, or Organizational Unique Identifier, are the first 3 bytes of the DevEUI and identfies the manufacturer. To accept join requests from certain devices you can add the OUI of their manufacturer to the `WHITELIST_OUIS` variable like in the eample below:

```
version: '2.0'

services:

  udp-packet-forwarder:
    image: rakwireless/udp-packet-forwarder:latest
    container_name: udp-packet-forwarder
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      MODEL: "RAK5146"
      GATEWAY_EUI: "E45F01FFFE517BA8"
      WHITELIST_OUIS: "0xA81758"
```

### Auto-provision your gateway

The service lets you auto-provision your gateway on the first boot agains a TTS (The Things Network / The Things Industries) server or a ChirpStack server.

The are some common variables for these options: `GATEWAY_PREFIX`, `GATEWAY_ID`, `GATEWAY_NAME`. These are not mandatory and if not defined the service will choose some sensible defaults.

#### Auto-provision your gateway on TTN/TTI

To configure auto-provisioning using the TTS API, `TTS_USERNAME` and `TTS_PERSONAL_KEY` are mandatory and `TTS_FREQUENCY_PLAN_ID` is optional.

`TTS_PERSONAL_KEY` should be a key with, at least, the following permissions:
* link as Gateway to a Gateway Server for traffic exchange, i.e. write uplink and read downlink
* view and edit gateway API keys
* edit basic gateway settings
* create a gateway under the user account

Remember that when using TTN the `GATEWAY_NAME` and `GATEWAY_ID` must be unique over time (including deleted gateways). 

An example `docker-compose.yml` file to autodiscover and auto-provision a gateway to the european server of TTN (that's the default) would be:
```
version: '2.0'

services:

  udp-packet-forwarder:
    image: rakwireless/udp-packet-forwarder:latest
    container_name: udp-packet-forwarder
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      TTS_USERNAME: "xoseperez" # use here your TTN user name
      TTS_PERSONAL_KEY: "NNSXS.E2CK53N....." # use here a personal key with the required permissions
```

You might want to change the `TTS_REGION` if not using the european server, set `TTS_TENANT` if using a The Things Clound instance or `SERVER` if using a on-premise instance of The Things Stack.

#### Auto-provision your gateway on ChirpStack

To configure auto-provisioning using the ChirpStack REST API `CS_TENANT_ID` and `CS_TOKEN` are mandatory and `CS_API_URL` is optional (will default to `http://<SERVER_HOST>:8089`).

`CS_TOKEN` should be a API key created by tenant `CS_TENANT_ID` or and admin. Remember that `GATEWAY_EUI` are unique, the service will show a warning if the gateway already exists on the same ChirpStack instance. 

An example `docker-compose.yml` file to autodiscover and auto-provision a gateway to a local ChirpStack LNS at IP 192.168.200.15 would be:
```
version: '2.0'

services:

  udp-packet-forwarder:
    image: rakwireless/udp-packet-forwarder:latest
    container_name: udp-packet-forwarder
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      SERVER_HOST: 192.168.200.15
      CS_TENANT_ID: "6849ca56-aa22-4025-cc65-be6961131589"
      CS_TOKEN: "eyJ0eXAiO..."
```


### Connect to a concentrator remotely

From version 2.4.0, you have the option to connect to a remote concentrator via a TCP link. This is useful to use the service with MacOS since Docker Desktop for MacOS does not let you passthrough USB devices. Therefore you can bypass the USB device as a TCP connection using `ser2net` and mount it back as a UART device inside the container.

First step is to stream the USB device as a TCP connection using `ser2net`. An example configuration file is provided but you will have to change the port of your USB device accordingly:

```
connection: &con3333
    accepter: tcp,0.0.0.0,3333
    enable: on
    options:
      kickolduser: true
    connector: serialdev,
              /dev/ttyACM0,
              115200n81,local
```

In the example above (`ser2net.yaml` file provided with this repo) port `/dev/ttyACM0` is mapped to `0.0.0.0:3333` using 115200bps, 8N1. 

**Attention: any machine with network access to port 3333 will be able to access the USB device, ser2net does not provide any security features. A more secure approach would be to link the service to your host docker IP.**

You can run it as `ser2net -c ser2net.yaml`. 

Once the USB device is available as a TCP stream, we can instruct the UDP Packet Forwarder to use this connection. An example `docker-compose.yml` file can be as follows:

```
version: '2.0'

services:

  udp-packet-forwarder:
    image: rakwireless/udp-packet-forwarder:latest
    container_name: udp-packet-forwarder
    restart: unless-stopped
    environment:
      MODEL: "RAK5146"
      INTERFACE: "NET"
      GATEWAY_EUI: "E45F01FFFE517BA8"
```

When the service boots you will see the information about the network device being used in the summary:

```
udp-packet-forwarder  | ------------------------------------------------------------------
udp-packet-forwarder  | UDP Packet Forwarder Container v2.4.0
udp-packet-forwarder  | (c) RAKwireless 2022-2024
udp-packet-forwarder  | 
udp-packet-forwarder  | Based on:
udp-packet-forwarder  |  * lora_gateway v5.0.1
udp-packet-forwarder  |  * packet_forwarder v4.0.1
udp-packet-forwarder  |  * sx1302_hal v2.1.0
udp-packet-forwarder  |  * picoGW_hal v0.2.3
udp-packet-forwarder  |  * picoGW_packet_forwarder v0.1.0
udp-packet-forwarder  |  * gateway_2g4_hal v1.1.0
udp-packet-forwarder  | ------------------------------------------------------------------
udp-packet-forwarder  | 
udp-packet-forwarder  | Protocol
udp-packet-forwarder  | ------------------------------------------------------------------
udp-packet-forwarder  | Mode:          DYNAMIC
udp-packet-forwarder  | Protocol:      UDP
udp-packet-forwarder  | Server:        eu1.cloud.thethings.network:1700
udp-packet-forwarder  | Band:          eu_863_870
udp-packet-forwarder  | Gateway EUI:   E45F01FFFE517BA8
udp-packet-forwarder  | EUI Source:    manual
udp-packet-forwarder  | 
udp-packet-forwarder  | Radio
udp-packet-forwarder  | ------------------------------------------------------------------
udp-packet-forwarder  | Model:         RAK5146
udp-packet-forwarder  | Concentrator:  SX1303
udp-packet-forwarder  | Design:        CORECELL
udp-packet-forwarder  | Network link:  172.26.0.1:3333
udp-packet-forwarder  | Interface:     USB
udp-packet-forwarder  | Radio Device:  /dev/ttyV0
udp-packet-forwarder  | 
udp-packet-forwarder  | Extra
udp-packet-forwarder  | ------------------------------------------------------------------
udp-packet-forwarder  | Use fake GPS:  TRUE
udp-packet-forwarder  | Latitude:      0
udp-packet-forwarder  | Longitude:     0
udp-packet-forwarder  | Altitude:      0
```

By default it will try to reach port 3333/tcp at the host. You can also specify a different connection in the `DEVICE` variable:

```
version: '2.0'

services:

  udp-packet-forwarder:
    image: rakwireless/udp-packet-forwarder:latest
    container_name: udp-packet-forwarder
    restart: unless-stopped
    environment:
      MODEL: "RAK5146"
      INTERFACE: "NET"
      DEVICE: "192.168.0.150:4321"
      GATEWAY_EUI: "E45F01FFFE517BA8"
```

## Troubleshoothing

Feel free to introduce issues on this repo and contribute with solutions.
