FROM alpine

COPY . /app
WORKDIR /app
RUN set -x \
  && apk update \
  && apk upgrade \
  # Add the packages
  && apk add --no-cache socat iproute2 bash \
  && rm -rf /usr/include \
  && rm -rf /var/cache/apk/* /usr/share/man /tmp/*

RUN chmod a+x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
