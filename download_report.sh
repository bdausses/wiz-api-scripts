#!/bin/bash

############
# requires 'bash, 'jq' and 'curl'
# The following Service Account credentials need to be set as environment variables:
#
#   SERVICE_ACCOUNT_CLIENT_ID
#   SERVICE_ACCOUNT_CLIENT_SECRET
#   WIZ_API_ENDPOINT
#     Example:  export WIZ_API_ENDPOINT="https://api.us20.app.wiz.io/graphql"
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

# Set query variables
QUERY_VARS=$(cat <<EOF
{"first":20,"filterBy":{"search":"TEST_REPORT_NAME"}}
EOF
)

# Define functions
function callAPI {
    curl -s -X POST $WIZ_API_ENDPOINT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -d '{
    "variables": '"$QUERY_VARS"',
    "query": "query ReportsTable($filterBy: ReportFilters, $first: Int, $after: String) { reports(first: $first, after: $after, filterBy: $filterBy) { nodes { id name type { id name } project { id name } emailTarget { to } parameters { query framework { name } subscriptions { ...ReportParamsEntity } entities { ...ReportParamsEntity } } params { ...ReportParams } lastRun { ...LastRunDetails } nextRunAt runIntervalHours } pageInfo { hasNextPage endCursor } totalCount }} fragment ReportParamsEntity on GraphEntity { id type name properties technologies { id name icon }} fragment ReportParams on ReportParams { ... on ReportParamsCloudResource { entityType subscriptionId } ... on ReportParamsComplianceAssessments { frameworks { ...ReportParamsFramework } subscriptions { ...ReportParamsEntity } } ... on ReportParamsComplianceExecutiveSummary { framework { ...ReportParamsFramework } subscriptions { ...ReportParamsEntity } } ... on ReportParamsConfigurationFindings { subscriptions { ...ReportParamsEntity } entities { ...ReportParamsEntity } } ... on ReportParamsGraphQuery { query } ... on ReportParamsHostConfiguration { hostConfigurationRuleAssessmentsFilters } ... on ReportParamsIssue { issueFilters } ... on ReportParamsNetworkExposure { __typename entities { ...ReportParamsEntity } subscriptions { ...ReportParamsEntity } } ... on ReportParamsSecurityFramework { entities { ...ReportParamsEntity } subscriptions { ...ReportParamsEntity } } ... on ReportParamsVulnerabilities { type assetType filters }} fragment ReportParamsFramework on SecurityFramework { id name} fragment LastRunDetails on ReportRun { id status failedReason runAt progress results { ... on ReportRunResultsBenchmark { errorCount passedCount failedCount scannedCount } ... on ReportRunResultsGraphQuery { resultCount entityCount } ... on ReportRunResultsNetworkExposure { scannedCount publiclyAccessibleCount } ... on ReportRunResultsConfigurationFindings { findingsCount } ... on ReportRunResultsVulnerabilities { count } ... on ReportRunResultsIssues { count } ... on ReportRunResultsCloudResource { count limitReached } }}"}'
}

# Get reports list
RESULT=$(callAPI)

REPORT_ID=`echo $RESULT|jq --raw-output '.data.reports.nodes[0].id'`
REPORT_NAME=`echo $RESULT|jq --raw-output '.data.reports.nodes[0].name'`
REPORT_LAST_RUN=`echo $RESULT|jq --raw-output '.data.reports.nodes[0].lastRun.runAt'`

# Set query variables
QUERY_VARS=$(cat <<EOF
{"reportId":"${REPORT_ID}"}
EOF
)

# Define functions
function callAPI {
    curl -s -X POST $WIZ_API_ENDPOINT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -d '{
    "variables": '"$QUERY_VARS"',
    "query": "query ReportDownloadUrl($reportId: ID!) { report(id: $reportId) { lastRun { url } }}"}'
}

# Get report URL
RESULT=$(callAPI)
REPORT_URL=`echo $RESULT|jq --raw-output '.data.report.lastRun.url'`

# Download report
echo "Downloading... "
echo "Report ID:    $REPORT_ID"
echo "Report Name:  $REPORT_NAME"
echo "Report Date:  $REPORT_LAST_RUN"
echo

REPORT_FILENAME=$REPORT_NAME-$REPORT_LAST_RUN.csv
wget -q -O $REPORT_FILENAME $REPORT_URL

echo "Download complete.  Your file has been saved as:"
echo "$REPORT_FILENAME"
echo