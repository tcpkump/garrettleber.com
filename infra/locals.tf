locals {
  primary_site_domain        = "garrettleber.com"
  primary_site_domain_dashed = replace(local.primary_site_domain, ".", "-")
  additional_site_domains    = []
  domains                    = concat([local.primary_site_domain], local.additional_site_domains)

  s3_origin_id = "S3-${local.primary_site_domain}"
}
