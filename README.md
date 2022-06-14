Example workflow file [playwright-github-pages](https://github.com/PavanMudigonda/playwright-html-reporter-s3-website/blob/main/.github/workflows/main.yml))

# Playwright HTML Test Results on AWS S3 Bucket with history action

## Usage

### `main.yml` Example

Place in a `.yml` file such as this one in your `.github/workflows` folder. [Refer to the documentation on workflow YAML syntax here.](https://help.github.com/en/articles/workflow-syntax-for-github-actions)

As of v0.2, all [`aws s3 sync` flags](https://docs.aws.amazon.com/cli/latest/reference/s3/sync.html) are optional to allow for maximum customizability (that's a word, I promise) and must be provided by you via `args:`.

#### The following example includes optimal defaults for a public static website:

- `--acl public-read` makes your files publicly readable (make sure your [bucket settings are also set to public](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteAccessPermissionsReqd.html)).
- `--follow-symlinks` won't hurt and fixes some weird symbolic link problems that may come up.
- Most importantly, `--delete` **permanently deletes** files in the S3 bucket that are **not** present in the latest version of your repository/build.
- **Optional tip:** If you're uploading the root of your repository, adding `--exclude '.git/*'` prevents your `.git` folder from syncing, which would expose your source code history if your project is closed-source. (To exclude more than one pattern, you must have one `--exclude` flag per exclusion. The single quotes are also important!)

```yaml
name: test-results

on:
  push:
    branches:
    - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name:  Upload Playwright Test Results History to S3
        uses: PavanMudigonda/playwright-html-reporter-s3-website@v0.2
        id: aws_s3_test_results_upload
        with:
          report_url: http://${{ secrets.AWS_S3_BUCKET }}.s3-website-${{ env.AWS_REGION }}.amazonaws.com
          playwright_results: test-results 
          playwright_history: playwright-history
          keep_reports: 20
          args: --acl public-read --follow-symlinks. # for public enabling use acl public-read # Please remove if its private bucket
        env:
          AWS_S3_BUCKET: ${{ secrets.AWS_S3_BUCKET }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION: 'us-east-1'   # optional: defaults to us-east-1
          SOURCE_DIR: 'playwright-history'      # optional: defaults to entire repository
          # DEST_DIR: ${{ env.GITHUB_RUN_NUMBER }}
```


### Configuration

The following settings must be passed as environment variables as shown in the example. Sensitive information, especially `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, should be [set as encrypted secrets](https://help.github.com/en/articles/virtual-environments-for-github-actions#creating-and-using-secrets-encrypted-variables) — otherwise, they'll be public to anyone browsing your repository's source code and CI logs.

| Key | Value | Suggested Type | Required | Default |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key. [More info here.](https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html) | `secret env` | **Yes** | N/A |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key. [More info here.](https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html) | `secret env` | **Yes** | N/A |
| `AWS_S3_BUCKET` | The name of the bucket you're syncing to. For example, `jarv.is` or `my-app-releases`. | `secret env` | **Yes** | N/A |
| `AWS_REGION` | The region where you created your bucket. Set to `us-east-1` by default. [Full list of regions here.](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions) | `env` | No | `us-east-1` |
| `AWS_S3_ENDPOINT` | The endpoint URL of the bucket you're syncing to. Can be used for [VPC scenarios](https://aws.amazon.com/blogs/aws/new-vpc-endpoint-for-amazon-s3/) or for non-AWS services using the S3 API, like [DigitalOcean Spaces](https://www.digitalocean.com/community/tools/adapting-an-existing-aws-s3-application-to-digitalocean-spaces). | `env` | No | Automatic (`s3.amazonaws.com` or AWS's region-specific equivalent) |
| `SOURCE_DIR` | The local directory (or file) you wish to sync/upload to S3. For example, `public`. Defaults to your entire repository. | `env` | No | `./` (root of cloned repository) |
| `DEST_DIR` | The directory inside of the S3 bucket you wish to sync/upload to. For example, `my_project/assets`. Defaults to the root of the bucket. | `env` | No | `/` (root of bucket) |

### AWS S3 Bucket folder structure sample:- Organized by Github Run Number

![image](https://user-images.githubusercontent.com/29324338/173656755-d47f949b-b11b-45fe-ae94-951751104397.png)

### AWS S3 Static Website Sample:- Full Report, Errors, Screenshots, Trace, Video is fully visible !

![image](https://user-images.githubusercontent.com/29324338/173658258-88247b45-c2f5-46d7-b2a0-12faaae72b52.png)

![image](https://user-images.githubusercontent.com/29324338/173658415-49b56fb9-d317-49db-8e0e-e3b6e8196c0a.png)

![image](https://user-images.githubusercontent.com/29324338/173658484-1121d0c2-2df4-4bf1-b2d0-a37f6f77c0d5.png)

![image](https://user-images.githubusercontent.com/29324338/173658512-23658238-2c47-407f-8c30-869812629228.png)


## License

This project is distributed under the [MIT license](LICENSE.md).
