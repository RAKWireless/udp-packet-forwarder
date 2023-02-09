ARG ARCH
ARG TAG
ARG BUILD_DATE

# Builder image
FROM balenalib/${ARCH}-debian:buster-build as builder
ARG ARCH

# Install required development packages
RUN install_packages libftdi-dev libusb-dev

# Switch to working directory for our app
WORKDIR /app

# Checkout and compile remote code
COPY ./builder/ ./
RUN chmod +x *.sh
RUN ARCH=${ARCH} ./build.sh

# Runner image
FROM balenalib/${ARCH}-debian:buster-run as runner
ARG ARCH
ARG TAG
ARG BUILD_DATE

# Image metadata
LABEL maintainer="RAKwireless"
LABEL authors="RAKwireless"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=${BUILD_DATE}
LABEL org.label-schema.name="UDP Packet Forwarder"
LABEL org.label-schema.description="LoRaWAN UDP Packet Forwarder"
LABEL org.label-schema.vcs-type="Git"
LABEL org.label-schema.vcs-url="https://github.com/RAKWireless/udp-packet-forwarder"
LABEL org.label-schema.vcs-ref=${TAG}
LABEL org.label-schema.arch=${ARCH}
LABEL org.label-schema.license="BSD License 2.0"

# Install required runtime packages
RUN install_packages jq vim libftdi1

# Switch to working directory for our app
WORKDIR /app

# Copy fles from builder and repo
COPY --from=builder /app/artifacts ./artifacts
COPY --from=builder /app/artifacts/v2/ftdi/99-libftdi.rules /etc/udev/rules.d/99-libftdi.rules
COPY --from=builder /usr/local/lib/libmpsse.so /usr/local/lib/libmpsse.so
COPY --from=builder /usr/local/lib/libmpsse.a /usr/local/lib/libmpsse.a
COPY --from=builder /usr/local/include/mpsse.h /usr/local/include/mpsse.h
COPY ./runner/ ./
RUN chmod +x *.sh

# Launch our binary on container startup.
CMD ["bash", "start.sh"]
