These are notes about how we set up object storage for storing reports CSV files, August, 2026.

### S3-compatible AWS credentials
* Create a new peony service developer account and request `object_storage` role ([T435414](https://phabricator.wikimedia.org/T435414)).
* Log in through Horizon using the new peony service developer account.
* Create new application credentials with /v3/users/peony-server/credentials/OS-EC2 access role and mark them as unrestricted.
* Use the new credentials to generate S3-compatible aws credentials bounded to the new peony service developer account.

### Container
* Create a new container called reports through Horizon.
* Grant anonymous GetObject access to that container, with no ListBucket access. This allows every user to download their report while preventing them from seeing all the existing reports.

### Set up ENV vars
* Use the container name and S3-compatible aws credentials to set the following env vars on the corresponding server.

```
# Credentials for storing CSV exports in S3-compatible object storage.
    report_csv_bucket: 'bucket-name'
    report_csv_s3_endpoint: 'https://object.eqiad1.wikimediacloud.org'
    report_csv_public_url: 'https://object.eqiad1.wikimediacloud.org/globaleducation:bucket-name'
    report_csv_access_key: 'access-key'
    report_csv_secret_key: 'secret-key'
```

Note that once you set the report_csv_bucket env var, reports will start being stored in the object storage container.
