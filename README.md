# Containerized KBOT

## 1. Introduction

This project is based on and a containerized version of KBOT project https://bkstar123@bitbucket.org/bkstar123/kbot.git. KBOT is a chatbot built with Botman framework to provide the following capabilities:  
- Check TLS/SSL certificate information for a list of domains, email the result in csv format (it can then be imported to Excel)
- Check DNS A/CNAME records for a list of domains, email the result in csv format (it can then be imported to Excel)
- Decode TLS/SSL certificate data
- Decode Certificate Signing Request (CSR)
- Extract unique root/apex zone from a list of domains


## 2. Services

The containerized KBOT appplication consists of the following services:  
- **kbot-web**: A frontend interface for users to interact with the application. This service can be created using the Docker image **bkstar123/kbot-web:<tag>** (See details in https://hub.docker.com/repository/docker/bkstar123/kbot-web)
- **kbot-worker**: A worker to check the queue for dispatched jobs and esexute them. This service can be created using the Docker image **bkstar123/kbot-worker:<tag>** (See details in https://hub.docker.com/repository/docker/bkstar123/kbot-worker)
- **kbot-db**: A MySQL database server to store the dispatched jobs in queue. This service can be created using the Docker image **bkstar123/kbot-db:<tag>** (See details in https://hub.docker.com/repository/docker/bkstar123/kbot-db)

Alternatively, you can re-build all the above images using their respective Dockerfile files provided in this project and push them to your Docker registries/repositories. To do so, perform the below steps:  
- ```git clone https://github.com/bkstar123/containerized-kbot.git``` to a location in your machine
- ```cd containerized-kbot/db && docker image build -t kbot-db .```
- ```cd ../web && docker image build -t kbot-web .```
- ```cd ../worker && docker image build -t kbot-worker``` 

## 3. Deploy services to standalone containers

Firstly, create a custom bridge network in your Docker host (bridge network is used to connect containers in the scope of a single host):  
```docker network create -d bridge kbot-net```

(Note: If you want to use **overlay** network to connect standalone containers over multiple hosts, the **overlay** network must be created with the flag ```--attachable```)

Then, You must deploy **kbot-db** service before the other services since they depend on it to start.  
### 3.1 kbot-db
```
docker container run -d  --name kbot-db \
-e MYSQL_ROOT_PASSWORD=<your_desired_root_password> \
-e MYSQL_DATABASE=<your desired name of database> \
-e MYSQL_USER=<your desired name of user for above database> \
-e MYSQL_PASSWORD=<your desired password for the above user to access above database> \
-v kbot-db-data:/var/lib/mysql \
--network kbot-net bkstar123/kbot-db
```

Example deployment:  
```
docker container run -d  --name kbot-db \
-e MYSQL_ROOT_PASSWORD=mysecretpassword \
-e MYSQL_DATABASE=kbot \
-e MYSQL_USER=kbotuser \
-e MYSQL_PASSWORD=kbotuserpassword \
-v kbot-db-data:/var/lib/mysql \
--network kbot-net bkstar123/kbot-db
```
**Note**:
- **kbot-db** image defines one mount point to export the MySQL data (under ```/var/lib/mysql```), you can specify a named volume in the Docker host to link with this mount point

### 3.2 kbot-web

Example deployment:  
```
docker container run -d  --name kbot-web -p 8000:80 \
-e APP_NAME=KBOT \
-e APP_ENV=production \
-e APP_DEBUG=false \
-e APP_URL=<http(s)://your-URL-to-KBOT-app> \
-e APP_TIMEZONE=Asia/Ho_Chi_Minh \
-e DB_HOST=kbot-db \
-e DB_DATABASE=kbot \
-e DB_USERNAME=kbotuser \
-e DB_PASSWORD=kbotuserpassword \
-e MAIL_DRIVER=smtp \
-e MAIL_HOST=<your SMTP service> \
-e MAIL_PORT=<your SMTP service port> \
-e MAIL_USERNAME=<your_email\
-e MAIL_PASSWORD=<your email password> \
-e MAIL_ENCRYPTION=ssl \
-e MAIL_FROM_NAME=KBOT \
-e MAIL_FROM_ADDRESS=<your from address> \
-v kbot-web-logs:/var/log/apache2 \
-v kbot-web-application-logs:/var/www/html/kbot/storage/logs \
--network kbot-net bkstar123/kbot-web
```
**Note**: 
- The value of the environment variable```DB_HOST``` must be matched with the name of **kbot-db** service
- The value of the environment variable ```APP_URL``` is the URL of your appplication
- The values of the environment variables ```APP_ENV```  & ```APP_DEBUG``` must be set to ```production```  and **false** for the production deployment
- If you want to send application logs to your Slack webhook, then pass the ```-e LOG_CHANNEL=stack -e LOG_SLACK_WEBHOOK_URL=<your-slack-webhook> -e LOG_SLACK_USERNAME=KBOT``` environment variables to ```docker container run``` command
- **kbot-web** image defines two mount points to export the web access/error logs (under ```/var/log/apache2```) and the application logs (under ```/var/www/html/kbot/storage/logs```), you can specify named volumes in the Docker host to link with these mount points

### 3.3 kbot-worker

Example deployment:  
```
docker container run -d  --name kbot-worker \
-e APP_ENV=production \
-e APP_DEBUG=false \
-e APP_TIMEZONE=Asia/Ho_Chi_Minh \
-e DB_HOST=kbot-db \
-e DB_DATABASE=kbot \
-e DB_USERNAME=kbotuser \
-e DB_PASSWORD=kbotuserpassword \
-v kbot-worker-logs:/tmp/supervisord \
--network kbot-net bkstar123/kbot-worker
```
**Note**: 
- The value of the environment variable```DB_HOST``` must be matched with the name of **kbot-db** service
- The values of the environment variables ```APP_ENV```  & ```APP_DEBUG``` must be set to ```production```  and **false** for the production deployment
- If you want to send application logs to your Slack webhook, then pass the ```-e LOG_CHANNEL=stack -e LOG_SLACK_WEBHOOK_URL=<your-slack-webhook> -e LOG_SLACK_USERNAME=KBOT``` environment variables to ```docker container run``` command
- **kbot-worker** image defines one mount point to export the worker logs (under ```/tmp/supervisord```), you can specify a named volume in the Docker host to link with these mount points

### 3.4 Reverse proxy (optional)

Assuming that, the URL to your app is ```http://containerized-kbot.acme.com```. You may want to place the **kbot-xxx** services behind a reverse proxy so that you can access the frontend interface by pointing browser to ```http://containerized-kbot.acme.com``` instead of ```http://containerized-kbot.acme.com:8000``` (i.e via the published port on the Docker host).  

Example Deployment:  
```
docker container run -d --name reverse-proxy --network kbot-net -v reverse-proxy-config:/etc/nginx -p 80:80 nginx:latest
```
Then, on the Docker host, run the command ```docker volume inspect reverse-proxy-config``` to find out the volume location. Go to that location, and then to **conf.d** and edit the configuration file by running ```vim default.conf``` & placing the following:  
```
server {
    listen 80;
    server_name containerized-kbot.acme.com;
    location / {
        proxy_pass http://kbot-web;
    }
}
```
Finally, stop/start the **reverse-proxy** service.

## 4. Deploy services to an orchestration cluster