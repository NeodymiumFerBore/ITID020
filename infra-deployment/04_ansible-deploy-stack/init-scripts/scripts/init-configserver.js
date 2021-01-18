rs.initiate(
   {
      _id: "configserver",
      configsvr: true,
      version: 1,
      members: [
         { _id: 0, host : "config01:27017", priority: 2 },
         { _id: 1, host : "config02:27017", priority: 1 },
         { _id: 2, host : "config03:27017", priority: 1 }
      ]
   }
);

// Wait to be master
while (!db.isMaster().ismaster) {
sleep(1000);
}
