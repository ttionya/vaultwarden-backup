FROM rclone/rclone:1.53.2

LABEL "repository"="https://github.com/karbon15/EteBase-Backup" \
  "homepage"="https://github.com/karbon15/EteBase-Backup" \
  "maintainer"="github.com/karbon15"

COPY scripts/*.sh /app/

RUN chmod +x /app/*.sh \
  && apk add --no-cache sqlite zip heirloom-mailx tzdata

ENTRYPOINT ["/app/entrypoint.sh"]
