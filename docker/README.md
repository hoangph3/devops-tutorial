## demo app - developing with Docker

This demo app shows a simple user profile app set up using 
- main.py run web app
- mysql for data storage

All components are docker-based

### With Docker

#### To start the application

Step 1: Create docker network

    docker network create mysqlnet

Step 2: Create volume

    docker volume create mysql
    docker volume create mysql_config

Step 3: Start mysql database

    docker run -v mysql:/var/lib/mysql \
    -v mysql_config:/etc/mysql -dp 3306:3306 \
    --network mysqlnet \
    --name mysqldb \
    -e MYSQL_ROOT_PASSWORD=p@ssw0rd1 \
    mysql

Step 4: Check mysql is running

    docker exec -it mysqldb bash
    mysql -u root -p
    Enter password: p@ssw0rd1

Step 5: Build image for python app

    docker build -t python-docker-dev .

Step 6: Start python app

    docker run --network mysqlnet \
    --name rest-server \
    -dp 9000:9000 \
    python-docker-dev

Step 7: Access you python application UI from browser

    curl http://localhost:9000

Step 8: Check python app is connected to mysqldb

    curl http://localhost:9000/initdb
    curl http://localhost:9000/widgets

### With Docker Compose

#### To start the application

Step 1: Start mysqldb and python app (make sure you have installed docker-compose)

    docker-compose up -d

Step 2: Access you python application UI from browser

    curl http://localhost:9000
    curl http://localhost:9000/initdb
    curl http://localhost:9000/widgets
