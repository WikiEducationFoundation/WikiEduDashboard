* Fresh debian-10.0-buster VM "p-and-e-dashboard-database", default and 'dashboard database' security groups
* 200 GB cinder volume approved: https://phabricator.wikimedia.org/T278132

* log in (as ragesoss)

== Server
* sudo apt update
* sudo apt install mariadb-server
  10.3.27-0+deb10u1

== Horizon

* Create volume, 180GiB
* Attach volume to p-and-e-dashboard-database instance

== Server
* sudo prepare_cinder_volume
  now it shows /dev/sdb mounted on /srv with 168G free.
* copy database backup to /srv/database-dump/2021-03-23_22h10m_12.sql.gz

- configure mariaDB to use /srv as the location of database files:
  - `sudo systemctl stop mysql`
  - `sudo mv /var/lib/msyql /srv/mysql`
  - `sudo mkdir /srv/tmp`
  - `sudo chown mysql:mysql /srv/tmp`

  - edit `/etc/mysql/my.conf` and add the following directives:
    ```
    [mysqld]
    datadir=/srv/mysql
    tmpdir/srv/tmp
    socket=/srv/mysql/mysql.sock
    bind-address=0.0.0.0
    max_allowed_packet=1073741824
    log_warnings=4
    innodb_buffer_pool_size=12GB

    [client]
    port=3306
    socket=/srv/mysql/mysql.sock

* `sudo systemctl start mysql`

* log in to mariadb: `sudo mysql`
* `CREATE DATABASE IF NOT EXISTS dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;`
Use a real username and password, in Rails database.yml
* `CREATE USER 'outreachdashboard'@'%' IDENTIFIED BY '****';`
* `GRANT ALL PRIVILEGES ON dashboard . * TO 'outreachdashboard'@'%';`
* `exit`

* import the database file:
* `cd /srv/database-dump`
* `sudo su`
* `pv 2021-03-23_22h10m_12.sql.gz | gunzip | mysql dashboard

Update database.yml entry on Rails server:

```
production:
  adapter: mysql2
  encoding: utf8mb4
  username: outreachdashboard
  password: ****
  host: p-and-e-dashboard-database
  port: 3306
  database: dashboard
  pool: 100
```
