rs.initiate(
   {
      _id: "shard03",
      version: 1,
      members: [
         { _id: 0, host : "shard03a:27017", arbiterOnly: true },
         { _id: 1, host : "shard03b:27017" },
         { _id: 2, host : "shard03c:27017" }
      ]
   }
);
db.getSiblingDB("admin").createUser(
   {
      user: "admin",
      pwd: "verylongpassword",
      roles: [
         { role: "clusterAdmin", db: "admin" },
         { role: "userAdmin", db: "admin" }
      ]
   },
   {
      user: "root",
      pwd: "verylongpassword",
      roles: [
         { role: "root", db: "admin" }
      ]
   }
);
