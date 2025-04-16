#!/usr/bin/bash 
# Script for syncing backup to remote object storage (S3 based) using rclone.

# Default values
local_path=""
remote_path=""
email_from=""
email_name=""
email_to=""
send_email_script_path="/etc/sg-send-email.sh"

print_usage () {
   echo "Usage: "$0" -l LOCAL_PATH -r REMOTE_PATH -f EMAIL_FROM -n EMAIL_NAME -t EMAIL_TO -s SEND_EMAIL_SCRIPT_PATH"
   echo "LOCAL_PATH - local path to sync"
   echo "REMOTE_PATH - remote path in format remote:bucket/path"
   echo "EMAIL_FROM - sender's email address"
   echo "EMAIL_NAME - sender's name"
   echo "EMAIL_TO - recipient's email adress"
   echo "SEND_EMAIL_SCRIPT_PATH - a path to the send email script (default: /etc/sg-send-email.sh)"
}

while getopts "l:r:f:n:t:s:h" opt
do
   case $opt in
      l)
         local_path="${OPTARG}";;
      r)
         remote_path="${OPTARG}";;
      f)
         email_from="${OPTARG}";;
      n)
         email_name="${OPTARG}";;
      t)
         email_to="${OPTARG}";;
      s)
         send_email_script_path="${OPTARG}";;
      h)
         print_usage
         exit 3
         ;;
   esac
done

# Check if script for sending emails is in place
if [[ ! -f $send_email_script_path ]]; then
    echo "Script \"$send_email_script_path\" does not exist"
    exit 1
fi

# Run script and capture time and exit code
start_time=$(date +'%Y-%m-%d %H:%M:%S')
rclone sync ${local_path} ${remote_path} --log-file=/var/log/rclone-backup.log --log-level INFO
exit_code="$?"
end_time=$(date +'%Y-%m-%d %H:%M:%S')

# Send email notification with sync status
email_message="Start time: ${start_time}\nEnd time: ${end_time}"
status="SUCCESSFUL"

if [[ $exit_code -ne 0 ]]; then
    status="FAILED"
fi

${send_email_script_path} -f ${email_from} -n ${email_name} -t ${email_to} -s "Backup sync to S3 status: ${status}" -m "${email_message}"

