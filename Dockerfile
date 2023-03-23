FROM debian:bullseye-slim
LABEL maintainer="Andrew Fried <afried@deteque.com>"
ENV KNOT_VERSION 3.2.5
ENV BUILD_DATE "2023-03-23"

RUN apt-get clean \
	&& apt-get update \
	&& apt-get -y dist-upgrade \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		apt-transport-https \
		ca-certificates \
		lsb-release \
		locate \
		net-tools\
		procps \
		rsync \
		sipcalc \
		tcpdump \
		vim \
		wget \
	&& wget -O /etc/apt/trusted.gpg.d/knot-latest.gpg https://deb.knot-dns.cz/apt.gpg \
	&& echo "deb https://deb.knot-dns.cz/knot-latest/ buster main" > /etc/apt/sources.list.d/knot-latest.list \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y knot knot-dnsutils \
	&& ldconfig \
	&& updatedb

COPY knot.conf /tmp/knot.conf.EXAMPLE
EXPOSE 53/tcp 53/udp
VOLUME [ "/etc/knot" ]
CMD ["knotd","-c","/etc/knot/knot.conf"]
