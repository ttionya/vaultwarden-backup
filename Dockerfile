FROM rclone/rclone:1.58.1

LABEL "repository"="https://github.com/ttionya/vaultwarden-backup" \
  "homepage"="https://github.com/ttionya/vaultwarden-backup" \
  "maintainer"="ttionya <git@ttionya.com>"

COPY scripts/*.sh /app/

RUN chmod +x /app/*.sh \
  && apk add --no-cache bash heirloom-mailx p7zip sqlite supercronic tzdata \
  && ln -sf /tmp/localtime /etc/localtime \
  && mkdir -m 777 /bitwarden \
  && addgroup -g 1100 backuptool \
  && adduser -u 1100 -Ds /bin/sh -G backuptool backuptool

ENTRYPOINT ["/app/entrypoint.sh"]
