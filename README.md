# LoRaWAN UDP Packet Forwarder Protocol for Docker

This project deploys a LoRaWAN gateway with UDP Packet Forwarder protocol using Docker. It runs on a Raspberry Pi 3/4, Compute Module 3/4 or balenaFin with SX1301, SX1302, SX1303 or SX1308 LoRa concentrators.


## Introduction

Deploy a LoRaWAN gateway running the UDP Packet Forwarder protocol in a docker container in your computer, Raspberry Pi or compatible SBC.

This project is based on rak_common_for_gateway project (https://github.com/RAKWireless/rak_common_for_gateway).

This project has been tested with The Things Stack Community Edition (TTSCE or TTNv3).


## Requirements


### Hardware

The UDP Packet Forwarder service can run on:

* AMD64: most PCs out there
* ARMv8: Raspberry Pi 3/4, 400, Compute Module 3/4, Zero 2 W,...
* ARVv7: Raspberry Pi 2
* ARMv6: Raspberry Pi Zero, Zero W


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

> **NOTE**: This project focuses on RAKwireless products but products from other manufacturers should also work. You will have to provide the some information to configure them properly, like concentrator type, interface type, reset GPIO,...

> **NOTE**: SPI concentrators in MiniPCIe form factor will require a special Hat or adapter to connect them to the SPI interface in the SBC. USB concentrators in MiniPCIe form factor will require a USB adapter to connect them to a USB2/3 socket on the SBC.


### Software

You will need docker and docker-compose (optional but recommended) on the machine (see below for instal·lation instructions). You will also need a an account at a LoRaWAN Network Server, for instance a [The Things Stack V3 account](https://console.cloud.thethings.network/).


## Installing docker & docker-compose on the OS

If you don't have docker running on the machine you will need to install docker on the OS first. This is pretty staring forward, just follow these instructions:

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

Once built (it will take some minutes) you can bring it up by using `rakwireless/udp-packet-forwarder:aarch64` as the image name in your `docker-compose.yml` file. If you are not in an ARMv8 64 bits machine (like a Raspberry Pi 4) you can change the `aarch64` with `arm` (ARMv6 and ARMv7) or `amd64`.

## Configure the Gateway

### Service Variables

These variables you can set them under the `environment` tag in the `docker-compose.yml` file or using an environment file (with the `env_file` tag). 

Variable Name | Value | Description | Default
------------ | ------------- | ------------- | -------------
**`MODEL`** | `STRING` | RAKwireless Developer gateway model or WisLink LPWAN module  | 
**`CONCENTRATOR`** | `STRING` | Semtech concentrator used (`SX1301`, `SX1302`, `SX1303` or `SX1308`) | If `MODEL` is defined it will get the concentrator from it
**`INTERFACE`** | `SPI` or `USB` | Concentrator interface | If `MODEL` is defined it will get the interface type from it, otherwise defaults to `SPI`
**`HAS_GPS`** | 0 or 1 | Set to 1 if the gateway has GPS | If `MODEL` is defined it will get this from it, otherwise defaults to 1 (with GPS)
**`HAS_LTE`** | 0 or 1 | Set to 1 if the gateway has LTE connectivity | If `MODEL` is defined it will get this from it, otherwise defaults to 0 (without LTE)
**`RESET_GPIO`** | `INT` | GPIO number that resets (Broadcom pin number) | 17
**`POWER_EN_GPIO`** | `INT` | GPIO number that enables power (by pulling HIGH) to the concentrator (Broadcom pin number). 0 means not required | 0
**`POWER_EN_LOGIC`** | `INT` | If `POWER_EN_GPIO` is not 0, the corresponding GPIO will be set to this value | 1
**`RADIO_DEV`** | `STRING` | Where the concentrator is connected to. Don't set it if you don't know what this means | `/dev/spidev0.0` for SPI concentrators, `/dev/ttyACM0` for USB concentrators
**`GPS_DEV`** | `STRING` | Where the GPS is connected to. Don't set it if you don't know what this means | `/dev/ttyAMA0` except when HAS_LTE is 1, in this case it will default to `/dev/i2c-1`
**`GATEWAY_EUI_NIC`** | `STRING` | Interface to use when generating the EUI | `eth0`
**`GATEWAY_EUI`** | `STRING` | Gateway EUI to use | Autogenerated from `GATEWAY_EUI_NIC` if defined, otherwise in order from: `eth0`, `wlan0`, `usb0`
**`TTN_REGION`** | `STRING` | If using a TTN server, region of the TTN server to use | `eu1`
**`SERVER_HOST`** | `STRING` | URL of the server | If `TTN_REGION` is defined it will build the right address for the TTN server
**`SERVER_PORT`** | `INT` | Port the server is listening to | 1700
**`BAND`** | `STRING` | Regional parameters identifier | `eu_863_870`
**`GPS_LATITUDE`** | `DOUBLE` | Report this latitude for the gateway | 
**`GPS_LONGITUDE`** | `DOUBLE` | Report this longitude for the gateway | 
**`GPS_ALTITUDE`** | `DOUBLE` | Report this altitude for the gateway | 

Notes: 

> At least `MODEL` or `CONCENTRATOR` must be defined.

> The list of supported modules is at the top of this page (either RAK Wisgate Developer model numbers or RAK WisLink modules). If your device is not in the list you can manually define `CONCENTRATOR`, `INTERFACE`, `HAS_GPS`, `HAS_LTE` and `RESET_GPIO`.

> The service will generate a Gateway EUI based on an existing interface. It will try to find `eth0`, `wlan0` or `usb0`. If neither of these is available it will try to identify the most used existing interface. But this approach is not recommended, instead define a specific and unique custom `GATEWAY_EUI` or identify the interface you want the service to use to generate it by setting `GATEWAY_EUI_NIC`.

> The `BAND` can be one of these values: `as_915_921`, `as_915_928`, `as_917_920`, `as_920_923`, `au_915_928`, `cn_470_510`, `eu_433`, `eu_863_870`, `in_865_867`, `kr_920_923`, `ru_864_870`, and `us_902_928`.

> `SERVER_HOST` and `SERVER_PORT` values default to The Things Stack Community Edition european server (`udp://eu1.cloud.thethings.network:1700`). If your region is not EU you can change it using ```TTN_REGION```. At the moment only these regions are available: `eu1`, `nam1` and `au1`.

> If you have more than one concentrator on the same device, you will have to set different GATEWAY_EUI for each one and different `RADIO_DEV` values. Setting the `RADIO_DEV` only works with SX1302 and SX1303 concentrators. So you cannot use two SPI SX1301/SX1308 or two USB SX1301/SX1308 concentrators on the same device since they will both try to use the same port. But you can mix USB and SPI SX1301/SX1308 concentrators without problem. You can also provide a custom `global_conf.json` file to customize how every concentrator should behave. Check the `Use a custom radio configuration` section below.


### Get the EUI of the LoRa Gateway

LoRa gateways are manufactured with a unique 64 bits (8 bytes) identifier, called EUI, which can be used to register the gateway on the LoRaWAN Network Server. You can check the gateway EUI (and other data) by inspecting the service logs or running the command below while the container is up:

```
docker exec -it udp-packet-forwarder ./info.sh
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

### Register your gateway to The Things Stack

1. Sign up at [The Things Stack console](https://console.cloud.thethings.network/).
2. Click `Go to Gateways` icon.
3. Click the `Add gateway` button.
4. Introduce the data for the gateway (at least an ID, the EUI and the frequency plan).
6. Click `Create gateway`.


## Troubleshoothing

Feel free to introduce issues on this repo and contribute with solutions.
