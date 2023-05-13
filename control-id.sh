#!/bin/bash

############
# This script is an example to get IDs of Controls.
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
#   NOTE:  In this example, I am searching for a control with string "BDausses".  You 
#          will want to change this to whatever it is that you are searching for.
#
############

# Get auth token
API_TOKEN=$(curl -s -X POST https://auth.app.wiz.io/oauth/token \
-H "Content-Type: application/x-www-form-urlencoded" \
-H "encoding: UTF-8" \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_id='"${SERVICE_ACCOUNT_CLIENT_ID}" \
--data-urlencode 'client_secret='"${SERVICE_ACCOUNT_CLIENT_SECRET}" \
--data-urlencode 'audience=wiz-api' | jq -r '.access_token')

QUERY_VARS=$(cat <<EOF
{"first":30,"orderBy":{"field":"SEVERITY","direction":"DESC"},"filterBy":{"search":"BDausses"}}
EOF
)

function callAPI {
    curl -s -X POST https://api.us20.app.wiz.io/graphql \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -d '{
    "variables": '"$QUERY_VARS"',
    "query": "query controlsTable($first: Int = 500, $after: String, $filterBy: ControlFilters, $orderBy: ControlOrder, $issueAnalyticsSelection: ControlIssueAnalyticsSelection) { controls(filterBy: $filterBy, first: $first, after: $after, orderBy: $orderBy) { nodes { id name description type severity query enabled lastRunAt lastSuccessfulRunAt lastRunError supportsNRT originalControlOverridden serviceTickets { ...ControlServiceTicket } scopeProject { id name } sourceCloudConfigurationRule { id name } securitySubCategories { id title description category { id name framework { id name enabled } } } enabledForLBI enabledForMBI enabledForHBI enabledForUnattributed createdBy { id name email } issueAnalytics(selection: $issueAnalyticsSelection) { issueCount } } pageInfo { hasNextPage endCursor } totalCount }} fragment ControlServiceTicket on ServiceTicket { id externalId name url project { id name } action { id name } integration { id type name }}"}'
}

RESULT=$(callAPI)
echo "${RESULT}" | jq . # your data is here!
