# Vegeta load testing demo

## Test target

First of all we need something to test. Let's create an AWS Lambda function. You can use any HTTP enabled service.

### Create lambda

Steps to create lambda:
- open AWS console
- go to lambda functions
- create new function
- use `microservice-http-endpoint` blueprint
- use API key security

### Change lambda code

If you don't plan to use real storage (like DynamoDb configured by default in a blueprint) you can just return predefined responses different actions:

```
switch (event.httpMethod) {
    case 'DELETE':
        //dynamo.deleteItem(JSON.parse(event.body), done);
        done(null, { deleted: 1 })
        break;
    case 'GET':
        //dynamo.scan({ TableName: event.queryStringParameters.TableName }, done);
        done(null, { name: event.queryStringParameters.TableName, data: "42" })
        break;
    case 'POST':
        //dynamo.putItem(JSON.parse(event.body), done);
        done(null, { created: JSON.parse(event.body) })
        break;
    case 'PUT':
        //dynamo.updateItem(JSON.parse(event.body), done);
        done(null, { updated: JSON.parse(event.body) })
        break;
    default:
        done(new Error(`Unsupported method "${event.httpMethod}"`));
}
```

### Test lambda

Use any REST client to test your API:
- you can find API uri clicking on `API Gateway` node in lambda functions designer
- put your API key into `x-api-key` header

Reference clients to use: [Advanced Rest Client](https://install.advancedrestclient.com/install); [Postman](https://www.getpostman.com/)

## Creating tests

### Install Vegeta

You can find [installation instructions](https://github.com/tsenart/vegeta#install) in the tool repository

### Targets file

While you could run tests manually setting destination it is very convinient to manage a targets file. You can control it with your version control and add new endpoints.

Vegeta repository has the [schema](https://github.com/tsenart/vegeta/blob/master/lib/target.schema.json) for tragets file.

Check out the sample targets file in the demo repository:

```
{"method":"GET", "url":"https://<lambda-uri-here>.amazonaws.com/default/vegeta-demo-test?TableName=test", "header": {"Accept": ["application/json"], "x-api-key": ["<api-key-here>"] }}
{"method":"POST", "url":"https://<lambda-uri-here>.amazonaws.com/default/vegeta-demo-test", "body": "eyAibXktb2JqZWN0IjogImE4OTRkODQ0LWNlYTMtNGZmNC1iNTc4LWVhOWJjY2NhZmE3ZCJ9", "header": {"Accept": ["application/json"], "x-api-key": ["<api-key-here>"] }}{"method":"POST","url":"https://<lambda-uri-here>.amazonaws.com/default/vegeta-demo-test","body":"eyAibXktb2JqZWN0IjogImE4OTRkODQ0LWNlYTMtNGZmNC1iNTc4LWVhOWJjY2NhZmE3ZCJ9","header":{"Accept":["application/json"],"x-api-key":["<api-key-here>"]}}
{"method":"PUT","url":"https://<lambda-uri-here>.amazonaws.com/default/vegeta-demo-test","body":"eyAibXktb2JqZWN0IjogImE4OTRkODQ0LWNlYTMtNGZmNC1iNTc4LWVhOWJjY2NhZmE3ZCJ9","header":{"Accept":["application/json"],"x-api-key":["<api-key-here>"]}}
{"method":"DELETE","url":"https://<lambda-uri-here>.amazonaws.com/default/vegeta-demo-test","body":"eyAibXktb2JqZWN0IjogImE4OTRkODQ0LWNlYTMtNGZmNC1iNTc4LWVhOWJjY2NhZmE3ZCJ9","header":{"Accept":["application/json"],"x-api-key":["<api-key-here>"]}}
```

Note that request body must be in base64 format. You can use `jq` [tool](https://stedolan.github.io/jq/) to convert your JSON.

### Launcher script

We want to generate both graphs and text reports from a test run. Also we want to have a testrun timestamp in a filename.

Let's get the date in YYYYMMDDHHmmSS format and put in a variable:

`datestamp=$(date '+%Y%m%d%H%M%S')`

We use this format because it preserves the files order when soring by name.

Also we would need a directory for test results: `mkdir -p ./results`.

Run Vegeta from JSON file for 5s with max rps of 50, save results in binary format and generate html graph out of it:

`cat targets.json | ./vegeta attack -format="json" -duration=5s rate=50 | tee ./results/results-$datestamp.bin | ./vegeta plot > ./results/vegeta-plot-$datestamp.html`

And finally generate text report:

`cat ./results/results-$datestamp.bin | ./vegeta report > ./results/report-$datestamp.txt`