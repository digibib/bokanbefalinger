#Bokanbefalinger 2.0

For å stare kjør `rackup` eller `thin start`

## Installasjon

### Redis
Applikasjonen bruker [Redis](http://redis.io/) til å cache anbefalingene.

For å installere Reids:
```shell
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make
```

Starte ved å kjøre `/redis-stable/src/redis-server`. Hvis du ikke angir en konfigurasjonsfil som første parameter, vil Redis bruke standardverdier.

#### Foreløbige innstillinger i redis.conf
`deamonize yes`