#!/bin/sh

if [ "$DO_INIT_REPSET" = true ] ; then
    # Wait until local MongoDB instance is up and running
    until /usr/bin/mongosh --port 27017 --quiet --eval 'db.getMongo()'; do
        sleep 1
    done

    # Configure this replica set as a SINGLE-member set (dev: low idle CPU).
    # Idempotent and data-preserving:
    #   - uninitiated      -> rs.initiate with one member (self-elects PRIMARY)
    #   - >1 member on disk -> one-time forced reconfig down to member 0; recovers
    #                          a node left without a voting majority after the
    #                          replica1/replica2 containers were removed
    #   - already 1 member  -> no-op
    /usr/bin/mongosh --port 27017 --quiet <<EOF
        try {
            var cfg = rs.conf();
            if (cfg.members.length > 1) {
                cfg.members = [cfg.members[0]];
                rs.reconfig(cfg, {force: true});
                print("repset ${REPSET_NAME}: forced reconfig to single member");
            } else {
                print("repset ${REPSET_NAME}: already single member, no-op");
            }
        } catch (e) {
            if (e.code === 94 || /NotYetInitialized|no replset config/i.test(e.message)) {
                rs.initiate({_id: "${REPSET_NAME}", members: [
                    {_id: 0, host: "${REPSET_NAME}-replica0:27017"}
                ], settings: {electionTimeoutMillis: 2000}});
                print("repset ${REPSET_NAME}: initiated single member");
            } else {
                throw e;
            }
        }
EOF
fi
