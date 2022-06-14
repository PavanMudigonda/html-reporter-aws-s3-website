#! /usr/bin/env bash

if [[ ${INPUT_REPORT_URL} != '' ]]; then
    S3_WEBSITE_URL="${INPUT_REPORT_URL}"
fi

#echo "index.html"
echo "<!DOCTYPE html><meta charset=\"utf-8\"><meta http-equiv=\"refresh\" content=\"0; URL=${S3_WEBSITE_URL}/${INPUT_GITHUB_RUN_NUM}/\">" > ./${INPUT_PLAYWRIGHT_HISTORY}/index.html # path
echo "<meta http-equiv=\"Pragma\" content=\"no-cache\"><meta http-equiv=\"Expires\" content=\"0\">" >> ./${INPUT_PLAYWRIGHT_HISTORY}/index.html
cat ./${INPUT_PLAYWRIGHT_HISTORY}/index.html

echo "copy playwright-results to ${INPUT_PLAYWRIGHT_HISTORY}/${INPUT_GITHUB_RUN_NUM}"
cp -R ./${INPUT_PLAYWRIGHT_RESULTS}/. ./${INPUT_PLAYWRIGHT_HISTORY}/${INPUT_GITHUB_RUN_NUM}