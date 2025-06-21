#!/usr/bin/bash

script_dir="$(dirname "$0")"
default_resend_key_file="$script_dir/rs_key"
default_sendgrid_key_file="$script_dir/sg_key"

# Default values
email_from=""
email_name=""
email_to=""
subject=""
message=""
provider=""
key_file=""

print_usage () {
   echo "Usage: $0 -f EMAIL_FROM -n EMAIL_NAME -t EMAIL_TO -s SUBJECT -m MESSAGE -p PROVIDER [-k KEY_FILE]"
   echo ""
   echo "Required:"
   echo "  -f EMAIL_FROM     Sender's email address"
   echo "  -n EMAIL_NAME     Sender's name"
   echo "  -t EMAIL_TO       Recipient's email address"
   echo "  -s SUBJECT        Email subject"
   echo "  -m MESSAGE        Email message"
   echo "  -p PROVIDER       Email provider: 'resend' or 'sendgrid'"
   echo ""
   echo "Optional:"
   echo "  -k KEY_FILE       Path to API key file (defaults: ./rs_key for resend, ./sg_key for sendgrid)"
   echo ""
}

send_email_resend () {
   full_from="${email_name} <${email_from}>"

   maildata='{
      "to": ["'"${email_to}"'"],
      "from": "'"${full_from}"'",
      "subject": "'"${subject}"'",
      "text": "'"${message}"'"
   }'

   curl -X POST "https://api.resend.com/emails" \
      -H "Authorization: Bearer $api_key" \
      -H "Content-Type: application/json" \
      -d "$maildata"
}

send_email_sendgrid () {
   maildata='{
      "personalizations": [{"to": [{"email": "'"${email_to}"'"}]}],
      "from": {"email": "'"${email_from}"'", "name": "'"${email_name}"'"},
      "subject": "'"${subject}"'",
      "content": [{"type": "text/plain", "value": "'"${message}"'"}]
   }'

   curl -X POST "https://api.sendgrid.com/v3/mail/send" \
      -H "Authorization: Bearer $api_key" \
      -H "Content-Type: application/json" \
      -d "$maildata"
}

while getopts "f:n:t:s:m:p:k:h" opt
do
   case $opt in
      f) email_from="${OPTARG}" ;;
      n) email_name="${OPTARG}" ;;
      t) email_to="${OPTARG}" ;;
      s) subject="${OPTARG}" ;;
      m) message="${OPTARG}" ;;
      p) provider="${OPTARG}" ;;
      k) key_file="${OPTARG}" ;;
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
if [[ -z "$email_from" || -z "$email_name" || -z "$email_to" || -z "$subject" || -z "$message" || -z "$provider" ]]; then
   echo "Error: Missing required parameter(s)"
   print_usage
   exit 1
fi

# Validate provider
if [[ "$provider" != "resend" && "$provider" != "sendgrid" ]]; then
   echo "Error: Invalid provider '$provider'. Use 'resend' or 'sendgrid'"
   exit 1
fi

# Default key file per provider if not specified
if [[ -z "$key_file" ]]; then
   if [[ "$provider" == "resend" ]]; then
      key_file="$default_resend_key_file"
   else
      key_file="$default_sendgrid_key_file"
   fi
fi

# Check key file validity
if [[ ! -f "$key_file" ]]; then
   echo "API key file \"$key_file\" does not exist"
   exit 1
fi

if [[ "$(stat -c "%a" "$key_file")" != "400" ]]; then
   echo "Unsafe API key file permissions (should be 400)"
   exit 1
fi

if [[ "$(wc -l < "$key_file")" != "1" ]]; then
   echo "Wrong API key format (file must contain exactly one line)"
   exit 1
fi

api_key="$(cat "$key_file")"

# Dispatch to appropriate send function
if [[ "$provider" == "resend" ]]; then
   send_email_resend
else
   send_email_sendgrid
fi

