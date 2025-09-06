#!/bin/bash

# آدرس IP سرور که containerها روی اون پورت map شدن
SERVER_IP="185.50.38.104"

echo "🌱 Waiting for Mongo to be ready..."

# منتظر بودن برای primary
until mongosh --host "$SERVER_IP" --port 27017 --username admin --password shantia_ariaSakht0425 --authenticationDatabase admin --eval "db.adminCommand('ping')" &>/dev/null; do
  echo "⏳ Still waiting for Mongo..."
  sleep 2
done

echo "✅ Mongo is ready. Setting up replica set..."

mongosh --host "$SERVER_IP" --port 27017 --username admin --password shantia_ariaSakht0425 --authenticationDatabase admin <<EOF
try {
  rs.status();
  print("✅ Replica Set already initialized.");
} catch (e) {
  rs.initiate({
    _id: "rs0",
    members: [
      { _id: 0, host: "$SERVER_IP:27017" },
      { _id: 1, host: "$SERVER_IP:27018" },
      { _id: 2, host: "$SERVER_IP:27019" }
    ]
  });
  print("✅ Replica Set Initialized.");
}

const userExists = db.getSiblingDB("admin").getUser("admin");
if (!userExists) {
  db.getSiblingDB("admin").createUser({
    user: "admin",
    pwd: "shantia_ariaSakht0425",
    roles: [
      { role: "readWrite", db: "test" },
      { role: "dbAdmin", db: "test" }
    ]
  });
  print("✅ User admin created.");
} else {
  print("✅ User admin already exists.");
}
EOF
