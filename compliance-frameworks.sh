#!/bin/bash

############
# This script is an example to download a compliance detail report.
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
#   Note:  The service account for this script requires the Wiz API permission:
#          Reports -> read:reports
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
{"first":500,"filterBy":{}}
EOF
)

function callAPI {
    curl -s -X POST https://api.us20.app.wiz.io/graphql \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -d '{
    "variables": '"$QUERY_VARS"',
    "query": "query SecurityFrameworksTable($first: Int, $after: String, $filterBy: SecurityFrameworkFilters) { securityFrameworks(first: $first, after: $after, filterBy: $filterBy) { nodes { policyTypes ...SecurityFrameworkFragment } nodesWithEnabledRulesCount: nodes { id enabledCloudConfigurationRules: cloudConfigurationRules( filterBy: {enabled: true} ) { totalCount } enabledHostConfigurationRules: hostConfigurationRules(filterBy: {enabled: true}) { totalCount } } pageInfo { hasNextPage endCursor } totalCount }} fragment SecurityFrameworkFragment on SecurityFramework { id name description builtin enabled cloudConfigurationRules { totalCount } hostConfigurationRules { totalCount } controls { totalCount enabledCount } categories { id name description subCategories { id title description } }}"}'
}

RESULT=$(callAPI)
echo "${RESULT}" | jq --raw-output '.data.securityFrameworks.nodes[]'


# If paginating on a Graph Query, then use <'quick': false> in the query variables.
# Uncomment the following section to paginate over all the results:
# while true; do
#     PAGE_INFO=$(echo "${RESULT}" | jq -r '.data | .securityFrameworks | .pageInfo')
#     HAS_NEXT_PAGE=$(echo "${PAGE_INFO}" | jq -r '.hasNextPage')
#     if [ "$HAS_NEXT_PAGE" = true ]; then
#         END_CURSOR=$(echo "${PAGE_INFO}" | jq -r '.endCursor')
#         QUERY_VARS=$(echo "$QUERY_VARS" | jq --arg foo "$END_CURSOR" '. + {after: $foo}')
#     else
#         break
#     fi
#     RESULT=$(callAPI)
#     echo "${RESULT}"
#  done
