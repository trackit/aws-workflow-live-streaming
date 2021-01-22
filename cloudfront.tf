locals {
  error_pages     = [400, 403, 404, 405, 414, 416, 500, 501, 502, 503, 504]
}

resource "aws_route53_record" "live" {
  count   = var.using_cloudfront ? 1 : 0
  zone_id = var.route_53_id
  name    = "live.frontendmasters.com"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_cloudfront_distribution.live[count.index]]
}

resource "aws_cloudfront_distribution" "live" {
  count   = var.using_cloudfront ? 1 : 0
  enabled = true
  comment = "Endpoint for medialive"

  aliases = ["live.frontendmasters.com"]

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    domain_name = "mediapackage.amazonaws.com"
    origin_id   = "TempORIGIN"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "TempORIGIN"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      cookies {
        forward = "none"
      }

      headers = [
        "Origin"
      ]

      query_string = true
      query_string_cache_keys = [
        "end",
        "m",
        "start"
      ]
    }
  }

  ordered_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "TempORIGIN"
    viewer_protocol_policy = "redirect-to-https"
    path_pattern           = "*"

    forwarded_values {
      cookies {
        forward = "none"
      }

      headers = [
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers",
        "Origin"
      ]

      query_string = true
      query_string_cache_keys = [
        "end",
        "m",
        "start"
      ]
    }
  }
  dynamic "custom_error_response" {
    for_each = local.error_pages

    content {
      error_code            = custom_error_response.value
      error_caching_min_ttl = 1
    }
  }

  lifecycle {
    # ignore_changes = [
    #   origin
    # ]
    ignore_changes = all
  }
}
