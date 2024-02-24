FROM debian:bookworm-slim as download

ENV PIVX_VERSION=5.6.1
ENV PIVX_URL_PREFIX=https://github.com/PIVX-Project/PIVX/releases/download/v${PIVX_VERSION}
ENV PIVX_FILENAME=pivx-${PIVX_VERSION}-x86_64-linux-gnu.tar.gz
ENV PIVX_TAR_URL=${PIVX_URL_PREFIX}/${PIVX_FILENAME}
ENV PIVX_ASC_URL=${PIVX_URL_PREFIX}/SHA256SUMS.asc
ENV GPGKEY=0xC1ABA64407731FD9

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
ENV UID=10000
ENV GID=10001

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
    --home /home/$USER \
    $USER

USER $USER

RUN set -ex \
  && ln -s /opt/pivx/params /home/${USER}/.pivx-params \
  && mkdir -p /home/${USER}/data/

# Remaining Configurations (same as before)
EXPOSE 51472
VOLUME ["/home/$USER/data"]
WORKDIR /home/$USER

ENTRYPOINT ["/opt/pivx/bin/pivxd", "-datadir=/home/$USER/data"]

