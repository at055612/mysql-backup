FROM alpine:3.8 as supercronic_download

ENV \
    SUPERCRONIC_VERSION="v0.1.6" \
    SUPERCRONIC_PACKAGE="supercronic-linux-amd64" \
    SUPERCRONIC_SHA1SUM="c3b78d342e5413ad39092fd3cfc083a85f5e2b75"

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/$SUPERCRONIC_VERSION/$SUPERCRONIC_PACKAGE

# install dependencies
RUN apk add --no-cache \
        ca-certificates \
        curl && \
        curl -fsSLO "$SUPERCRONIC_URL" && \
    echo "SUPERCRONIC_VERSION=${SUPERCRONIC_VERSION}" && \
    echo "SUPERCRONIC_PACKAGE=${SUPERCRONIC_PACKAGE}" && \
    echo "SUPERCRONIC_SHA1SUM=${SUPERCRONIC_SHA1SUM}" && \
# verify file hash
    echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC_PACKAGE}" | sha1sum -c - && \
    chmod +x "${SUPERCRONIC_PACKAGE}" && \
    mv "${SUPERCRONIC_PACKAGE}" supercronic && \
    echo "Done"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FROM alpine:3.8

# mysql backup image
MAINTAINER Avi Deitcher <https://github.com/deitch>

# run entrypoint script inside tini for better unix process handling, 
# see https://github.com/krallin/tini/issues/8
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint"]

# install the necessary client
RUN apk add --no-cache \
        bash \
        mysql-client \
        python3 \
        samba-client \
        shadow \
        tini && \
    touch /etc/samba/smb.conf && \
    pip3 install awscli && \
    groupadd -g 1005 appuser && \
    useradd -r -u 1005 -g appuser appuser

USER appuser

# install the entrypoint
COPY functions.sh /
COPY entrypoint /entrypoint
# Copy the supercronic binary
COPY --from=supercronic_download /supercronic /bin/

