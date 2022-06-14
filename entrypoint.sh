#! /usr/bin/env bash
mkdir -p ./${INPUT_PLAYWRIGHT_HISTORY}

if [[ ${INPUT_REPORT_URL} != '' ]]; then
    S3_WEBSITE_URL="${INPUT_REPORT_URL}"
fi

#echo "index.html"
echo "<!DOCTYPE html><meta charset=\"utf-8\"><meta http-equiv=\"refresh\" content=\"0; URL=${S3_WEBSITE_URL}/${INPUT_GITHUB_RUN_NUM}/\">" > ./${INPUT_PLAYWRIGHT_HISTORY}/index.html # path
echo "<meta http-equiv=\"Pragma\" content=\"no-cache\"><meta http-equiv=\"Expires\" content=\"0\">" >> ./${INPUT_PLAYWRIGHT_HISTORY}/index.html
cat ./${INPUT_PLAYWRIGHT_HISTORY}/index.html

echo "copy playwright-results to ${INPUT_PLAYWRIGHT_HISTORY}/${INPUT_GITHUB_RUN_NUM}"
cp -R ./${INPUT_PLAYWRIGHT_RESULTS}/. ./${INPUT_PLAYWRIGHT_HISTORY}/${INPUT_GITHUB_RUN_NUM}

set -e

if [ -z "$AWS_S3_BUCKET" ]; then
  echo "AWS_S3_BUCKET is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY is not set. Quitting."
  exit 1
fi

# Default to us-east-1 if AWS_REGION not set.
if [ -z "$AWS_REGION" ]; then
  AWS_REGION="us-east-1"
fi

# Override default AWS endpoint if user sets AWS_S3_ENDPOINT.
if [ -n "$AWS_S3_ENDPOINT" ]; then
  ENDPOINT_APPEND="--endpoint-url $AWS_S3_ENDPOINT"
fi

# Create a dedicated profile for this action to avoid conflicts
# with past/future actions.
# https://github.com/jakejarvis/s3-sync-action/issues/1
aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

# Sync using our dedicated profile and suppress verbose messages.
# All other flags are optional via the `args:` directive.
sh -c "aws s3 sync ${SOURCE_DIR:-.} s3://${AWS_S3_BUCKET}/${DEST_DIR} \
              --profile s3-sync-action \
              --no-progress \
              ${ENDPOINT_APPEND} $*"


# Delete history
COUNT=$( sh -c "aws s3 ls s3://${AWS_S3_BUCKET}" | sort -n | grep "PRE" | wc -l )
echo "count folders in playwright-history: ${COUNT}"
echo "keep reports count ${INPUT_KEEP_REPORTS}"
INPUT_KEEP_REPORTS=$((INPUT_KEEP_REPORTS+1))
echo "if ${COUNT} > ${INPUT_KEEP_REPORTS}"
if (( COUNT > INPUT_KEEP_REPORTS )); then
  NUMBER_OF_FOLDERS_TO_DELETE=$((${COUNT}-${INPUT_KEEP_REPORTS}))
  echo "remove old reports"
  echo "number of folders to delete ${NUMBER_OF_FOLDERS_TO_DELETE}"
  sh -c "aws s3 ls s3://${AWS_S3_BUCKET}" |  grep "PRE" | sed 's/PRE //' | sed 's/.$//' | head -n ${NUMBER_OF_FOLDERS_TO_DELETE} | sort -n | while read -r line;
    do
      sh -c "aws s3 rm s3://${AWS_S3_BUCKET}/${line}/ --recursive";
      echo "deleted prefix folder : ${line}";
    done;
fi

# Clear out credentials after we're done.
# We need to re-run `aws configure` with bogus input instead of
# deleting ~/.aws in case there are other credentials living there.
# https://forums.aws.amazon.com/thread.jspa?threadID=148833
aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
null
null
null
text
EOF
