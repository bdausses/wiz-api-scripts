#!/bin/bash

############
# This script is an example to download the Wiz Audit Logs
#
# requires 'bash, 'jq' and 'curl'
#
# The following Service Account credentials need to be set as environment variables:
#
#   SERVICE_ACCOUNT_CLIENT_ID
#   SERVICE_ACCOUNT_CLIENT_SECRET
#   WIZ_API_ENDPOINT
#     Example:  export WIZ_API_ENDPOINT="https://api.us20.app.wiz.io/graphql"
#
# Additionally, the "Set Variables block" can be changed to suit your needs.  In a production
#   version of this script, this script should be modified so that these variables can be
#   passed in via command line options.
############

# Set Variables
EXPORT_EVENTS_AFTER=2023-04-23
EXPORT_EVENTS_LIMIT=10000

# Get auth token
API_TOKEN=$(curl -s -X POST https://auth.app.wiz.io/oauth/token \
-H "Content-Type: application/x-www-form-urlencoded" \
-H "encoding: UTF-8" \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_id='"${SERVICE_ACCOUNT_CLIENT_ID}" \
--data-urlencode 'client_secret='"${SERVICE_ACCOUNT_CLIENT_SECRET}" \
--data-urlencode 'audience=wiz-api' | jq -r '.access_token')

# Set query variables
QUERY_VARS=$(cat <<EOF
{"filterBy":{"timestamp":{"after":"${EXPORT_EVENTS_AFTER}T00:00:00.000Z"},"user":[]},"limit":${EXPORT_EVENTS_LIMIT}}
EOF
)

# Define report listing function
function callAPI {
    curl -s -X POST $WIZ_API_ENDPOINT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -d '{
    "variables": '"$QUERY_VARS"',
    "query": "query AuditLogTableTableExport($filterBy: AuditLogEntryFilters, $limit: Int!) { export: auditLogEntries(filterBy: $filterBy) { exportUrl(limit: $limit) }}"}'
}

# Get report URL
RESULT=$(callAPI)
REPORT_URL=`echo $RESULT|jq --raw-output '.data.export.exportUrl'`

# Download report
echo "Exporting events after:  $EXPORT_EVENTS_AFTER"
echo "Report limited to $EXPORT_EVENTS_LIMIT events."
echo "Downloading Audit Log... "
echo

REPORT_FILENAME=WizAuditLog-EventsAfter$EXPORT_EVENTS_AFTER.csv
wget -q -O $REPORT_FILENAME $REPORT_URL

echo "Download complete.  Your file has been saved as:"
echo "$REPORT_FILENAME"
echo
