resource "aws_lambda_function" "medialive_create_stream" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-medialive_api_create_stream"
  role             = aws_iam_role.lambda_job.arn
  handler          = "api.create_stream"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 3008

  environment {
    variables = {
      DYNAMODB_TABLE             = var.dynamodb_table_name,
      MEDIALIVE_ROLE_ARN         = aws_iam_role.medialive_job.arn,
      ARCHIVE_BUCKET             = var.archive_bucket_name,
      CLOUDFRONT_DISTRIBUTION_ID = var.using_cloudfront ? aws_cloudfront_distribution.live[0].id : "",
      CLOUDFRONT_LIVE_DOMAIN     = var.cloudfront_live_domain,
      INPUT_SECURITY_GROUP       = var.input_security_group,
      DELETE_CALLBACK_NAME       = "${var.project_base_name}-medialive_api_delete_stream_callback",
      DELETE_CALLBACK_ARN        = aws_lambda_function.medialive_delete_callback.arn
    }
  }
}

resource "aws_lambda_permission" "invoke_permission_create_stream" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medialive_create_stream.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_lambda_function" "medialive_start_stream" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-medialive_api_start_stream"
  role             = aws_iam_role.lambda_job.arn
  handler          = "api.start_stream"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 3008

  environment {
    variables = {
      DYNAMODB_TABLE             = var.dynamodb_table_name,
      MEDIALIVE_ROLE_ARN         = aws_iam_role.medialive_job.arn,
      ARCHIVE_BUCKET             = var.archive_bucket_name
      CLOUDFRONT_DISTRIBUTION_ID = var.using_cloudfront ? aws_cloudfront_distribution.live[0].id : "",
      CLOUDFRONT_LIVE_DOMAIN     = var.cloudfront_live_domain,
      INPUT_SECURITY_GROUP       = var.input_security_group,
      DELETE_CALLBACK_NAME       = "${var.project_base_name}-medialive_api_delete_stream_callback",
      DELETE_CALLBACK_ARN        = aws_lambda_function.medialive_delete_callback.arn
    }
  }
}

resource "aws_lambda_permission" "invoke_permission_start_stream" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medialive_start_stream.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_lambda_function" "medialive_stop_stream" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-medialive_api_stop_stream"
  role             = aws_iam_role.lambda_job.arn
  handler          = "api.stop_stream"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 3008

  environment {
    variables = {
      DYNAMODB_TABLE             = var.dynamodb_table_name,
      MEDIALIVE_ROLE_ARN         = aws_iam_role.medialive_job.arn,
      ARCHIVE_BUCKET             = var.archive_bucket_name
      CLOUDFRONT_DISTRIBUTION_ID = var.using_cloudfront ? aws_cloudfront_distribution.live[0].id : "",
      CLOUDFRONT_LIVE_DOMAIN     = var.cloudfront_live_domain,
      INPUT_SECURITY_GROUP       = var.input_security_group,
      DELETE_CALLBACK_NAME       = "${var.project_base_name}-medialive_api_delete_stream_callback",
      DELETE_CALLBACK_ARN        = aws_lambda_function.medialive_delete_callback.arn
    }
  }
}

resource "aws_lambda_permission" "invoke_permission_stop_stream" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medialive_stop_stream.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_lambda_function" "medialive_get_streams" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-medialive_api_get_streams"
  role             = aws_iam_role.lambda_job.arn
  handler          = "api.get_streams"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 3008

  environment {
    variables = {
      DYNAMODB_TABLE             = var.dynamodb_table_name,
      MEDIALIVE_ROLE_ARN         = aws_iam_role.medialive_job.arn,
      ARCHIVE_BUCKET             = var.archive_bucket_name
      CLOUDFRONT_DISTRIBUTION_ID = var.using_cloudfront ? aws_cloudfront_distribution.live[0].id : "",
      CLOUDFRONT_LIVE_DOMAIN     = var.cloudfront_live_domain,
      INPUT_SECURITY_GROUP       = var.input_security_group,
      DELETE_CALLBACK_NAME       = "${var.project_base_name}-medialive_api_delete_stream_callback",
      DELETE_CALLBACK_ARN        = aws_lambda_function.medialive_delete_callback.arn
    }
  }
}

