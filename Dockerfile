FROM rclone/rclone:1.52.1

LABEL "repository"="https://github.com/ttionya/BitwardenRS-Backup" \
  "homepage"="https://github.com/ttionya/BitwardenRS-Backup" \
  "maintainer"="ttionya <git@ttionya.com>"

COPY scripts/*.sh /app/

RUN chmod +x /app/*.sh \
  && apk add --no-cache sqlite zip heirloom-mailx

ENTRYPOINT ["/app/entrypoint.sh"]
