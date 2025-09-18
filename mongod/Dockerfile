FROM mongo:8.0.12-4

RUN apt-get update && apt-get -q install -y

COPY --chown=mongodb:mongodb mongod-start.sh /usr/local/bin/
COPY --chown=mongodb:mongodb mongod-runextra.sh /usr/local/bin/

RUN chmod u+x /usr/local/bin/mongod-start.sh /usr/local/bin/mongod-runextra.sh

ENTRYPOINT ["mongod-start.sh"]

CMD mongod --setParameter "transactionLifetimeLimitSeconds=600" -f /etc/mongod.conf
