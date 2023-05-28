resource "aws_s3_bucket" "website_bucket" {
  bucket = local.primary_site_domain

  lifecycle {
    ignore_changes = [
      website
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "website_bucket" {
  bucket                  = aws_s3_bucket.website_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Sid : "PublicReadGetObject"
        Effect : "Allow"
        Principal : "*"
        Action : "s3:GetObject"
        Resource : [
          aws_s3_bucket.website_bucket.arn,
          "${aws_s3_bucket.website_bucket.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }

}

resource "aws_acm_certificate" "website_certificate" {
  domain_name               = local.primary_site_domain
  validation_method         = "DNS"
  subject_alternative_names = concat(local.additional_site_domains, [for domain in local.domains : "www.${domain}"])
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  aliases             = concat(local.domains, [for domain in local.domains : "www.${domain}"])
  default_root_object = "index.html"
  is_ipv6_enabled     = true

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    default_ttl            = 3600
    max_ttl                = 86400
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket_website_configuration.website_bucket.website_endpoint
    origin_id   = local.s3_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.website_certificate.arn
    minimum_protocol_version = "TLSv1.2_2019"
    ssl_support_method       = "sni-only"
  }
}

data "aws_route53_zone" "site_zones" {
  for_each = toset(local.domains)
  name     = each.value
}

resource "aws_route53_record" "site_records" {
  for_each = toset(local.domains)
  zone_id  = data.aws_route53_zone.site_zones[each.key].zone_id
  name     = each.key
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_www_records" {
  for_each = toset(local.domains)
  zone_id  = data.aws_route53_zone.site_zones[each.key].zone_id
  name     = "www.${each.key}"
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
