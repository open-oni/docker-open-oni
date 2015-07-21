Docker Chronam
==============

Run Chronam in Docker.

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
$ SOLR=4.10.4 docker run -d \
$   -p 8983:8983 \
$   --name solr \
$   -v $(pwd)/solr/schema.xml:/opt/solr/example/solr/collection1/conf/schema.xml \
$   -v $(pwd)/solr/solrconfig.xml:/opt/solr/example/solr/collection1/conf/solrconfig.xml \
$   makuk66/docker-solr:$SOLR
```

Chronam
-------

```bash
$ docker run -i -t \
$   -p 80:80 \
$   --name chronam \
$   --link mysql:db \
$   --link solr:solr \
$   -v $(pwd)/data:/opt/chronam/data \
$   lyrasis/chronam:latest
```

Build:

```bash
$ docker build -t chronam:latest .
```

Migrate and start Chronam:

```bash
$ docker run -i -t \
$   -p 80:80 \
$   --name chronam \
$   --link mysql:db \
$   --link solr:solr \
$   -v $(pwd)/data:/opt/chronam/data \
$   chronam:latest
```

**Load data**

```bash
$ cd data
$ wget --recursive --no-host-directories --cut-dirs 1 --reject index.html* --include-directories /data/batches/batch_uuml_thys_ver01/ http://chroniclingamerica.loc.gov/data/batches/batch_uuml_thys_ver01/
$ cd ..
$ docker exec -it chronam /load_batch.sh batch_uuml_thys_ver01
```

---