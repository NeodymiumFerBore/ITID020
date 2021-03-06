rs.initiate(
   {
      _id: "shard01",
      version: 1,
      members: [
         { _id: 0, host : "shard01a:27017", arbiterOnly: true },
         { _id: 1, host : "shard01b:27017", priority: 2 },
         { _id: 2, host : "shard01c:27017", priority: 1 }
      ]
   }
);
print('Waiting to be master...');

while (!db.isMaster().ismaster) {
   sleep(1000);
}

db.getSiblingDB("admin").createUser(
   {
      user: "root",
      pwd: "verylongpassword",
      roles: [
         { role: "root", db: "admin" }
      ]
   }
);
// Reauth the session
db.getSiblingDB("admin").auth("root", "verylongpassword");

db.getSiblingDB("admin").createUser(
   {
      user: "admin",
      pwd: "verylongpassword",
      roles: [
         { role: "clusterAdmin", db: "admin" },
         { role: "userAdmin", db: "admin" },
         { role: "userAdminAnyDatabase", db: "admin" }
      ]
   }
);
