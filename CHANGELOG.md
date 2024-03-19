# Changelog

## 2.4.3 (2024-03-19)

* Support for auto-discover for Picocell concentrators
* Auto-provision gateway for TTSv3 (TTN/TTI) and ChirpStackv4
* General clean up of the code

## 2.4.2 (2024-03-13)

* Option to filter uplinks and join requests using whitelists
* Fixed CLKSRC for USB SX1301 concentrators
* Fixed device argument for picocell concentrators

## 2.4.1 (2024-03-01)

* Fixed bug in SERVER_HOST setting
* Fixed `gateway_eui` script not retrieving EUI from configuration files first
* Catching errors in `reset` script

## 2.4.0 (2024-02-29)

* Refactor gateway_eui and find_concentrator utilities
* Auto-discover concentrator up-front if no MODEL defined
* Support to build address based on TTS tenant
* Better support for static configuration (breaking changes)
* Deprecation notice for `RADIO_DEV`, `GATEWAY_EUI_NIC` and `TTN_REGION`
* Support for remote concentrators via ser2net
* Support for MacOS (using ser2net)
* Fixed support for picocell concentrators (no up-front auto-discover)

## 2.3.0 (2024-02-05)

* Support for Raspberry Pi 5
* Document gpiod use, including chip selection

## 2.2.0 (2023-11-13)

* Image for armv6l architecture (#9)
* If HAS_GPS==0 do not try to connect to GPS (#11)
* Default value for HAS_GPS is now based on GPS_DEV

## 2.1.0 (2023-08-20)

* Added concentrator discovery feature
* Modified AS923 plans

## 2.0.0 (2023-06-05)

* Remove dependency with rak_common_for_gateway code
* Find concentrator utility

## 1.2.0 (2023-02-09)

* Changed default RADIO_DEV to /dev/ttyUSB0 when using USB interface

## 1.1.3 (2022-02-18)

* Option to set a different device port and speed for SX1301/8 SPI concentrators
* Prevent double resetting concentrator on SX1302/3

## 1.1.2 (2022-01-27)

* Fix concentrator reset
* Support for RAK833-USB/SPI module

## 1.1.1 (2022-01-24)

* Advanced configuration mode mounting custom `global_conf.json` file
 
## 1.1.0 (2022-01-24)

* Added RADIO_DEV and GPS_DEV so the user can specify non-default ports, this allows to have more than one concentrator on the same device
* Changed GW_RESET_GPIO and GW_POWER_EN_GPIO to RESET_GPIO and POWER_EN_GPIO
* Removed EMAIL and DESCRIPTION since these are not used by the code
* Applied patches to the rak_common_for_gateway code to avoid GPS warnings when DEBUG_GPS is 0
* Updated README.md file and also richer docker-compose.yml file

## 1.0.1 (2022-01-23)

* Support for ARMv6 processors (lke the Raspberry Pi Zero W)

## 1.0.0 (2022-01-22)

* Based on rak-common-for-gateway
* Compatible with SX1301, SX1302, SX1303 and SX1308 concentrators
* Docker image for armv7hf (32 bits) and aarch64 (64 bits) architectures
