# docker-pivx-wallet

## Building the Docker image

To build the Docker image, you'll need Docker installed. Then run the following command in your terminal from the project's root directory:

```bash
$ docker build --build-arg PIVX_VERSION=5.6.1 -t pivx-wallet
```

## Running the rootless Podman container

Create a `~/pivx.conf` coniguration file as documented at https://docs.pivx.org/masternodes/masternodes#step-3-–-create-the-masternode-configuration-file-and-populate 

Create a [quadlet](https://www.redhat.com/sysadmin/quadlet-podman) configuration at `~/.config/containers/systemd/pivx-wallet.container` with this content:

```ini
[Install]
  WantedBy=default.target

[Unit]
  Description=PIVX wallet
  StartLimitIntervalSec=500
  StartLimitBurst=5

[Service]
  TimeoutStartSec=900
  Restart=on-failure
  RestartSec=5s

[Container]
  Image=docker.io/fm0s/pivx:latest
  AutoUpdate=registry
  Volume=pivx-data:/home/pivx/data:Z
  Volume=%h/pivx.conf:/home/pivx/pivx.conf:Z,ro
  PublishPort=51472:51472/tcp
  PublishPort=51472:51472/udp
```

Allow user to run container when logged off, open firewall ports and run container:

```bash
$ sudo loginctl enable-linger $USER
$ sudo firewall-cmd --permanent --zone=public --add-port=51472/udp --add-port=51472/tcp
$ sudo firewall-cmd --reload
$ systemctl --user daemon-reload
$ systemctl --user start pivx-wallet.service
```

