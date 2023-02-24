#!/bin/bash

# same as deploy_cr.sh
NAME=ingest-whoop-daily

PROJECT_ID=$(gcloud config get-value project)
BUCKET=${PROJECT_ID}-cf-staging

URL=$(gcloud run services describe ingest-whoop-daily --format 'value(status.url)')
echo $URL

curl -k -X POST $URL \
   -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
   -H "Content-Type:application/json" --data-binary @/tmp/message