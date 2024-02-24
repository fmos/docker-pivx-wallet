# docker-pivx-wallet

get the latest pivx blockchain snapshot here

http://178.254.23.111/~pub/PIVX/Daily-Snapshots-Html/PIVX-Daily-Snapshots.html

```
version: '3'
services:
  wallet:
    image: fm0s/pivx:latest
    ports:
      - "51472:51472"
    volumes: 
      - /opt/pivx/data/:/home/pivx/data/
```
