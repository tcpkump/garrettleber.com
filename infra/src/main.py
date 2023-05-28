from decimal import Decimal
import boto3


def lambda_handler(event, context):
    dynamodbclient = boto3.resource('dynamodb')
    table = dynamodbclient.Table("garrettleber-com-visitors-app-table")
    response = table.update_item(
        Key={
            'website': 'garrettleber.com'
        },
        UpdateExpression="ADD hits :val1",
        ExpressionAttributeValues={
            ':val1': Decimal(1)
        },
        ReturnValues="UPDATED_NEW"
    )
    hitcount = response['Attributes']['hits']

    return {
        "isBase64Encoded": "false",
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Credentials": "true"
        },
        "body": hitcount
    }
