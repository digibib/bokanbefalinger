## Installasjon

### Torquebox applikasjonsserver
Forsikre deg om at det er en ny versjon av java installert (1.6 eller nyere):

```bash
$ java -version
java version "1.7.0_15"
OpenJDK Runtime Environment (IcedTea7 2.3.7) (7u15-2.3.7-0ubuntu1~12.04.1)
OpenJDK Server VM (build 23.7-b01, mixed mode)
```

Innstaller [Leiningen](http://leiningen.org/):

```bash
$ wget https://raw.github.com/technomancy/leiningen/stable/bin/lein
$ sudo cp lein /usr/bin/lein
$ sudo chmod a+x /usr/bin/lein
$ sudo adduser torquebox --disabled-login
$ sudo su torquebox
$ lein
```

Innstaller [Torquebox](http://torquebox.org) og [Immutant](http://immutang.org):

```bash
$ cat > /home/torquebox/.lein/profiles.clj <<EOF
$ {:user {:plugins [[lein-immutant "0.18.0"]] }}
$ EOF
$ lein immutant install
$ lein immutant overlay
```

Set opp environment. Legg til i `/home/torquebox/.bashrc`:

```bash
export TORQUEBOX_HOME=/home/torquebox/.lein/immutant/current
export IMMUTANT_HOME=$TORQUEBOX_HOME
export JBOSS_HOME=$TORQUEBOX_HOME/jboss
export JRUBY_HOME=$TORQUEBOX_HOME/jruby
PATH=$JBOSS_HOME/bin:$JRUBY_HOME/bin:$PATH
```

Source `.bashrc` og test at alt funker ved å kjøre `torquebox run`.

Konfigurer oppstartsjobb:

```bash
$ cd $TORQUEBOX_HOME
$ rake torquebox:upstart:install # NB må kjøres av bruker med tilatelse til å skrive til /etc/init.
$ sudo service torquebox start
```

Overnevnte kommanda skal skrive følgende til /etc/init/torquebox.conf:

```bash
description "This is an upstart job file for TorqueBox"

pre-start script
bash << "EOF"
  mkdir -p /var/log/torquebox
  chown -R torquebox /var/log/torquebox
EOF
end script

start on started network-services
stop on stopped network-services
respawn

limit nofile 4096 4096

script
bash << "EOF"
  su - torquebox
  /home/torquebox/.lein/immutant/current/jboss/bin/standalone.sh >> /var/log/torquebox/torquebox.log 2>&1
EOF
end script
```


### Apache routing
JBoss server til port 8080.

```apache
<VirtualHost *:80>
  ServerName anbefalinger.deichman.no
  DocumentRoot /home/torquebox/bokanbefalinger

  ProxyRequests Off
  ProxyPreserveHost on
  ProxyTimeout        300
  # Proxy ACL
  <Proxy *>
      Order deny,allow
      Allow from all
  </Proxy>
  <Proxy />
    Allow from all
    ProxyPass http://localhost:8080/ timeout=300
    ProxyPassReverse http://localhost:8080/
  </Proxy>

  ErrorLog /var/log/apache2/nyeanbefalinger.deichman.no_error
  CustomLog /var/log/apache2/nyeanbefalinger.deichman.no_access combined
</VirtualHost>
```

### Cache
JBoss har en egen cache-modul (Infinispan), men appen bruker fremdeles [Redis](http://redis.io/) til å cache anbefalingene. Redis er superrask og fungerer så bra at jeg vet ikke om det er noe poeng å bytte.

For å installere Redis:
```shell
sudo apt-get install redis-server
```
Dette vil også konfigurere redis som upstart service.
