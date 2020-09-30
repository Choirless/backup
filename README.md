# Choirless backup

This is a serverless action that backs up a single Cloudant database to Cloud Object Storage.

It can be used as follows:

```js
const opts = {
  CLOUDANT_IAM_KEY: '<cloudant iam key>',  // e.g. 'abc123'
  CLOUDANT_URL: '<cloudant url>', // e.g 'https://myservice.cloudantnosqldb.appdomain.cloud'
  CLOUDANT_DB: '<cloudant database name>', // e.g. 'mydata'
  COS_API_KEY: '<cos_api_key>', // e.g. 'xyz456'
  COS_ENDPOINT: '<cos_endpoint>', // e.g. 's3.private.eu-gb.cloud-object-storage.appdomain.cloud',
  COS_SERVICE_INSTANCE_ID: '<cos_service_instance_id>', // e.g. 'crn:v:w:x:y:z::'
  COS_BUCKET: '<cos_bucket>' // e.g. 'mybucket'
}
const main = require('./index.js').main
main(opts).then(console.log).catch(console.error)
```

## Deploying to IBM Cloud Functions

First we create a Docker image that contains the Node.js dependencies of this project (replace 'glynnbird' with your DockerHub username):

```sh
# build a docker image
docker build -t glynnbird/choirless_backup .

# push it to docker hub
docker push glynnbird/choirless_backup:latest
```

Then we can create an IBM Cloud Function based on this custom image

```sh
ibmcloud fn action update choirless/backup --docker glynnbird/choirless_backup:latest index.js
```

## Running in Cloud Functions

A one-off invocation of the backup can set off from the command-line:

```sh
ibmcloud fn action invoke choirless/backup --result --param-file opts.json 
```

where `opts.json` contains the Cloudant and COS config in JSON format.

## Running backup periodically

to do