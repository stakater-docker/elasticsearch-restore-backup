# Elasticsearch Data Backup and Restore Sidecar

## Overview

Elasticsearch restore and backup requires two container one for each operation. One of them is `init` container and the second one is `sidecar` container. This guide is based on `elasticsearch:2.3.1` version.

## Description

There are multiple ways to backup and restore elasticsearch data, the list is given below:

1- Elasticsearch Snapshot and Restore API. [Details](https://z0z0.me/how-to-create-snapshot-and-restore-snapshot-with-elasticsearch/)

2- Elasticsearch reindexing API. [Details](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html)

3- Elasticsearch data folder restore and backup.

This guide is based on the `3rd` method because of the following reasons:

* When `elasticsearch:2.3.1` version docker container runs it loads the data provided in `/usr/share/elasticsearch/data/` directory. Method 1 cannot be used here because once the elasticsearch server starts it doesn't detect any change in `/etc/elasticsearch/elasticsearch.yml` file and it is the requirement of method 1 to specify the snapshot repository `repo.path: ["/datasource"]` in it.

* Method 2 is useful only if we have multi-node elasticsearch deployment. In which if one node goes down we can backup the data from other nodes.


## Working

Elasticsearch manifest provided in this repository uses two container their details is given below:

1- **`Init Container`**

Init [container's](https://hub.docker.com/r/stakater/elasticsearch-restore) job is to restore the data from the AWS S3 bucket. Untar it and copy the data in the shared volume(`/usr/share/elasticsearch/data`) between the containers.

The reason to use an init container for data restoring is becuase it has a specific purpose, when fullfiled it must stop.

Init container environment variable is given below:

| Environment Variable | Description | Default value |
|---|---|---|
| CRON_TIME | Data backup interval | Default backup interval is "00 */1 * * *", which means take backup after each hour. |
| S3_BUCKET_NAME | AWS S3 bucket name | "" |
| AWS_ACCESS_KEY_ID | AWS account access id | "" |
| AWS_SECRET_ACCESS_KEY | AWS account access id secret | "" |
| AWS_DEFAULT_REGION | AWS default region | "" |
| LAST_BACKUP | Name of the last backup. Last backup name in extracted from S3 bucket name using the script written in `run.sh` file. | None |
| RESTORE_FOLDER | Name of the folder. | /home/restore |
| VOLUME | Volume that is shared between elasticsearch and elasticsearch-restore-backup container | `/usr/share/elasticsearch/data` |
| RESTORE | Variable for check to restore data from S3 bucket. If `true` data will be restored from S3 bucket and store in location given in `RESTORE_FOLDER` env variable otherwise only data backup script will execute in the container. | true |

**`NOTE`**

It is recommended to only use the init container only when the backup (AWS bucket) and current data is synced. 

2- **`Sidecar Container`**

Sidecar [container's](https://hub.docker.com/r/stakater/elasticsearch-backup) job is to back up the data available in `/usr/share/elasticsearch/data` directory. It runs continuously side-by-side with elasticsearch container and backs up the data after the interval specified by the user. During the backup process, it compresses(in `yyyy.mm.dd-HH-MM-SS.tar.gz` format) the data and finally push it to AWS S3 bucket.


| Environment Variable | Description | Default value |
|---|---|---|
| CRON_TIME | Data backup interval | Default backup interval is "00 */1 * * *", which means take backup after each hour. |
| S3_BUCKET_NAME | AWS S3 bucket name | "" |
| AWS_ACCESS_KEY_ID | AWS account access id | "" |
| AWS_SECRET_ACCESS_KEY | AWS account access id secret | "" |
| AWS_DEFAULT_REGION | AWS default region | "" |
| BACKUP_FOLDER | Name of backup folder | /home/backup |
| VOLUME | Volume that is shared between elasticsearch and elasticsearch-restore-backup container | `/usr/share/elasticsearch/data` |
