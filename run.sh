#!/bin/bash
export PATH=$PATH:/usr/bin:/usr/local/bin:/bin

# These environment variables must not be empty
echo  "Validating environment variable existance"
[ -z "${AWS_ACCESS_KEY_ID}" ] && { echo "=> AWS_ACCESS_KEY_ID cannot be empty" && exit 1; }
[ -z "${AWS_SECRET_ACCESS_KEY}" ] && { echo "=> AWS_SECRET_ACCESS_KEY cannot be empty" && exit 1; }
[ -z "${VOLUME}" ] && { echo "=> VOLUME path cannot be empty" && exit 1; }
[ -z "${S3_BUCKET_NAME}" ] && { echo "=> S3_BUCKET_NAME cannot be empty" && exit 1; }
[ -z "${CRON_TIME}" ] && { echo "=> CRON_TIME cannot be empty" && exit 1; }
[ -z "${AWS_DEFAULT_REGION}" ] && { echo "=> AWS_DEFAULT_REGION cannot be empty" && exit 1; }


echo "=> Creating restore script"
rm -f /restore.sh
cat <<EOF >> /restore.sh
#!/bin/bash
BUCKET_EXIST=\$(aws s3 --region \${AWS_DEFAULT_REGION} ls | grep \${S3_BUCKET_NAME} | wc -l)
if [ \${BUCKET_EXIST} -eq 0 ];
then
    echo "Bucket does not exist"
    exit 1
else
    echo "Bucket exists"
fi

echo "Extracting last backup name from bucket"
if [ -z "\${LAST_BACKUP}" ]; then
# Find last backup file
: ${LAST_BACKUP:=$(aws s3 ls s3://$S3_BUCKET_NAME | awk -F " " '{print $4}' | sort -r | head -n1)}
fi

# Download backup from S3
echo "=> Restore from S3 => $LAST_BACKUP"
aws s3 cp s3://$S3_BUCKET_NAME/$LAST_BACKUP $RESTORE_FOLDER/$LAST_BACKUP
echo "=> Restore dump from \$1"

echo "=> Done"
EOF
chmod +x /restore.sh

echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/bash
export PATH=$PATH:/usr/bin:/usr/local/bin:/bin
MAX_BACKUPS=${MAX_BACKUPS}
BACKUP_NAME=\$(date +\%Y.\%m.\%d.\%H-\%M-\%S)

echo "=> Backup started: \${BACKUP_NAME}"
echo "${VOLUME}"

tar -czvf /home/backup/"\${BACKUP_NAME}"-dump.tar.gz "${VOLUME}" > /dev/null
ls /backup/

echo "=> Upload to s3 started: \${BACKUP_NAME}"

# Create bucket, if it doesn't already exist
BUCKET_EXIST=\$(aws s3 --region \${AWS_DEFAULT_REGION} ls | grep \${S3_BUCKET_NAME} | wc -l)

if [ \${BUCKET_EXIST} -eq 0 ];
then
    aws s3 --region \${AWS_DEFAULT_REGION} mb s3://\${S3_BUCKET_NAME}
else
    echo "Bucket exists"
fi
# Upload the backup to S3 with timestamp
aws s3 --region \${AWS_DEFAULT_REGION} cp /home/backup/"\${BACKUP_NAME}"-dump.tar.gz s3://\${S3_BUCKET_NAME}/\${BACKUP_NAME}
echo "=> Upload to s3 done"


# *********CLEAN UP************
echo "=> Cleanup started: /home/backup/"\${BACKUP_NAME}"-dump.tar.gz"
rm /home/backup/"\${BACKUP_NAME}"-dump.tar.gz

echo "=> Cleanup done"

EOF
chmod +x /backup.sh

if [[ "$RESTORE" == "true" ]]; then
  ./restore.sh
fi

echo "${CRON_TIME} export S3_BUCKET_NAME=${S3_BUCKET_NAME}; export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}; export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}; export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}; /backup.sh >> /es_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running cron job"
exec cron -f
