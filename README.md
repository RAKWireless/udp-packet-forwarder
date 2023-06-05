# LoRaWAN UDP Packet Forwarder Protocol for Docker

This project deploys a LoRaWAN gateway with UDP Packet Forwarder protocol using Docker. It runs on any amd64/x86_64 PC, or a SBC like a Raspberry Pi 3/4, Compute Module 3/4 or balenaFin using SX1301, SX1302, SX1303 or SX1308 LoRa concentrators.


## Introduction

Deploy a LoRaWAN gateway running the UDP Packet Forwarder protocol in a docker container in your computer, Raspberry Pi or compatible SBC.

Main features:

* Support for AMD64 (x86_64), ARMv8, ARMv7 and ARMv6 architectures.
* Support for SX1301, SX1302, SX1303 and SX1308 concentrators.
* Support for SPI and USB concentrators.
* Compatible with The Things Stack (Comunity Edition / TTNv3) or Chirpstack LNS amongst others.
* Almost one click deploy and at the same time highly configurable.

This project is available on Docker Hub (https://hub.docker.com/r/rakwireless/udp-packet-forwarder) and GitHub (https://github.com/RAKWireless/udp-packet-forwarder).

This project has been tested with The Things Stack Community Edition (TTSCE or TTNv3).


## Requirements


### Hardware

As long as the host can run docker containers, the UDP Packet Forwarder service can run on:

* AMD64: most PCs out there
* ARMv8: Raspberry Pi 3/4, 400, Compute Module 3/4, Zero 2 W,...
* ARMv7: Raspberry Pi 2
* ARMv6: Raspberry Pi Zero, Zero W

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

> **NOTE**: This project focuses on RAKwireless products but products from other manufacturers should also work. You will have to provide the some information to configure them properly, like concentrator type, interface type, reset GPIO,...

> **NOTE**: SPI concentrators in MiniPCIe form factor will require a special Hat or adapter to connect them to the SPI interface in the SBC. USB concentrators in MiniPCIe form factor will require a USB adapter to connect them to a USB2/3 socket on the SBC. Other form factors might also require an adaptor for the target host.


### Software

You will need docker and docker-compose (optional but recommended) on the machine (see below for instal·lation instructions). You will also need a an account at a LoRaWAN Network Server, for instance a [The Things Stack V3 account](https://console.cloud.thethings.network/).

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

Once built (it will take some minutes) you can bring it up by using `rakwireless/udp-packet-forwarder:aarch64` as the image name in your `docker-compose.yml` file. If you are not in an ARMv8 64 bits machine (like a Raspberry Pi 4) you can change the `aarch64` with `arm` (ARMv6 and ARMv7) or `amd64`.


### Deploy with balena

[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/RAKWireless/udp-packet-forwarder/)

You need to set the variables upon deployment according to your installed concentrator / gateway. Example for a RAK 5146 USB installed on a RAK 2287 Pi Hat on a RPi 3:

````
INTERFACE: "USB"
HAS_GPS: "1"
HAS_LTE: "0"
RESET_GPIO: 0
RADIO_DEV: "/dev/ttyUSB0"
GPS_DEV: "/dev/ttyAMA0"
GATEWAY_EUI: "<YourGatewayEUI>"
TTN_REGION: "eu1"
BAND: "eu_863_870"
# leave the remaining variables as default
````

You can also set other variables like `GPS_LATITUDE`, `GPS_LONGITUDE` and `GPS_ALTITUDE` for fake GPS (in case HAS_GPS is 0 - please do not include these variables if your unit has a GPS, otherwise it will not use it).

For more details, read the `Service Variables` section below.

## Configure the Gateway

### Service Variables

These variables you can set them under the `environment` tag in the `docker-compose.yml` file or using an environment file (with the `env_file` tag). 

Variable Name | Value | Description | Default
------------ | ------------- | ------------- | -------------
**`MODEL`** | `STRING` | RAKwireless Developer gateway model or WisLink LPWAN module  | 
**`DESIGN`** | `STRING` | Reference design for the concentrator (`v2/native`, `v2/ftdi`, `corecell`, `2g4`, `picocell`) | Based on `MODEL`
**`INTERFACE`** | `SPI` or `USB` | Concentrator interface | If `MODEL` is defined it will get the interface type from it, otherwise defaults to `SPI`
**`HAS_GPS`** | 0 or 1 | Set to 1 if the gateway has GPS | If `MODEL` is defined it will get this from it, otherwise defaults to 1 (with GPS)
**`RADIO_DEV`** | `STRING` | Where the concentrator is connected to | `/dev/spidev0.0` for SPI concentrators, `/dev/ttyUSB0` or `/dev/ttyACM0` for USB concentrators
**`SPI_SPEED`** | `INT` | Speed of the SPI interface | 2000000 (2MHz) for SX1301/8 concentrators, 8000000 (8Mhz) for the rest
**`RESET_GPIO`** | `INT` | GPIO number that resets (Broadcom pin number) | 17
**`POWER_EN_GPIO`** | `INT` | GPIO number that enables power (by pulling HIGH) to the concentrator (Broadcom pin number). 0 means not required | 0
**`POWER_EN_LOGIC`** | `INT` | If `POWER_EN_GPIO` is not 0, the corresponding GPIO will be set to this value | 1
**`GPS_DEV`** | `STRING` | Where the GPS is connected to. Don't set it if you don't know what this means | `/dev/ttyAMA0` except when HAS_LTE is 1, in this case it will default to `/dev/i2c-1`
**`GATEWAY_EUI`** | `STRING` | Gateway EUI to use | Autogenerated from `GATEWAY_EUI_SOURCE` if defined, otherwise in order from: `eth0`, `wlan0`, `usb0`
**`GATEWAY_EUI_SOURCE`** | `STRING` | Interface to use when generating the EUI, set to `chip` for SX1302/3 and SX1280 chips to get the EUI from the radio chip | `eth0`
**`TTN_REGION`** | `STRING` | If using a TTN server, region of the TTN server to use | `eu1`
**`SERVER_HOST`** | `STRING` | URL of the server | If `TTN_REGION` is defined it will build the right address for the TTN server
**`SERVER_PORT`** | `INT` | Port the server is listening to | 1700
**`BAND`** | `STRING` | Regional parameters identifier | `eu_863_870`
**`GPS_LATITUDE`** | `DOUBLE` | Report this latitude for the gateway | 
**`GPS_LONGITUDE`** | `DOUBLE` | Report this longitude for the gateway | 
**`GPS_ALTITUDE`** | `DOUBLE` | Report this altitude for the gateway | 
**`GATEWAY_EUI_NIC`** | `STRING` | Deprecated, use GATEWAY_EUI_SOURCE instead |

Notes: 

> At least `MODEL` must be defined.

> The list of supported modules is at the top of this page (either RAK Wisgate Developer model numbers or RAK WisLink modules). If your device is not in the list you can manually define `CONCENTRATOR`, `INTERFACE`, `HAS_GPS`, `HAS_LTE` and `RESET_GPIO`.

> The service will generate a Gateway EUI based on an existing interface. It will try to find `eth0`, `wlan0` or `usb0`. If neither of these is available it will try to identify the most used existing interface. But this approach is not recommended, instead define a specific and unique custom `GATEWAY_EUI` or identify the interface you want the service to use to generate it by setting `GATEWAY_EUI_NIC`.

> The `BAND` can be one of these values: `as_915_921(as_923_3)`, `as_915_928(as_915_1)`, `as_917_920(as_923_4)`, `as_920_923(as_923_2)`, `au_915_928`, `cn_470_510`, `eu_433`, `eu_863_870`, `in_865_867`, `kr_920_923`, `ru_864_870`, and `us_902_928`.

> `SERVER_HOST` and `SERVER_PORT` values default to The Things Stack Community Edition european server (`udp://eu1.cloud.thethings.network:1700`). If your region is not EU you can change it using ```TTN_REGION```. At the moment only these regions are available: `eu1`, `nam1` and `au1`.

> If you have more than one concentrator on the same device, you will have to set different GATEWAY_EUI for each one and different `RADIO_DEV` values. Setting the `RADIO_DEV` only works with SX1302 and SX1303 concentrators. So you cannot use two SPI SX1301/SX1308 or two USB SX1301/SX1308 concentrators on the same device since they will both try to use the same port. But you can mix USB and SPI SX1301/SX1308 concentrators without problem. You can also provide a custom `global_conf.json` file to customize how every concentrator should behave. Check the `Use a custom radio configuration` section below.

### Find the concentrator

The service comes with an utility that tries to find existing concentrators connected to the device. It works with CoreCell, PicoCell and 2.4GHz concentrators.

You can run the tool (with the service shut down) by: 

```
docker run --privileged --rm rakwireless/udp-packet-forwarder ./find.sh
```

By default it will reset the concentrator using GPIO6 and GPIO17, if you know the reset pin is connected to any other GPIO(S) you can use the RESET_GPIO environment variable:

```
docker run --privileged --rm -e RESET_GPIO="12 13" rakwireless/udp-packet-forwarder ./find.sh
```

Finally, you can also limit the interfaces to scan by setting SCAN_USB or SCAN_SPI to 0, so this command below will only scan for SUB concentrators:

```
docker run --privileged --rm -e SCAN_SPI=0 rakwireless/udp-packet-forwarder ./find.sh
```

The output will be a list of concentrators with the port they are connected to and the EUI:

```
DEVICE             DESIGN             RESPONSE           
---------------------------------------------------------
/dev/ttyACM0       Corecell           0016C001FF1BA2BE 
```

### Get the EUI of the LoRa Gateway

LoRa gateways are manufactured with a unique 64 bits (8 bytes) identifier, called EUI, which can be used to register the gateway on the LoRaWAN Network Server. You can check the gateway EUI (and other data) by inspecting the service logs or running the command below while the container is up:

```
docker exec -it udp-packet-forwarder ./get_eui.sh
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
      - ./global_conf.json:/app/global_conf.json:ro
    environment:
      MODEL: "RAK7248"
```

Please note that a `local_conf.json` file will still be generated and will overwrite some of the settings in the `global_conf.json`, but only in the `gateway_conf` section.


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


### Register your gateway to The Things Stack

1. Sign up at [The Things Stack console](https://console.cloud.thethings.network/).
2. Click `Go to Gateways` icon.
3. Click the `Add gateway` button.
4. Introduce the data for the gateway (at least an ID, the EUI and the frequency plan).
6. Click `Create gateway`.


## Troubleshoothing

Feel free to introduce issues on this repo and contribute with solutions.