resource "aws_lambda_permission" "invoke_permission_get_streams" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medialive_get_streams.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_lambda_function" "medialive_get_stream" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-medialive_api_get_stream"
  role             = aws_iam_role.lambda_job.arn
  handler          = "api.get_stream"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 3008

  environment {
    variables = {
      DYNAMODB_TABLE             = var.dynamodb_table_name,
      MEDIALIVE_ROLE_ARN         = aws_iam_role.medialive_job.arn,
      ARCHIVE_BUCKET             = var.archive_bucket_name
      CLOUDFRONT_DISTRIBUTION_ID = var.using_cloudfront ? aws_cloudfront_distribution.live[0].id : "",
      CLOUDFRONT_LIVE_DOMAIN     = var.cloudfront_live_domain,
      INPUT_SECURITY_GROUP       = var.input_security_group,
      DELETE_CALLBACK_NAME       = "${var.project_base_name}-medialive_api_delete_stream_callback",
      DELETE_CALLBACK_ARN        = aws_lambda_function.medialive_delete_callback.arn
    }
  }
}

resource "aws_lambda_permission" "invoke_permission_get_stream" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medialive_get_stream.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_lambda_function" "medialive_update_stream" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-medialive_api_update_stream"
  role             = aws_iam_role.lambda_job.arn
  handler          = "api.update_stream"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 3008

  environment {
    variables = {
      DYNAMODB_TABLE             = var.dynamodb_table_name,
      MEDIALIVE_ROLE_ARN         = aws_iam_role.medialive_job.arn,
      ARCHIVE_BUCKET             = var.archive_bucket_name
      CLOUDFRONT_DISTRIBUTION_ID = var.using_cloudfront ? aws_cloudfront_distribution.live[0].id : "",
      CLOUDFRONT_LIVE_DOMAIN     = var.cloudfront_live_domain,
      INPUT_SECURITY_GROUP       = var.input_security_group,
      DELETE_CALLBACK_NAME       = "${var.project_base_name}-medialive_api_delete_stream_callback",
      DELETE_CALLBACK_ARN        = aws_lambda_function.medialive_delete_callback.arn
    }
  }
}

resource "aws_lambda_permission" "invoke_permission_update_stream" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medialive_update_stream.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_lambda_function" "medialive_delete_stream" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-medialive_api_delete_stream"
  role             = aws_iam_role.lambda_job.arn
  handler          = "api.delete_stream"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 3008

  environment {
    variables = {
      DYNAMODB_TABLE             = var.dynamodb_table_name,
      MEDIALIVE_ROLE_ARN         = aws_iam_role.medialive_job.arn,
      ARCHIVE_BUCKET             = var.archive_bucket_name
      CLOUDFRONT_DISTRIBUTION_ID = var.using_cloudfront ? aws_cloudfront_distribution.live[0].id : "",
      CLOUDFRONT_LIVE_DOMAIN     = var.cloudfront_live_domain,
      INPUT_SECURITY_GROUP       = var.input_security_group,
      DELETE_CALLBACK_NAME       = "${var.project_base_name}-medialive_api_delete_stream_callback",
      DELETE_CALLBACK_ARN        = aws_lambda_function.medialive_delete_callback.arn
    }
  }
}

