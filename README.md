# zabbix-bdchecker
Service for getting metrics from databases for zabbix

## Motivation
Zabbix provides items types for getting metrics from databases using odbc. But it has some problems. If we have many odbc metrics from database and this database is getting slow, all your poolers are getting busy soon and zabbix dies. The service was developed to avoid these situations. Features:

1. No impact on zabbix processes.
2. Keep persistent connections to databases.
3. Managed connection pool to each database.
4. Statistical information about queries to databases.

## Installation

* Select host for this service and install there Ruby language (https://www.ruby-lang.org).
* Download there this repository.
* Setup database drivers.
* Install bundler gem. Run in command line/console
```
gem install bundler
```
* Change Gemfile - uncomment/add gem's for your databases.
* Install gems. Run in command line/console
```
cd <repository_dir>
bundler install
```
## Service configuration

* Add to params/databases.yml descriptions of all your databases connections. DSN (Data Source Name) there is a unique name for your connection.
* For each DSN create file params/sql/DSN.sql with sql-s. The name of this file shoud be the same as DSN-name in databases.yml. Format of this file is the same as yml-file.
* You may change $SERVER_PORT, $LISTEN_ON_ADRESS constants in bdchecker_server.rb

## Run service

In Windows run in command line
```
ruby bdchecker_server.rb
```

In Linux to run as daemon exec in console 
```
ruby bdchecker-control.rb start
```
You should find "Server started!" in logs/bdchecker.log after starting service 

## Stop service

In Windows - press ctrl-c in window with running service.

In Linux:
```
ruby bdchecker-control.rb stop
```

## Zabbix configuration

To get full advantage from this service we must set up "Zabbix agent (active)" item in zabbix.

To get metric from this service you should:
* make tcp/ip connection to service
* send line 
```
DSN1,SQL_NAME,PARAM1,PARAM2
```
where: DSN1 - name of DSN from params/databases.yml; SQL_NAME - name of sql from params/sql/DSN1.sql; PARAM1,PARAM2 - optional parameters for sql
* read line with result

You can write your own client or use client/get_data.py or compile client/zbx_bd_win.go for windows/linux.

We need installed Zabbix agent on target host. If we can not have agent on that host we can install it somewhere else (for example on proxy-server). 

If zabbix agent is not on the target host:
- set unique Hostname in agent configuration file (it can be any name)
- set unique ListenPort in agent configuration file if there are other agents on this server (for example 10053)
- add host in zabbix with the same name (so active checks can be found by hostname)
- set "Agent interface" for that host. 

Add to agent configuration file:
```
UserParameter=bd[*],echo "$1" | /path/to/client/script/get_data.py localhost 10000
```
change localhost and 10000 to values of $LISTEN_ON_ADRESS, $SERVER_PORT constants in bdchecker_server.rb

Now you can add "Zabbix agent (active)" item in zabbix. The key will be `bd["DSN1,SQL_NAME,PARAM1,PARAM2"]`.

## Known issues

Error "Target thread must not be current thread" is recorded in logs on the first request to database. This error does not affect on the work of this service.
