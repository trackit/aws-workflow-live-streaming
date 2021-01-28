variable "region" {
  description = "AWS region."
  default     = "us-west-2"
}

variable "project_base_name" {
  description = "Project name."
  default     = "workflow-live"
}

variable "lambda_zip_path" {
  description = "Path to lambda zip file."
  default     = "./medialive_module/api.zip"
}

variable "dynamodb_table_name" {
  description = "Db table name for MediaLive API storage."
  default     = "MedialiveApiStorage"
}

variable "archive_bucket_name" {
  description = "Archive bucket to record lives in."
  default     = "live_archive_bucket"
}

variable "using_cloudfront" {
  description = "Boolean to set to true if using AWS Cloudfront."
  default = false
  type = bool
}

variable "acm_certificate" {
  description = "In case of using AWS Cloudfront, please set ACM certificate."
  default = "0"
  type = string
}

variable "cloudfront_live_domain" {
  description = "In case of using AWS Cloudfront, please set Cloudfront live domain"
  default = "0"
  type = string
}

variable "route_53_id" {
  description = "In case of using AWS Cloudfront, please set the Route53 id."
  default = "0"
  type = string
}
