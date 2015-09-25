# zabbix-bdchecker
Service for getting metrics from databases for zabbix

## Motivation
Zabbix provides items types for getting metrics from databases using odbc. But it has some problems. If we have many odbc metrics from database and this database is getting slow, all your poolers are getting busy soon and zabbix dies. The service was developed to avoid these situations. Features:

1. No impact on zabbix processes.
2. Keep persistent connections to databases.
3. Managed connection pool to each database.
4. Statistical information about queries to databases.

## Installation

1. Select host for this service and install there ruby language.
2. Download there this repository.
3. Setup bundler gem
```
gem install bundler
```
4. Setup gems
```
cd <repository_dir>
bundler install
```

## Service configuration

## Configuration in zabbix

## Run service

## Known issues
