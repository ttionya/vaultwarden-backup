FROM rclone/rclone:1.67.0

LABEL "repository"="https://github.com/ttionya/vaultwarden-backup" \
  "homepage"="https://github.com/ttionya/vaultwarden-backup" \
  "maintainer"="ttionya <git@ttionya.com>"

ARG USER_NAME="backuptool"
ARG USER_ID="1100"

ENV LOCALTIME_FILE="/tmp/localtime"

COPY scripts/*.sh /app/

RUN chmod +x /app/*.sh \
  && mkdir -m 777 /bitwarden \
  && apk add --no-cache 7zip bash mariadb-client postgresql16-client sqlite supercronic s-nail tzdata \
  && apk info --no-cache -Lq mariadb-client | grep -vE '/bin/mariadb$' | grep -vE '/bin/mariadb-dump$' | xargs -I {} rm -f "/{}" \
  && ln -sf "${LOCALTIME_FILE}" /etc/localtime \
  && addgroup -g "${USER_ID}" "${USER_NAME}" \
  && adduser -u "${USER_ID}" -Ds /bin/sh -G "${USER_NAME}" "${USER_NAME}"

ENTRYPOINT ["/app/entrypoint.sh"]
