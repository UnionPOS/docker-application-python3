FROM unionpos/python:3.11.8

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
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends build-essential $buildDeps \
    # Install Couchbase dependencies
    && apt-get install -y --no-install-recommends libtinfo6 \
    # Install Couchbase
    && wget -O $COUCHBASE_PKG http://packages.couchbase.com/releases/7.0.2/$COUCHBASE_PKG \
    && dpkg -i --force-depends $COUCHBASE_PKG && rm $COUCHBASE_PKG \
    # Note that we skipslibcouchbase-dev installation due to repository access issues
    # CB should older version of the application docker image
    # && wget -O - http://packages.couchbase.com/ubuntu/couchbase.key | gpg --dearmor -o /usr/share/keyrings/couchbase-archive-keyring.gpg \
    # && echo "deb [signed-by=/usr/share/keyrings/couchbase-archive-keyring.gpg] http://packages.couchbase.com/ubuntu jammy jammy/main" | tee /etc/apt/sources.list.d/couchbase.list \
    # && apt-get update && apt-get install -y --no-install-recommends libcouchbase-dev \
    # Fix broken dependencies and install MySQL packages
    && apt-get update && apt --fix-broken install -y \
    && apt-get install -y --no-install-recommends \
    libxml2-dev libxslt1-dev libmysqlclient-dev \
    # Install Node.js
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && node -v \
    # Install pwgen
    && apt-get update && apt-get install -y --no-install-recommends pwgen \
    && rm -f /bin/pwgen && ln -s /usr/bin/pwgen /bin/pwgen \
    # Install Python dev tools and virtualenv
    && apt-get update && apt-get install -y --no-install-recommends python3-dev curl \
    && pip install virtualenv \
    # Install Redis CLI
    && apt-get update && apt-get install -y --no-install-recommends redis-tools \
    # Cleanup
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -rf /var/lib/apt/lists/*

# create mount point for volumes holding custom startup
RUN mkdir /docker-entrypoint.d

# create mount point for volumes holding application source
RUN mkdir -p /opt/backend/bin

EXPOSE 3000

COPY scripts/docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
