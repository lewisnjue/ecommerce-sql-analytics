

## how to start the project 

to start the project you will need to have `docker` and `docker compose ` installed on your system afte that you can run `docker compose up -d` to start the `container` with the `postgres` database, after that you can connect to the database, for me i usually just for simplicify i just use go inside the container and just connect using `psql` which is much simpler i dont have to install anything for posgres in my machine but you can change this if you want, also you can change the enviroment variables in the `compose.yml` if you want i just like keeping them simple for local work i use better ones when going to production 
