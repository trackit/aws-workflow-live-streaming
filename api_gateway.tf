# /streams 
# GET & POST 

resource "aws_api_gateway_resource" "speke_server_api_resource_streams" {
  rest_api_id = aws_api_gateway_rest_api.speke_server_api.id
  parent_id   = aws_api_gateway_rest_api.speke_server_api.root_resource_id
  path_part   = "streams"
}

resource "aws_api_gateway_method" "speke_server_api_method_post_streams" {
  rest_api_id   = aws_api_gateway_rest_api.speke_server_api.id
  resource_id   = aws_api_gateway_resource.speke_server_api_resource_streams.id
  http_method   = "POST"
  authorization = "NONE"
}


resource "aws_api_gateway_integration" "speke_server_api_integration_post_streams" {
  rest_api_id             = aws_api_gateway_rest_api.speke_server_api.id
  resource_id             = aws_api_gateway_resource.speke_server_api_resource_streams.id
  http_method             = aws_api_gateway_method.speke_server_api_method_post_streams.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.medialive_create_stream.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method" "speke_server_api_method_get_streams" {
  rest_api_id   = aws_api_gateway_rest_api.speke_server_api.id
  resource_id   = aws_api_gateway_resource.speke_server_api_resource_streams.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "speke_server_api_integration_get_streams" {
  rest_api_id             = aws_api_gateway_rest_api.speke_server_api.id
  resource_id             = aws_api_gateway_resource.speke_server_api_resource_streams.id
  http_method             = aws_api_gateway_method.speke_server_api_method_get_streams.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.medialive_get_streams.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

# streams/{id}

resource "aws_api_gateway_resource" "speke_server_api_resource_id" {
  rest_api_id = aws_api_gateway_rest_api.speke_server_api.id
  parent_id   = aws_api_gateway_resource.speke_server_api_resource_streams.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "speke_server_api_resource_start" {
  rest_api_id = aws_api_gateway_rest_api.speke_server_api.id
  parent_id   = aws_api_gateway_resource.speke_server_api_resource_id.id
  path_part   = "start"
}

resource "aws_api_gateway_resource" "speke_server_api_resource_stop" {
  rest_api_id = aws_api_gateway_rest_api.speke_server_api.id
  parent_id   = aws_api_gateway_resource.speke_server_api_resource_id.id
  path_part   = "stop"
}



resource "aws_api_gateway_method" "speke_server_api_method_post_streams_start" {
  rest_api_id   = aws_api_gateway_rest_api.speke_server_api.id
  resource_id   = aws_api_gateway_resource.speke_server_api_resource_start.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "speke_server_api_integration_post_streams_start" {
  rest_api_id             = aws_api_gateway_rest_api.speke_server_api.id
  resource_id             = aws_api_gateway_resource.speke_server_api_resource_start.id
  http_method             = aws_api_gateway_method.speke_server_api_method_post_streams_start.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.medialive_start_stream.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method" "speke_server_api_method_post_streams_stop" {
  rest_api_id   = aws_api_gateway_rest_api.speke_server_api.id
  resource_id   = aws_api_gateway_resource.speke_server_api_resource_stop.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "speke_server_api_integration_post_streams_stop" {
  rest_api_id             = aws_api_gateway_rest_api.speke_server_api.id
  resource_id             = aws_api_gateway_resource.speke_server_api_resource_stop.id
  http_method             = aws_api_gateway_method.speke_server_api_method_post_streams_stop.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.medialive_stop_stream.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_resource" "speke_server_api_resource_split" {
  rest_api_id = aws_api_gateway_rest_api.speke_server_api.id
  parent_id   = aws_api_gateway_resource.speke_server_api_resource_id.id
  path_part   = "split"
}

resource "aws_api_gateway_method" "speke_server_api_method_post_stream_split" {
  rest_api_id   = aws_api_gateway_rest_api.speke_server_api.id
  resource_id   = aws_api_gateway_resource.speke_server_api_resource_split.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "speke_server_api_integration_post_stream_split" {
  rest_api_id             = aws_api_gateway_rest_api.speke_server_api.id
  resource_id             = aws_api_gateway_resource.speke_server_api_resource_split.id
  http_method             = aws_api_gateway_method.speke_server_api_method_post_stream_split.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.medialive_split_stream.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_resource" "speke_server_api_resource_live" {
  rest_api_id = aws_api_gateway_rest_api.speke_server_api.id
  parent_id   = aws_api_gateway_resource.speke_server_api_resource_id.id
  path_part   = "live"
}

resource "aws_api_gateway_method" "speke_server_api_method_post_stream_live" {
  rest_api_id   = aws_api_gateway_rest_api.speke_server_api.id
  resource_id   = aws_api_gateway_resource.speke_server_api_resource_live.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "speke_server_api_integration_post_stream_live" {
  rest_api_id             = aws_api_gateway_rest_api.speke_server_api.id
  resource_id             = aws_api_gateway_resource.speke_server_api_resource_live.id
  http_method             = aws_api_gateway_method.speke_server_api_method_post_stream_live.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.medialive_set_stream_cloudfront.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method" "speke_server_api_method_delete_stream_live" {
  rest_api_id   = aws_api_gateway_rest_api.speke_server_api.id
  resource_id   = aws_api_gateway_resource.speke_server_api_resource_live.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "speke_server_api_integration_delete_stream_live" {
  rest_api_id             = aws_api_gateway_rest_api.speke_server_api.id
  resource_id             = aws_api_gateway_resource.speke_server_api_resource_live.id
  http_method             = aws_api_gateway_method.speke_server_api_method_delete_stream_live.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.medialive_delete_stream_cloudfront.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method" "speke_server_api_method_get_streams_id" {
  rest_api_id   = aws_api_gateway_rest_api.speke_server_api.id
  resource_id   = aws_api_gateway_resource.speke_server_api_resource_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "speke_server_api_integration_get_stream_id" {
  rest_api_id             = aws_api_gateway_rest_api.speke_server_api.id
  resource_id             = aws_api_gateway_resource.speke_server_api_resource_id.id
  http_method             = aws_api_gateway_method.speke_server_api_method_get_streams_id.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.medialive_get_stream.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method" "speke_server_api_method_post_streams_id" {
  rest_api_id   = aws_api_gateway_rest_api.speke_server_api.id
  resource_id   = aws_api_gateway_resource.speke_server_api_resource_id.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "speke_server_api_integration_post_stream_id" {
  rest_api_id             = aws_api_gateway_rest_api.speke_server_api.id
  resource_id             = aws_api_gateway_resource.speke_server_api_resource_id.id
  http_method             = aws_api_gateway_method.speke_server_api_method_post_streams_id.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.medialive_update_stream.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method" "speke_server_api_method_delete_streams_id" {
  rest_api_id   = aws_api_gateway_rest_api.speke_server_api.id
  resource_id   = aws_api_gateway_resource.speke_server_api_resource_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "speke_server_api_integration_delete_stream_id" {
  rest_api_id             = aws_api_gateway_rest_api.speke_server_api.id
  resource_id             = aws_api_gateway_resource.speke_server_api_resource_id.id
  http_method             = aws_api_gateway_method.speke_server_api_method_delete_streams_id.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.medialive_delete_stream.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}
