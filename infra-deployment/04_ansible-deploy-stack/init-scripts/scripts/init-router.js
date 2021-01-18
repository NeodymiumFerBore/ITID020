sh.addShard("shard01/shard01a:27017,shard01b:27017,shard01c:27017");
sh.addShard("shard02/shard02a:27017,shard02b:27017,shard02c:27017");
sh.addShard("shard03/shard03a:27017,shard03b:27017,shard03c:27017");

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
 db.getSiblingDB("itid020").createUser(
    {
       user: "itid020",
       pwd: "SuperPassword",
       roles: [
          { role: "readWrite", db: "itid020" }
       ]
    }
 );
