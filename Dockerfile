# for linux/amd64 platform
FROM rclone/rclone:1.59.0 AS image-linux-amd64


# for linux/arm64 platform
FROM rclone/rclone:1.59.0 AS image-linux-arm64


# for linux/arm/v7 platform
FROM rclone/rclone:1.59.0 AS image-linux-armv7


# for linux/arm/v6 platform
FROM alpine:3.15 AS image-linux-armv6

RUN apk add --no-cache rclone


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
