FROM debian:buster-slim
LABEL maintainer="Andrew Fried <afried@deteque.com>"
ENV KNOT_VERSION 2.8.3

RUN apt-get clean \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		apt-transport-https \
		ca-certificates \
		lsb-release \
		locate \
		net-tools\
		procps \
		sipcalc \
		vim \
		wget \
	&& wget -O /etc/apt/trusted.gpg.d/knot-latest.gpg https://deb.knot-dns.cz/knot-latest/apt.gpg \
	&& echo "deb https://deb.knot-dns.cz/knot-latest/ buster main" > /etc/apt/sources.list.d/knot-latest.list \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		knot \
		knot-dnsutils

EXPOSE 53/tcp
EXPOSE 53/udp
VOLUME [ "/etc/knot" ]

CMD ["knotd","-c","/etc/knot/knot.conf"]
