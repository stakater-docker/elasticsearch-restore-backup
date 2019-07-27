FROM phusion/baseimage:0.9.19
MAINTAINER Irtiza Ali <irtiza@aurorasolutions.io>

RUN echo "deb http://archive.ubuntu.com/ubuntu xenial main universe" > /etc/apt/sources.list && \
	apt-get -y update && \
	apt-get install -y python-pip && \
    apt-get -y install sudo nano git sudo zip bzip2 fontconfig wget groff && \
	pip install awscli && \
    mkdir -p home/restore && \
    mkdir /home/backup

ENV CRON_TIME="*/1 * * * *" \
	S3_BUCKET_NAME="docker-backups.example.com" \
	AWS_ACCESS_KEY_ID="**DefineMe**" \ 
	AWS_SECRET_ACCESS_KEY="**DefineMe**" \
	AWS_DEFAULT_REGION="us-east-1" \
	PATHS_TO_BACKUP="/paths/to/backup" \
	BACKUP_NAME="" \
	LAST_BACKUP="" \
    RESTORE_FOLDER="/home/restore" \
    VOLUME="" \
	RESTORE="true"

ADD run.sh /run.sh

CMD ["./run.sh"]
