FROM phusion/baseimage:0.9.19
MAINTAINER Irtiza Ali <irtiza@aurorasolutions.io>

RUN echo "deb http://archive.ubuntu.com/ubuntu xenial main universe" > /etc/apt/sources.list && \
    apt-get -y update && \
    apt-get install -y python-pip && \
    apt-get -y install sudo nano git sudo zip bzip2 fontconfig wget groff && \
    pip install awscli && \
    mkdir -p /home/restore

ENV S3_BUCKET_NAME="docker-backups.example.com" \
    AWS_ACCESS_KEY_ID="" \ 
    AWS_SECRET_ACCESS_KEY="" \
    AWS_DEFAULT_REGION="" \
    LAST_BACKUP="" \
    RESTORE_FOLDER="/home/restore" \
    VOLUME="/usr/share/elasticsearch/data" \
    RESTORE="true"

ADD creat-script.sh /creat-script.sh

CMD ["./creat-script.sh"]
