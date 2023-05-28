output "api_gateway_url" {
  value = join("", [
    aws_api_gateway_deployment.visitors_app_api_gateway_deploy.invoke_url,
    "/",
    aws_api_gateway_resource.visitors_app_proxy.path_part
  ])
}

output "website_bucket_name" {
  value = aws_s3_bucket.website_bucket.id
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.main.id
}
