ARG VPP_VERSION=v23.10-rc0-170-g806b14eeb
FROM ghcr.io/networkservicemesh/govpp/vpp:${VPP_VERSION} as runtime
COPY vpp.conf /etc/vpp1/vpp.conf
RUN mkdir -p /var/run/vpp/external
ENTRYPOINT [ "vpp", "-c", "/etc/vpp1/vpp.conf" ]