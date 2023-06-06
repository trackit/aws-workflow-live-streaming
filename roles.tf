

data "aws_iam_policy_document" "lambda_job_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "medialive:*",
      "mediapackage:*",
      "dynamodb:*",
      "cloudfront:*",
      "events:*",
      "lambda:*",
      "ssm:*",
      "s3:*",
      "ecs:*",
      "ivs:*",
      "autoscaling:SetDesiredCapacity"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.medialive_job.arn
    ]
  }

}

data "aws_iam_policy_document" "lambda_job_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_job" {
  name               = "${var.project_base_name}medialive-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_job_trust.json
}

resource "aws_iam_role_policy" "lambda_job" {
  name = "${var.project_base_name}medialive-lambda-policy"
  role = aws_iam_role.lambda_job.id

  policy = data.aws_iam_policy_document.lambda_job_policy.json
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_job.name
}

data "aws_iam_policy_document" "medialive_job_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "mediapackage.amazonaws.com",
        "medialive.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "medialive_job" {
  name               = "${var.project_base_name}medialive-api-role"
  assume_role_policy = data.aws_iam_policy_document.medialive_job_trust.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.medialive_job.name
}
