Allows to run `postgres` with any user available on the host by setting up this user in the container
as the postgres cluster owner during container creation.

Accepts the following arguments
```
   --pg-cluster-owner-userid <string>
   --pg-cluster-owner-groupid <string>
   --pg-db-owner-name <string>
   --pg-db-name <string>
   --pg-log-statements
```
