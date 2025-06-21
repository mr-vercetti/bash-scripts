#!/usr/bin/bash 
# Script for syncing backup to remote object storage (S3 based) using rclone.

# Default values
local_path=""
remote_path=""
email_from=""
email_name=""
email_to=""
send_email_script_path="/etc/send-email.sh"
email_provider=""

print_usage () {
   echo "Usage: $0 -l LOCAL_PATH -r REMOTE_PATH -f EMAIL_FROM -n EMAIL_NAME -t EMAIL_TO -s SEND_EMAIL_SCRIPT_PATH -p EMAIL_PROVIDER"
   echo ""
   echo "Required:"
   echo "  -l LOCAL_PATH             Local path to sync"
   echo "  -r REMOTE_PATH            Remote path in format remote:bucket/path"
   echo "  -f EMAIL_FROM             Sender's email address"
   echo "  -n EMAIL_NAME             Sender's name"
   echo "  -t EMAIL_TO               Recipient's email address"
   echo "  -p EMAIL_PROVIDER         Email provider: resend or sendgrid"
   echo ""
   echo "Optional:"
   echo "  -s SEND_EMAIL_SCRIPT_PATH Path to the send email script (default: /etc/send-email.sh)"
}

while getopts "l:r:f:n:t:s:p:h" opt
do
   case $opt in
      l) local_path="${OPTARG}" ;;
      r) remote_path="${OPTARG}" ;;
      f) email_from="${OPTARG}" ;;
      n) email_name="${OPTARG}" ;;
      t) email_to="${OPTARG}" ;;
      s) send_email_script_path="${OPTARG}" ;;
      p) email_provider="${OPTARG}" ;;
      h)
         print_usage
         exit 0
         ;;
      *)
         print_usage
         exit 1
         ;;
   esac
done

# Validate required parameters
if [[ -z "$local_path" || -z "$remote_path" || -z "$email_from" || -z "$email_name" || -z "$email_to" || -z "$email_provider" ]]; then
    echo "Error: Missing required parameter(s)"
    print_usage
    exit 1
fi

# Validate email provider
if [[ "$email_provider" != "resend" && "$email_provider" != "sendgrid" ]]; then
    echo "Error: Invalid email provider '$email_provider'. Use 'resend' or 'sendgrid'"
    exit 1
fi

# Check if send-email script exists
if [[ ! -f "$send_email_script_path" ]]; then
    echo "Script \"$send_email_script_path\" does not exist"
    exit 1
fi

# Run sync and capture start/end time and status
start_time=$(date +'%Y-%m-%d %H:%M:%S')
rclone sync "${local_path}" "${remote_path}" --log-file=/var/log/rclone-backup.log --log-level INFO
exit_code="$?"
end_time=$(date +'%Y-%m-%d %H:%M:%S')

# Prepare email
status="SUCCESSFUL"
if [[ $exit_code -ne 0 ]]; then
    status="FAILED"
fi

email_message="Start time: ${start_time}\nEnd time: ${end_time}"

# Send email
"$send_email_script_path" \
   -f "$email_from" \
   -n "$email_name" \
   -t "$email_to" \
   -s "Backup sync to S3 status: $status" \
   -m "$email_message" \
   -p "$email_provider"

