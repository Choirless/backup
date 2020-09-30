const couchbackup = require('@cloudant/couchbackup')
const AWS = require('ibm-cos-sdk')
const stream = require('stream')

const main = async function (args) {
  // combine bare URL with source database
  if (!args.CLOUDANT_URL || !args.CLOUDANT_DB) {
    return Promise.reject(new Error('missing Cloudant config'))
  }
  const fullURL = args.CLOUDANT_URL + '/' + args.CLOUDANT_DB

  // COS config
  if (!args.COS_ENDPOINT || !args.COS_API_KEY || !args.COS_SERVICE_INSTANCE_ID || !args.COS_BUCKET) {
    return Promise.reject(new Error('missing COS config'))
  }
  const COSConfig = {
    endpoint: args.COS_ENDPOINT,
    apiKeyId: args.COS_API_KEY,
    ibmAuthEndpoint: 'https://iam.ng.bluemix.net/oidc/token',
    serviceInstanceId: args.COS_SERVICE_INSTANCE_ID
  }
  const cos = new AWS.S3(COSConfig)
  const streamToUpload = new stream.PassThrough({ highWaterMark: 67108864 })
  const key = `${args.CLOUDANT_DB}_${new Date().toISOString()}_backup.txt`
  const bucket = args.COS_BUCKET
  const uploadParams = {
    Bucket: args.COS_BUCKET,
    Key: key,
    Body: streamToUpload
  }
  console.log(`Backing up DB ${fullURL} to ${bucket}/${key}`)

  // return a Promise as this make take some time
  return new Promise((resolve, reject) => {
    // create a COS upload operation hanging on a stream of data
    cos.upload(uploadParams, function (err, data) {
      if (err) {
        return reject(new Error('could not write to COS'))
      }
      console.log('COS upload done')
      resolve(data)
    })

    // then kick off a backup writing to that stream
    couchbackup.backup(fullURL, streamToUpload, { iamApiKey: args.CLOUDANT_IAM_KEY },
      function (err, data) {
        if (err) {
          return reject(err)
        }
        console.log('couchbackup done')
      }
    )
  })
}

module.exports = {
  main
}
