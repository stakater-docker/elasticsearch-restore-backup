**Repository not created by Terraform**

# Elasticsearch Data Backup and Restore Sidecar

## Overview

It is a sidecar that will run inside elasticsearch pod. Its main purpose is to backup and restore elasticsearch data.

## Description

Elasticsearch backup and restore [image](https://hub.docker.com/r/stakater/elasticsearch-backup-restore) [EBR] container can be used to backup elasticsearch data on S3 bucket. It runs inside elasticsearch pod as a sidecar container. A volume will be shared between both containers. EBR container will backup the elasticsearh data folder(default data storage folder is `/usr/share/elasticsearch/data` ) after the interval specified by the user.


| Environment Variable | Description | Default value |
|---|---|---|
| CRON_TIME | Data backup interval | Default backup interval is "00 */1 * * *", which means take backup after each hour. |
| S3_BUCKET_NAME | AWS S3 bucket name | "" |
| AWS_ACCESS_KEY_ID | AWS account access id | "" |
| AWS_SECRET_ACCESS_KEY | AWS account access id secret | "" |
| AWS_DEFAULT_REGION | AWS default region | "" |
| BACKUP_NAME | Name of the backup. | Its default value is yyyy.mm.dd-HH-MM-SS-dump.tar.gz |
| LAST_BACKUP | Name of the last backup. Last backup name in extracted from S3 bucket name using the script written in `run.sh` file. | None |
| RESTORE_FOLDER | Name of the folder. | /home/restore |
| BACKUP_FOLDER | Name of backup folder | /home/backup |
| VOLUME | Volume that is shared between elasticsearch and elasticsearch-restore-backup container | `/usr/share/elasticsearch/data` |
| RESTORE | Variable for check to restore data from S3 bucket. If `true` data will be restored from S3 bucket and store in location given in `RESTORE_FOLDER` env variable otherwise only data backup script will execute in the container. | true |


## CAVEATS

* It has been tested with elasticsearch:2.3.1 version.

* Elasticsearch provides different methods to backup and restore data. 
  
  1- [`Using snapshot`](https://linuxaws.wordpress.com/2018/09/21/how-to-create-snapshots-of-elasticsearch-cluster-data-and-restore/):  When the elasticsearch run inside the container it doesn't detect the changes done in `/etc/elasticsearch/elasticsearch.yml` file.

  2- `Using Reindexing`: This feature exists after elasticseach version 5 which is not possible in this scenario because the version that is being used is `2.3.1`.