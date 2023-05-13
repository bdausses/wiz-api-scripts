#!/bin/bash

############
# This script is an example to get IDs of Projects.
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
#   NOTE:  In this example, I am searching for a Project named BDausses-Accounts.  You 
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
{"first":20,"filterBy":{"search":"BDausses-Accounts"},"orderBy":{"field":"SECURITY_SCORE","direction":"ASC"},"analyticsSelection":{}}
EOF
)

function callAPI {
    curl -s -X POST https://api.us20.app.wiz.io/graphql \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -d '{
    "variables": '"$QUERY_VARS"',
    "query": "query ProjectsTable($filterBy: ProjectFilters, $first: Int, $after: String, $orderBy: ProjectOrder, $analyticsSelection: ProjectIssueAnalyticsSelection) { projects(filterBy: $filterBy, first: $first, after: $after, orderBy: $orderBy) { nodes { id name slug cloudAccountCount repositoryCount kubernetesClusterCount containerRegistryCount securityScore archived businessUnit description riskProfile { businessImpact } issueAnalytics(selection: $analyticsSelection) { issueCount scopeSize informationalSeverityCount lowSeverityCount mediumSeverityCount highSeverityCount criticalSeverityCount } } pageInfo { hasNextPage endCursor } totalCount LBICount MBICount HBICount }}"}'
}

RESULT=$(callAPI)
echo "${RESULT}" | jq . # your data is here!
