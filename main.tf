terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = ">= 2.11"
  region  = var.region
}

# Save the terraform state for medialive module in a S3 bucket
# terraform {
#   backend "s3" {
#     bucket = "bucket_name"
#     key    = "medialive.tfstate"
#     region = "us-west-2"
#   }
# }

data "aws_caller_identity" "current" {}

resource "aws_dynamodb_table" "medialive-api-storage" {
  name           = var.dynamodb_table_name
  hash_key       = "id"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "id"
    type = "S"
  }
}


resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project_base_name}-medialive-api"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.api_integration_post_streams,
    aws_api_gateway_integration.api_integration_get_streams,
    aws_api_gateway_integration.api_integration_post_streams_start,
    aws_api_gateway_integration.api_integration_post_streams_stop,
    aws_api_gateway_integration.api_integration_post_stream_split,
    aws_api_gateway_integration.api_integration_post_stream_live,
    aws_api_gateway_integration.api_integration_delete_stream_live,
    aws_api_gateway_integration.api_integration_get_stream_id,
    aws_api_gateway_integration.api_integration_post_stream_id,
    aws_api_gateway_integration.api_integration_delete_stream_id
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"
  description = "Default stage deployment for MediaLive API"
}

output "apigateway_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}
