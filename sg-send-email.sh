#!/usr/bin/bash 
# Simple script to send email notifications via the Sendgrid API.

# Default values
email_from=""
email_name=""
email_to=""
subject=""
message=""
sg_key_file="./sg_key"

print_usage () {
   echo "Usage: "$0" -f EMAIL_FROM -n EMAIL_NAME -t EMAIL_TO -s SUBJECT -m MESSAGE [-k SG_KEY_FILE]"
   echo "EMAIL_FROM - sender's email address"
   echo "EMAIL_NAME - sender's name"
   echo "EMAIL_TO - recipient's email adress"
   echo "SUBJECT - email subject"
   echo "MESSAGE - email message"
   echo "SG_KEY_FILE - a path to the file with Sendgrid API key (default: ./sg_key)"
}

send_email () {
   maildata='{"personalizations": [{"to": [{"email": "'${email_to}'"}]}],"from": {"email": "'${email_from}'",
   "name": "'${email_name}'"},"subject": "'${subject}'","content": [{"type": "text/plain", "value": "'${message}'"}]}'
   
   curl -X "POST" "https://api.sendgrid.com/v3/mail/send" \
      -H "Authorization: Bearer $sg_key" \
      -H "Content-Type: application/json" \
      -d "$maildata"
}

while getopts "f:n:t:s:m:k:h" opt
do
   case $opt in
      f)
         email_from="${OPTARG}";;
      n)
         email_name="${OPTARG}";;
      t)
         email_to="${OPTARG}";;
      s)
         subject="${OPTARG}";;
      m)
         message="${OPTARG}";;
      k)
         sg_key_file="${OPTARG}";;
      h)
         print_usage
         exit 3
         ;;
   esac
done

if [[ ! -f $sg_key_file ]]; then
    echo "API key file \"$sg_key_file\" does not exist"
    exit 1
fi

if [[ "$(stat -c "%a" $sg_key_file)" != "400" ]]; then
    echo "Unsafe API key file permissions"
    exit 1
fi

if [[ "$(wc -l $sg_key_file | cut -d" " -f1)" != "1" ]]; then
   echo "Wrong API key format"
   exit 1
fi

sg_key="$(cat $sg_key_file)"
send_email
