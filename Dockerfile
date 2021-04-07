FROM rclone/rclone:1.55.0

LABEL "repository"="https://github.com/ttionya/BitwardenRS-Backup" \
  "homepage"="https://github.com/ttionya/BitwardenRS-Backup" \
  "maintainer"="ttionya <git@ttionya.com>"

COPY scripts/*.sh /app/

RUN chmod +x /app/*.sh \
  && apk add --no-cache bash sqlite p7zip heirloom-mailx tzdata

ENTRYPOINT ["/app/entrypoint.sh"]
