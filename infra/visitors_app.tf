resource "aws_iam_role_policy" "visitorsapp_lambda_policy" {
  name = "${local.primary_site_domain_dashed}-visitorsapp-lambda-policy"
  role = aws_iam_role.visitorsapp_lambda_role.id

  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Action : "dynamodb:UpdateItem"
        Effect : "Allow"
        Sid : ""
        Resource : "${aws_dynamodb_table.visitors_app_table.arn}"
      },
    ]
  })
}

resource "aws_iam_role" "visitorsapp_lambda_role" {
  name = "${local.primary_site_domain_dashed}-visitorsapp-lambda-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Action : "sts:AssumeRole"
        Effect : "Allow"
        Sid : ""
        Principal : {
          "Service" : "lambda.amazonaws.com"
        }
      },
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "src/main.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "visitorsapp" {
  function_name = "${local.primary_site_domain_dashed}-visitorsapp"
  role          = aws_iam_role.visitorsapp_lambda_role.arn
  handler       = "main.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256
  filename         = data.archive_file.lambda.output_path

  runtime = "python3.8"
  depends_on = [
    aws_dynamodb_table.visitors_app_table,
  ]

  environment {
    variables = {
      VISITORS_TABLE = aws_dynamodb_table.visitors_app_table.name
    }
  }
}

resource "aws_api_gateway_rest_api" "visitors_rest_api" {
  name        = "${local.primary_site_domain_dashed}-visitors-rest-api"
  description = "REST API for visitor count"
}

resource "aws_api_gateway_resource" "visitors_app_proxy" {
  rest_api_id = aws_api_gateway_rest_api.visitors_rest_api.id
  parent_id   = aws_api_gateway_rest_api.visitors_rest_api.root_resource_id
  path_part   = "getcount"
}

resource "aws_api_gateway_method" "visitors_gateway_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.visitors_rest_api.id
  resource_id   = aws_api_gateway_resource.visitors_app_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "visitors_app_lambda" {
  rest_api_id = aws_api_gateway_rest_api.visitors_rest_api.id
  resource_id = aws_api_gateway_method.visitors_gateway_proxy.resource_id
  http_method = aws_api_gateway_method.visitors_gateway_proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.visitorsapp.invoke_arn
}

resource "aws_api_gateway_deployment" "visitors_app_api_gateway_deploy" {
  depends_on = [
    aws_api_gateway_integration.visitors_app_lambda
  ]

  rest_api_id = aws_api_gateway_rest_api.visitors_rest_api.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "visitors_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitorsapp.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.visitors_rest_api.execution_arn}/*/*"
}


resource "aws_dynamodb_table" "visitors_app_table" {
  name           = "${local.primary_site_domain_dashed}-visitors-app-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "website"

  attribute {
    name = "website"
    type = "S"
  }

  tags = {
    Name        = "${local.primary_site_domain_dashed}-visitors-app-table"
    Environment = "production"
  }
}
