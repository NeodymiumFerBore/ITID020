rs.initiate(
   {
      _id: "configserver",
      configsvr: true,
      version: 1,
      members: [
         { _id: 0, host : "config01:27017" },
         { _id: 1, host : "config02:27017" },
         { _id: 2, host : "config03:27017" }
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
