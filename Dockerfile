# for linux/amd64 platform
FROM rclone/rclone:1.59.1 AS image-linux-amd64


# for linux/arm64 platform
FROM rclone/rclone:1.59.1 AS image-linux-arm64


# for linux/arm/v7 platform
FROM rclone/rclone:1.59.1 AS image-linux-armv7


# for linux/arm/v6 platform
FROM alpine:3.15 AS image-linux-armv6

RUN apk add --no-cache ca-certificates fuse \
  && echo "user_allow_other" >> /etc/fuse.conf \
  && wget https://downloads.rclone.org/v1.59.1/rclone-v1.59.1-linux-arm.zip -O /rclone-linux-arm.zip \
  && unzip /rclone-linux-arm.zip -j -d /rclone-linux-arm \
  && cp /rclone-linux-arm/rclone /usr/local/bin/ \
  && rm -rf /rclone-linux-arm.zip /rclone-linux-arm \
  && rclone --help


# main
FROM image-${TARGETOS}-${TARGETARCH}${TARGETVARIANT}

LABEL "repository"="https://github.com/ttionya/vaultwarden-backup" \
  "homepage"="https://github.com/ttionya/vaultwarden-backup" \
  "maintainer"="ttionya <git@ttionya.com>"

ARG USER_NAME="backuptool"
ARG USER_ID="1100"

ENV LOCALTIME_FILE="/tmp/localtime"

COPY scripts/*.sh /app/

RUN chmod +x /app/*.sh \
  && mkdir -m 777 /bitwarden \
  && apk add --no-cache bash heirloom-mailx p7zip sqlite supercronic tzdata \
  && ln -sf "${LOCALTIME_FILE}" /etc/localtime \
  && addgroup -g "${USER_ID}" "${USER_NAME}" \
  && adduser -u "${USER_ID}" -Ds /bin/sh -G "${USER_NAME}" "${USER_NAME}"

ENTRYPOINT ["/app/entrypoint.sh"]
