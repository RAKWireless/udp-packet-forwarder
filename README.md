# LoRaWAN UDP Packet Forwarder Protocol for Docker

This project deploys a LoRaWAN gateway with UDP Packet Forwarder protocol using Docker. It runs on a Raspberry Pi 3/4, Compute Module 3/4 or balenaFin with SX1301, SX1302, SX1303 or SX1308 LoRa concentrators.


## Introduction

Deploy a LoRaWAN gateway running the UDP Packet Forwarder protocol in a docker container in your computer, Raspberry Pi or compatible SBC.

This project is based on rak-common-for-gateway project (https://github.com/RAKWireless/rak-common-for-gateway).

This project has been tested with The Things Stack Community Edition (TTSCE or TTNv3).


## Requirements


### Hardware

* Raspberry Pi 3/4 or Compute Module 3/4
* SD card in case of the RPi 3/4


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
  * RAK2246

Other concentrators might also work.

### Software

If you are going to use docker to deploy the project, you will need:

* An OS image for your board (Raspberry Pi OS, Ubuntu OS for ARM,...)
* Docker (and optionally docker-compose) on the machine (see below for instal·lation instructions)

On both cases you will also need:

* A The Things Stack V3 account [here](https://ttc.eu1.cloud.thethings.industries/console/)
* [balenaEtcher](https://balena.io/etcher) to burn the image on the SD


Once all of this is ready, you are able to deploy this repository following instructions below.


## Installing docker & docker-compose on the OS

If you are going to run this project you will need to install docker on the OS first. This is pretty staring forward, just follow these instructions:

```
sudo apt-get update && sudo apt-get upgrade -y
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker ${USER}
newgrp docker
sudo apt install -y python3 python3-dev python3-pip libffi-dev libssl-dev
sudo pip3 install docker-compose
sudo systemctl enable docker
```

Once done, you should be able to check the instalation is alright by testing:

```
docker --version
docker-compose --version
```


## Deploy the code

### Via docker-compose

You can use the `docker-compose.yml` file below to configure and run your instance of UDP Packet Forwarder:

```
version: '3.7'

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

### Build the image (not required)

In case you can not pull the already built image from Docker Hub or if you want to customize the cose, you can easily build the image by using the [buildx extension](https://docs.docker.com/buildx/working-with-buildx/) of docker and push it to your local repository by doing:

```
docker buildx bake --load aarch64
```

Once built (it will take some minutes) you can bring it up by using `rakwireless/udp-packet-forwarder:aarch64` as the image name in your `docker-compose.yml` file. If you are not in an ARMv8 64 bits machine (like a Raspberry Pi 4) you can change the `aarch64` with `armv7hf` (ARMv7) or `amd64`.

## Configure the Gateway

### Service Variables

These variables you can set them under the `environment` tag in the `docker-compose.yml` file or using an environment file (with the `env_file` tag). 

Variable Name | Value | Description | Default
------------ | ------------- | ------------- | -------------
**`MODEL`** | `STRING` | RAKwireless Developer gateway model or WisLink LPWAN module  | 
**`CONCENTRATOR`** | `STRING` | Semtech concentrator used (`SX1301`, `SX1302`, `SX1303` or `SX1308`) | If `MODEL` is defined it will get the concentrator from it
**`INTERFACE`** | `SPI` or `USB` | Concentrator interface | If `MODEL` is defined it will get the interface type from it, otherwise defaults to `SPI`
**`HAS_GPS`** | 0 or 1 | Set to 1 if the gateway has GPS | If `MODEL` is defined it will get this from it, otherwise defaults to 1 (with GPS)
**`HAS_LTE`** | 0 or 1 | Set to 1 if the gateway has LTE connectivity | If `MODEL` id defined it will get this from it, otherwise defaults to 0 (without LTE)
**`GW_RESET_GPIO`** | `INT` | GPIO number that resets (Broadcom pin number, if not defined, it's calculated based on the GW_RESET_PIN) | 17
**`GW_POWER_EN_GPIO`** | `INT` | GPIO number that enables power (by pulling HIGH) to the concentrator (Broadcom pin number). 0 means not required | 0
**`GATEWAY_EUI_NIC`** | `STRING` | Interface to use when generating the EUI | `eth0`
**`GATEWAY_EUI`** | `STRING` | Gateway EUI to use | Autogenerated from `GATEWAY_EUI_NIC` if defined or the any of these: `eth0`, `wlan0`, `usb0`
**`TTN_REGION`** | `STRING` | If using a TTN server, region of the TTN server to use | `eu1`
**`SERVER_HOST`** | `STRING` | URL of the server | If `TTN_REGION` is defined it will build the right address for the TTN server
**`SERVER_PORT`** | `INT` | Port the server is listening to | 1700
**`BAND`** | `STRING` | Regional parameters identifier | `eu_863_870`
**`GPS_LATITUDE`** | `DOUBLE` | Report this latitude for the gateway | 
**`GPS_LONGITUDE`** | `DOUBLE` | Report this longitude for the gateway | 
**`GPS_ALTITUDE`** | `DOUBLE` | Report this altitude for the gateway | 
**`EMAIL`** | `STRING` | Report this email as contact for the gateway | 
**`DESCRIPTION`** | `STRING` | Report this as description for the gateway | 

Notes: 

> At least `MODEL` or `CONCENTRATOR` must be defined.

> The list of supported modules is at the top of this page (either RAK Wisgate Developer model numbers or RAK WisLink modules). If your device is not in the list you can manually define `CONCENTRATOR`, `INTERFACE`, `HAS_GPS`, `HAS_LTE` and `GW_RESET_GPIO`.

> The service will generate a Gateway EUI based on an existing interface. It will try to find `eth0`, `wlan0` or `usb0`. If neither of these is available it will try to identify the most used existing interface. But this approach is not recommended, instead define a specific and unique custom `GATEWAY_EUI` or identify the interface you want the service to use to generate it by setting `GATEWAY_EUI_NIC`.

> The `BAND` can be one of these values: `as_915_921`, `as_915_928`, `as_917_920`, `as_920_923`, `au_915_928`, `cn_470_510`, `eu_433`, `eu_863_870`, `in_865_867`, `kr_920_923`, `ru_864_870`, and `us_902_928`.

> When using The Things Stack Community Edition the `SERVER_HOST` and `SERVER_PORT` values are automatically populated to use `udp://eu1.cloud.thethings.network:1700`. If your region is not EU you can set it using ```TTN_REGION```. At the moment only these regions are available: `eu1`, `nam1` and `au1`.


### Get the EUI of the LoRa Gateway

The LoRa gateways are manufactured with a unique 64 bits (8 bytes) identifier, called EUI, which can be used to register the gateway on the LoRaWAN Network Server. You can check the gateway EUI (and other data) by inspecting the service logs or running the command below while the container is up:

```
docker exec -it udp-packet-forwarder ./info.sh
```

### Register your gateway to The Things Stack

1. Sign up at [The Things Stack console](https://console.cloud.thethings.network/).
2. Click `Go to Gateways` icon.
3. Click the `Add gateway` button.
4. Introduce the data for the gateway (at least an ID, the EUI and the frequency plan).
6. Click `Create gateway`.


## Troubleshoothing

Feel free to introduce issues on this repo and contribute with solutions.
