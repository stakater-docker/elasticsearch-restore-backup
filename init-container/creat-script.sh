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
[ -z "${AWS_DEFAULT_REGION}" ] && { echo "=> AWS_DEFAULT_REGION cannot be empty" && exit 1; }

# ************************************* #
# ********* RESTORE SCRIPT ************ #
# ************************************* #
echo "=> Creating restore script"
rm -f /restore.sh
cat <<EOF >> /restore.sh
#!/bin/bash

# *********CHECK IF BUCKET EXISTS************ #
BUCKET_EXIST=\$(aws s3 --region \${AWS_DEFAULT_REGION} ls | grep \${S3_BUCKET_NAME} | wc -l)
if [ \${BUCKET_EXIST} -eq 0 ];
then
    echo "Bucket does not exist"
    exit 1
else
    echo "Bucket exists"
fi

# *********EXTRACTING LAST BACKUP FROM BUCKET************ #
if [ -z "\${LAST_BACKUP}" ]; then
# Find last backup file
: ${LAST_BACKUP:=$(aws s3 ls s3://$S3_BUCKET_NAME | awk -F " " '{print $4}' | sort -r | head -n1)}
fi

# *********DOWNLOADING LAST BACKUP FROM S3 BUCKET************ #
echo "=> Restore from S3 => $LAST_BACKUP"
aws s3 cp s3://$S3_BUCKET_NAME/$LAST_BACKUP $RESTORE_FOLDER/$LAST_BACKUP

# *********COPYING DATA TO ELASTICSEARCH DATA FOLDER************ #
tar -zxvf $RESTORE_FOLDER/$LAST_BACKUP
cp -r elasticsearch ${VOLUME}
echo "Untar complete"
sleep 5
echo "=> Restore dump from \$1"
echo "=> Done"
EOF
# making backup script executable
chmod +x /restore.sh

# Check to execute restore data or not
if [[ "$RESTORE" == "true" ]]; then
  ./restore.sh
fi
