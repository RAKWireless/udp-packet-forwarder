# Changelog

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
