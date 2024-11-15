These are notes from setting up a fresh database server for use with the existing data volume, July 2, 2024.

* Spin up a new large server (16 core, 32GB ram)
* `sudo apt update`
* `sudo apt install mariadb-server`
* `sudo systemctl stop mysql`

* configure mariaDB to use /srv as the location of database files:
  - edit `/etc/mysql/my.cnf` and add the following directives:

    ```
[mysqld]
datadir=/srv/mysql
tmpdir=/srv/tmp
socket=/srv/mysql/mysql.sock
bind-address=0.0.0.0
max_allowed_packet=1073741824
log_warnings=4
innodb_buffer_pool_size=12GB

[client]
port=3306
socket=/srv/mysql/mysql.sock
    ```

* Shut down all the Rails servers and processes that connect to the database.
* On the old server, `sudo systemctl stop mysql`. Note: It's important that mysql shuts down cleanly.
* Detach the Cinder volume from the old server, and attach it to the new one via Horizon.
* Configure the new server to mount the volume (in the default /srv location): `sudo wmcs-prepare-cinder-volume`. (See also https://wikitech.wikimedia.org/wiki/Help:Adding_disk_space_to_Cloud_VPS_instances)
* Update permissions for the required directories:
  * `sudo chown -R mysql:mysql /srv/mysql/`
  * `sudo chown -R mysql:mysql /srv/tmp/`
* Start the database: `sudo systemctl start mysql`
  * If it fails to start, use systemctl to explore the error. Possible problems include the mysql or tmp directories not being writable, the innoDB log files indicating a non-clean shutdown which may be incompatible with the new version of mariadb running on the server (which can be fixed by re-attaching and re-owning the Cinder volume to the old server and doing a clean start and shutdown of mysql, then moving it back).
* Once the database is back up, update `database.yml` for each Rails server to point to the new database, then restart Rails and the workers.