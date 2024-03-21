FROM debian:bookworm-slim as download

ARG PIVX_VERSION

ARG GPGKEY=0xC1ABA64407731FD9

ARG PIVX_URL_PREFIX=https://github.com/PIVX-Project/PIVX/releases/download/v${PIVX_VERSION}
ARG PIVX_FILENAME=pivx-${PIVX_VERSION}-x86_64-linux-gnu.tar.gz
ARG PIVX_TAR_URL=${PIVX_URL_PREFIX}/${PIVX_FILENAME}
ARG PIVX_ASC_URL=${PIVX_URL_PREFIX}/SHA256SUMS.asc

RUN set -ex \
  && apt-get -q update \
  && apt-get -yq install gpg gpg-agent wget ca-certificates \
  && \
  for server in \
    keyserver.ubuntu.com \
    pgp.mit.edu; do \
      gpg --keyserver "$server" \
          --recv-keys "$GPGKEY" \
          && break; \
  done \
  && cd /tmp \
  && wget --progress=dot:mega $PIVX_TAR_URL \
  && wget --progress=dot:mega $PIVX_ASC_URL \
  && gpg --yes --decrypt --output SHA256SUMS SHA256SUMS.asc \
  && fgrep $PIVX_FILENAME SHA256SUMS | sha256sum -c \
  && mkdir -p /opt \
  && cd /opt \
  && tar xvzf /tmp/$PIVX_FILENAME \
  && rm /tmp/$PIVX_FILENAME \
  && ln -sf pivx-$PIVX_VERSION pivx \
  && cd /opt/pivx \
  && ./install-params.sh /opt/pivx/params \
  && rm /opt/pivx/bin/pivx-qt /opt/pivx/bin/test_pivx /opt/pivx/install-params.sh

FROM debian:bookworm-slim as run

ENV USER=pivx
ENV GROUP=$USER
ENV ARGS=""

ARG UID=10000
ARG GID=10001

COPY --from=download /opt/pivx /opt/pivx

RUN set -ex \
  && addgroup \
    --system \
    --gid "$GID" \
    $GROUP \
  && adduser \
    --system \
    --uid "$UID" \
    --gid "$GID" \
    --home /home/pivx \
    $USER

USER $USER

RUN set -ex \
  && ln -s /opt/pivx/params /home/pivx/.pivx-params \
  && mkdir -p /home/pivx/data/

EXPOSE 51472/tcp
EXPOSE 51472/udp

VOLUME ["/home/pivx/pivx.conf"]
VOLUME ["/home/pivx/data"]

WORKDIR /home/pivx

ENTRYPOINT ["sh", "-c", "exec /opt/pivx/bin/pivxd -conf=/home/pivx/pivx.conf -datadir=/home/pivx/data $ARGS"]

