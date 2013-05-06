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
JBoss har en egen cache-modul (Infinispan), men appen bruker fremdeles [Redis](http://redis.io/) til å cache anbefalingene. Redis er superrask og fungerer så bra at jeg vet ikke om det er noe vits å bytte. Må teste ut Infinispan litt mere først.

For å installere Redis:
```shell
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make
```

Starte ved å kjøre `/redis-stable/src/redis-server`. Hvis du ikke angir en konfigurasjonsfil som første parameter, vil Redis bruke standardverdier, og serve fra port 6379.

#### Innstillinger i redis.conf:
`deamonize yes`