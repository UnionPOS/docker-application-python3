FROM unionpos/python:3.8.11b

ENV COUCHBASE_PKG "couchbase-server-enterprise_7.0.2-ubuntu18.04_amd64.deb"
ENV MYSQL_PKG "mysql-apt-config_0.8.9-1_all.deb"
ENV REDIS_PKG "redis-stable.tar.gz"

# include the gosu binary
COPY --from=unionpos/gosu:1.11 /gosu /usr/local/bin/

RUN set -ex \
    && buildDeps=' \
    lsb-release \
    gnupg \
    gpg-agent \
    wget \
    libjemalloc1 \
    libjemalloc-dev \
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends build-essential $buildDeps \
    # Ubuntu key
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 467B942D3A79BD29 \
    # couchbase dev
    && wget -O $COUCHBASE_PKG http://packages.couchbase.com/releases/7.0.2/$COUCHBASE_PKG \
    && dpkg -i $COUCHBASE_PKG && rm $COUCHBASE_PKG \
    && wget -O - http://packages.couchbase.com/ubuntu/couchbase.key | apt-key add - \
    && echo "deb http://packages.couchbase.com/ubuntu bionic bionic/main" | tee /etc/apt/sources.list.d/couchbase.list \
    && apt-get update && apt-get install -y --no-install-recommends libcouchbase-dev \
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
    && apt-get update && apt-get install -y --no-install-recommends redis-tools \
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
