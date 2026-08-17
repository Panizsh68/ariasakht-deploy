#!/bin/bash
set -euo pipefail

SERVER_HOST="${MONGO_PRIMARY_HOST:-mongo-primary}"
MONGO_USERNAME="${MONGO_INITDB_ROOT_USERNAME:?MONGO_INITDB_ROOT_USERNAME is required}"
MONGO_PASSWORD="${MONGO_INITDB_ROOT_PASSWORD:?MONGO_INITDB_ROOT_PASSWORD is required}"

echo "Waiting for Mongo to be ready..."
until mongo --host "$SERVER_HOST" --port 27017 --username "$MONGO_USERNAME" --password "$MONGO_PASSWORD" --authenticationDatabase admin --eval "db.adminCommand('ping')" &>/dev/null; do
  sleep 2
done

echo "Resolving the replica-set primary..."
PRIMARY_ENDPOINT=""
until [[ "$PRIMARY_ENDPOINT" == *:* ]]; do
  PRIMARY_ENDPOINT="$(mongo --quiet --host "$SERVER_HOST" --port 27017 --username "$MONGO_USERNAME" --password "$MONGO_PASSWORD" --authenticationDatabase admin --eval "var primary = db.isMaster().primary; if (primary) print(primary);" 2>/dev/null | tail -n 1 || true)"
  sleep 2
done

SERVER_HOST="${PRIMARY_ENDPOINT%:*}"
SERVER_PORT="${PRIMARY_ENDPOINT##*:}"
echo "Replica-set primary: ${SERVER_HOST}:${SERVER_PORT}"

echo "Setting up replica set..."
mongo --host "$SERVER_HOST" --port "$SERVER_PORT" --username "$MONGO_USERNAME" --password "$MONGO_PASSWORD" --authenticationDatabase admin <<EOF
try {
  rs.status();
  print("Replica Set already initialized.");
} catch (e) {
  rs.initiate({
    _id: "rs0",
    members: [
      { _id: 0, host: "mongo-primary:27017" },
      { _id: 1, host: "mongo-secondary-1:27017" },
      { _id: 2, host: "mongo-secondary-2:27017" }
    ]
  });
  print("Replica Set Initialized.");
}

var adminDb = db.getSiblingDB("admin");
var userExists = adminDb.getUser("$MONGO_USERNAME");
if (!userExists) {
  adminDb.createUser({
    user: "$MONGO_USERNAME",
    pwd: "$MONGO_PASSWORD",
    roles: [
      { role: "readWrite", db: "test" },
      { role: "dbAdmin", db: "test" }
    ]
  });
  print("Database user created.");
} else {
  print("Database user already exists.");
}
EOF
