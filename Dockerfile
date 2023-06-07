FROM unionpos/python:3.8.11

ENV COUCHBASE_PKG "couchbase-release-1.0-2-amd64.deb"
ENV MYSQL_PKG "mysql-apt-config_0.8.9-1_all.deb"
ENV REDIS_PKG "redis-stable.tar.gz"

# include the gosu binary
COPY --from=unionpos/gosu:1.11 /gosu /usr/local/bin/

RUN set -ex \
    && buildDeps=' \
    lsb-release \
    wget \
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends build-essential $buildDeps \
    # couchbase dev
    && wget -O $COUCHBASE_PKG http://packages.couchbase.com/releases/couchbase-release/$COUCHBASE_PKG \
    && dpkg -i $COUCHBASE_PKG && rm $COUCHBASE_PKG \
    && apt-key update && apt-get update && apt-get install -y --no-install-recommends libcouchbase-dev \
    # mysql dev
    && wget -O $MYSQL_PKG http://repo.mysql.com/$MYSQL_PKG \
    && dpkg -i $MYSQL_PKG && rm $MYSQL_PKG \
    && apt-key list \
    && apt-key update && apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
    libxml2-dev libxslt-dev libmysqlclient-dev mysql-client \
    # nodejs
    && curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && node -v \
    # pwgen
    && apt-get update && apt-get install -y --no-install-recommends pwgen \
    && ln -s /usr/bin/pwgen /bin/pwgen \
    # python-dev & virtualenv
    && apt-get update && apt-get install -y --no-install-recommends python-dev curl \
    && pip install virtualenv \
    # redis cli
    && wget -O $REDIS_PKG http://download.redis.io/$REDIS_PKG \
    && tar xvzf $REDIS_PKG -C /tmp \
    && cd /tmp/redis-stable && make && chmod 755 src/redis-cli \
    && cp src/redis-cli /usr/local/bin/ \
    && rm -rf /tmp/redis-stable \
    && cd / \
    # cleanup
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -rf /var/lib/apt/lists/*

# create mount point for volumes holding custom startup
RUN mkdir /docker-entrypoint.d

# create mount point for volumes holding application source
RUN mkdir -p /opt/backend/bin

EXPOSE 3000

COPY scripts/docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
