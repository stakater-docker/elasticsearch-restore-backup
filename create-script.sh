#!/bin/bash
export PATH=$PATH:/usr/bin:/usr/local/bin:/bin

# ************************************* #
# ********* ENV VARS ****************** #
# ************************************* #
echo  "Validating environment variable existance"
[ -z "${AWS_ACCESS_KEY_ID}" ] && { echo "=> AWS_ACCESS_KEY_ID cannot be empty" && exit 1; }
[ -z "${AWS_SECRET_ACCESS_KEY}" ] && { echo "=> AWS_SECRET_ACCESS_KEY cannot be empty" && exit 1; }
[ -z "${VOLUME}" ] && { echo "=> VOLUME path cannot be empty" && exit 1; }
[ -z "${S3_BUCKET_NAME}" ] && { echo "=> S3_BUCKET_NAME cannot be empty" && exit 1; }
[ -z "${CRON_TIME}" ] && { echo "=> CRON_TIME cannot be empty" && exit 1; }
[ -z "${AWS_DEFAULT_REGION}" ] && { echo "=> AWS_DEFAULT_REGION cannot be empty" && exit 1; }

# ************************************ #
# ********* BACKUP SCRIPT ************ #
# ************************************ #
echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/bash
export PATH=$PATH:/usr/bin:/usr/local/bin:/bin

# *********BACKING UP DATA************ #
BACKUP_NAME=\$(date +\%Y.\%m.\%d.\%H-\%M-\%S).tar.gz
echo "=> Backup started: \${BACKUP_NAME}"
tar -czvf $BACKUP_FOLDER/"\${BACKUP_NAME}" --directory="${VOLUME}" elasticsearch  > /dev/null
echo "=> Backup has been completed"

# *********CREATING BUCKET IF IT DOES NOT EXISTS************ #
BUCKET_EXIST=\$(aws s3 --region \${AWS_DEFAULT_REGION} ls | grep \${S3_BUCKET_NAME} | wc -l)
if [ \${BUCKET_EXIST} -eq 0 ];
then
    echo "=> Creating bucket"
    aws s3 --region \${AWS_DEFAULT_REGION} mb s3://\${S3_BUCKET_NAME}
    echo "=> Bucket created"
else
    echo "Bucket exists"
fi

# *********UPLOADING DATA TO S3 BUCKET************ #
echo "=> Upload to s3 started: \${BACKUP_NAME}"
# Upload the backup to S3 with timestamp
aws s3 --region \${AWS_DEFAULT_REGION} cp $BACKUP_FOLDER/"\${BACKUP_NAME}" s3://\${S3_BUCKET_NAME}/\${BACKUP_NAME}
echo "=> Upload to s3 done"


# *********CLEAN UP************ #
echo "=> Cleanup started: $BACKUP_FOLDER/"\${BACKUP_NAME}""
# rm $BACKUP_FOLDER/"\${BACKUP_NAME}"
echo "=> Cleanup done"

EOF

# making backup script executable
chmod +x /backup.sh

# *********************************************** #
# ********* CRON JOB FOR DATA BACKUP ************ #
# *********************************************** #
echo "${CRON_TIME} export S3_BUCKET_NAME=${S3_BUCKET_NAME}; export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}; export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}; export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}; /backup.sh >> /es_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running cron job"
exec cron -f
