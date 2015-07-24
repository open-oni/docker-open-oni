Docker open-oni
===============

Run open-oni (community chronam fork) in Docker.

MySQL
-----

```bash
$ docker run -d \
$   -p 3306:3306 \
$   --name mysql \
$   -e MYSQL_ROOT_PASSWORD=123456 \
$   -e MYSQL_DATABASE=chronam \
$   -e MYSQL_USER=chronam \
$   -e MYSQL_PASSWORD=chronam \
$   mysql
```

Now alter the `charset`:

```bash
$ mysql -h 127.0.0.1 -u root --password=123456 -e 'ALTER DATABASE chronam charset=utf8;'
```

Solr
----

```bash
$ export SOLR=4.10.4
$ docker run -d \
$   -p 8983:8983 \
$   --name solr \
$   -v /$(pwd)/solr/schema.xml:/opt/solr/example/solr/collection1/conf/schema.xml \
$   -v /$(pwd)/solr/solrconfig.xml:/opt/solr/example/solr/collection1/conf/solrconfig.xml \
$   makuk66/docker-solr:$SOLR
```

open-oni
--------

See below for development instructions.

```bash
$ docker run -i -t \
$   -p 80:80 \
$   --name open-oni \
$   --link mysql:db \
$   --link solr:solr \
$   -v /$(pwd)/data:/opt/chronam/data \
$   openoni/open-oni:latest
$ # "openoni" is correct for dockerhub org name
```

Or, to build locally:

```bash
$ docker build -t open-oni:latest .
```

Migrate and start the local open-oni:

```bash
$ docker run -i -t \
$   -p 80:80 \
$   --name open-oni \
$   --link mysql:db \
$   --link solr:solr \
$   -v /$(pwd)/data:/opt/chronam/data \
$   open-oni:latest
```

**Load data**

```bash
$ cd data
$ wget --recursive --no-host-directories --cut-dirs 1 --reject index.html* --include-directories /data/batches/batch_uuml_thys_ver01/ http://chroniclingamerica.loc.gov/data/batches/batch_uuml_thys_ver01/
$ cd ..
$ docker exec -it open-oni /load_batch.sh batch_uuml_thys_ver01
```

open-oni development
--------------------

First clone open-oni: `git clone git@github.com:open-oni/open-oni.git`. For a quickstart use `./dev.sh` (note for `docker-machine` use `./dev.sh $IP_ADDRESS_OF_MACHINE`), for more control use:

```bash
$ docker build -t open-oni:dev -f Dockerfile-dev .
```

Migrate and start the development open-oni:

```bash
$ docker run -i -t \
$   -p 80:80 \
$   --name open-oni-dev \
$   --link mysql:db \
$   --link solr:solr \
$   -v /$(pwd)/open-oni/core:/opt/chronam/core \
$   -v /$(pwd)/data:/opt/chronam/data \
$   open-oni:dev
```

In the above example the `core` folder has been host volume mounted for dynamic development. You can mount additional files / folders as needed. For example:

```
$ -v /$(pwd)/open-oni/nebraska:/opt/chronam/nebraska \ # for a custom "app"
$ -v /$(pwd)/settings.py:/opt/chronam/settings.py \ # note: DB_HOST and SOLR_HOST will be overrewritten
```

Volume mounting is optional. You can always rebuild the image and rerun the container during development. To test modifications to the requirements file re-run the build command. Use the `dev.sh` script to simplify this.

**Run tests**

```bash
$ docker exec -it open-oni /test.sh
```

---