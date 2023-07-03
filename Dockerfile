FROM alpine:latest AS builder

ARG S_NAIL_VERSION="14.9.24"
ARG S_NAIL_NAME="s-nail-${S_NAIL_VERSION}"
ARG DEST_DIR="/build/dest"
ARG BIN_NAME="mail"

WORKDIR /build/

RUN apk --no-cache add curl gcc g++ libidn2-dev make ncurses-dev openssl openssl-dev \
  && wget "https://ftp.sdaoden.eu/${S_NAIL_NAME}.tar.xz" \
  && tar -Jxvf "${S_NAIL_NAME}.tar.xz" \
  && cd "${S_NAIL_NAME}" \
  && make VAL_SID= VAL_MAILX="${BIN_NAME}" VAL_PREFIX=/usr VAL_SYSCONFDIR=/etc OPT_GSSAPI=no VAL_IDNA=idn2 VAL_RANDOM="tls,libgetrandom,urandom,builtin" VAL_MAIL=/var/mail config \
  && make build \
  && make test \
  && make DESTDIR="${DEST_DIR}" install \
  && ls -l "${DEST_DIR}" \
  && "${DEST_DIR}/usr/bin/${BIN_NAME}" --version


FROM rclone/rclone:1.63.0

LABEL "repository"="https://github.com/ttionya/vaultwarden-backup" \
  "homepage"="https://github.com/ttionya/vaultwarden-backup" \
  "maintainer"="ttionya <git@ttionya.com>"

ARG USER_NAME="backuptool"
ARG USER_ID="1100"

ENV LOCALTIME_FILE="/tmp/localtime"

COPY scripts/*.sh /app/
COPY --from=builder /build/dest /

RUN chmod +x /app/*.sh \
  && mkdir -m 777 /bitwarden \
  && apk add --no-cache 7zip bash libcrypto3 libidn2 libncursesw libssl3 mariadb-client musl postgresql15-client sqlite supercronic tzdata \
  && apk info --no-cache -Lq mariadb-client | grep -vE '/bin/mariadb$' | grep -vE '/bin/mariadb-dump$' | xargs -I {} rm -f "/{}" \
  && ln -sf "${LOCALTIME_FILE}" /etc/localtime \
  && addgroup -g "${USER_ID}" "${USER_NAME}" \
  && adduser -u "${USER_ID}" -Ds /bin/sh -G "${USER_NAME}" "${USER_NAME}"

ENTRYPOINT ["/app/entrypoint.sh"]
