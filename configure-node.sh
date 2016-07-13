set -m

/entrypoint.sh couchbase-server &

sleep 15

# Setup index and memory quota
curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=300 -d indexMemoryQuota=300

# Setup services
curl -v http://127.0.0.1:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex

# Setup credentials
curl -v http://127.0.0.1:8091/settings/web -d port=8091 -d username=Administrator -d password=password

# Create main bucket
curl -v -u Administrator:password -X POST http://127.0.0.1:8091/pools/default/buckets -d 'name=main' -d 'authType=sasl' -d 'bucketType=couchbase' -d 'ramQuotaMB=100' -d 'replicaNumber=2' -d ''

# Setup Memory Optimized Indexes
curl -i -u Administrator:password -X POST http://127.0.0.1:8091/settings/indexes -d 'storageMode=memory_optimized'

echo "Type: $TYPE, Master: $COUCHBASE_MASTER"

if [ "$TYPE" = "worker" ]; then
  sleep 15
  set IP=`hostname -I`
  couchbase-cli server-add --cluster=$COUCHBASE_MASTER:8091 --user Administrator --password password --server-add=$IP

    echo "Auto Rebalance: $AUTO_REBALANCE"
    sleep 10
    couchbase-cli rebalance -c $COUCHBASE_MASTER:8091 -u Administrator -p password --server-add=$IP
fi;

fg 1