resource "aws_lambda_permission" "invoke_permission_delete_stream" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medialive_delete_stream.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_lambda_function" "medialive_split_stream" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-medialive_api_split_stream"
  role             = aws_iam_role.lambda_job.arn
  handler          = "api.split_stream"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 3008

  environment {
    variables = {
      DYNAMODB_TABLE             = var.dynamodb_table_name,
      MEDIALIVE_ROLE_ARN         = aws_iam_role.medialive_job.arn,
      ARCHIVE_BUCKET             = var.archive_bucket_name
      CLOUDFRONT_DISTRIBUTION_ID = var.using_cloudfront ? aws_cloudfront_distribution.live[0].id : "",
      CLOUDFRONT_LIVE_DOMAIN     = var.cloudfront_live_domain,
      INPUT_SECURITY_GROUP       = var.input_security_group,
      DELETE_CALLBACK_NAME       = "${var.project_base_name}-medialive_api_delete_stream_callback",
      DELETE_CALLBACK_ARN        = aws_lambda_function.medialive_delete_callback.arn
    }
  }
}

resource "aws_lambda_permission" "invoke_permission_split_stream" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medialive_split_stream.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_lambda_function" "medialive_delete_callback" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-medialive_api_delete_stream_callback"
  role             = aws_iam_role.lambda_job.arn
  handler          = "api.delete_callback"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 3008

  environment {
    variables = {
      DYNAMODB_TABLE             = var.dynamodb_table_name,
      MEDIALIVE_ROLE_ARN         = aws_iam_role.medialive_job.arn,
      ARCHIVE_BUCKET             = var.archive_bucket_name
      CLOUDFRONT_DISTRIBUTION_ID = var.using_cloudfront ? aws_cloudfront_distribution.live[0].id : "",
      CLOUDFRONT_LIVE_DOMAIN     = var.cloudfront_live_domain,
      INPUT_SECURITY_GROUP       = var.input_security_group,
      DELETE_CALLBACK_NAME       = "${var.project_base_name}-medialive_api_delete_stream_callback"
    }
  }
}

resource "aws_lambda_function" "medialive_set_stream_cloudfront" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-medialive_api_set_stream_cloudfront"
  role             = aws_iam_role.lambda_job.arn
  handler          = "api.set_stream_cloudfront"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 3008

  environment {
    variables = {
      DYNAMODB_TABLE             = var.dynamodb_table_name,
      MEDIALIVE_ROLE_ARN         = aws_iam_role.medialive_job.arn,
      ARCHIVE_BUCKET             = var.archive_bucket_name
      CLOUDFRONT_DISTRIBUTION_ID = var.using_cloudfront ? aws_cloudfront_distribution.live[0].id : "",
      CLOUDFRONT_LIVE_DOMAIN     = var.cloudfront_live_domain,
      INPUT_SECURITY_GROUP       = var.input_security_group,
      DELETE_CALLBACK_NAME       = "${var.project_base_name}-medialive_api_delete_stream_callback",
      DELETE_CALLBACK_ARN        = aws_lambda_function.medialive_delete_callback.arn
    }
  }
}

resource "aws_lambda_permission" "invoke_permission_set_stream_cloudfront" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medialive_set_stream_cloudfront.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_lambda_function" "medialive_delete_stream_cloudfront" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-medialive_api_delete_stream_cloudfront"
  role             = aws_iam_role.lambda_job.arn
  handler          = "api.delete_stream_cloudfront"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 3008

  environment {
    variables = {
      DYNAMODB_TABLE             = var.dynamodb_table_name,
      MEDIALIVE_ROLE_ARN         = aws_iam_role.medialive_job.arn,
      ARCHIVE_BUCKET             = var.archive_bucket_name
      CLOUDFRONT_DISTRIBUTION_ID = var.using_cloudfront ? aws_cloudfront_distribution.live[0].id : "",
      CLOUDFRONT_LIVE_DOMAIN     = var.cloudfront_live_domain,
      INPUT_SECURITY_GROUP       = var.input_security_group,
      DELETE_CALLBACK_NAME       = "${var.project_base_name}-medialive_api_delete_stream_callback",
      DELETE_CALLBACK_ARN        = aws_lambda_function.medialive_delete_callback.arn
    }
  }
}

resource "aws_lambda_permission" "invoke_permission_delete_stream_cloudfront" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medialive_delete_stream_cloudfront.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}
