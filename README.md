#Bokanbefalinger 2.0

## Installasjon

### Torquebox applikasjonsserver
Forsikre deg om at det er en ny versjon (1.6 eller nyere) av java installert:

```bash
$ java -version
java version "1.7.0_15"
OpenJDK Runtime Environment (IcedTea7 2.3.7) (7u15-2.3.7-0ubuntu1~12.04.1)
OpenJDK Server VM (build 23.7-b01, mixed mode)
```

Last ned og installer torquebox:

```bash
$ wget http://torquebox.org/release/org/torquebox/torquebox-dist/2.3.0/torquebox-dist-2.3.0-bin.zip
  # Torquebox is owned by user 'torquebox'
$ sudo adduser torquebox --disabled-login
$ sudo mkdir /opt/torquebox
$ sudo chown torquebox:torquebox /opt/torquebox
$ sudo su torquebox
$ unzip torquebox-dist-2.3.0-bin.zip -d /opt/torquebox/
$ cd /opt/torquebox
  # Symlink current version of torquebox, so it will be easy to upgrade later.
$ ln -s torquebox-2.3.0 current
```

Set opp environment. Legg til i `/home/torquebox/.bashrc`:

```bash
export TORQUEBOX_HOME=/opt/torquebox/current
export JBOSS_HOME=$TORQUEBOX_HOME/jboss
export JRUBY_HOME=$TORQUEBOX_HOME/jruby
PATH=$JBOSS_HOME/bin:$JRUBY_HOME/bin:$PATH
```

Source `.bashrc` og test at alt funker ved å kjøre `torquebox run`.

Konfigurer oppstartsjobb:

```bash
$ cd $TORQUEBOX_HOME
  # NB must be run with user who can write to /etc/init
$ rake torquebox:upstart:install
$ sudo service torquebox start
```

### Redis
Applikasjonen bruker [Redis](http://redis.io/) til å cache anbefalingene.

For å installere Redis:
```shell
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make
```

Starte ved å kjøre `/redis-stable/src/redis-server`. Hvis du ikke angir en konfigurasjonsfil som første parameter, vil Redis bruke standardverdier, og serve fra port 6379.

#### Foreløbige innstillinger i redis.conf
`deamonize yes`