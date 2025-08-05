provider "aws" {
  region = "us-east-1"
}


terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.0"
    }
  }
}
provider "auth0" {
  domain        = "dev-gfew5m8jtuzrrhhw.us.auth0.com"
  client_id                  = "rZyBhpq7SsMgyhxXTPbjfmRunEZHDFNq"
  client_secret              = "iFLPIid-tlvMK9igrZfZGnWiV6cHJI1TNZRrLN_o-vHDmJ7lKbtXuxoNTxABAsq5"
}

# S3 Bucket for Hosting
resource "aws_s3_bucket" "website_bucket" {
  bucket = "hello-world-web-app-prod"

  tags = {
    Name = "HelloWorldWebAppProd"
  }
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website_bucket_block" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  depends_on = [aws_s3_bucket_public_access_block.website_bucket_block]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.website_config.website_endpoint
    origin_id   = "S3Origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "HelloWorldWebAppDistribution"
  }
}

# Auth0 Application Configuration
resource "auth0_client" "hello_world_app" {
  name            = "HelloWorldApp"
  app_type        = "regular_web"
  oidc_conformant = true

  callbacks            = ["https://${aws_cloudfront_distribution.website_distribution.domain_name}/index.html"]
  allowed_logout_urls  = ["https://${aws_cloudfront_distribution.website_distribution.domain_name}/logout"]

  grant_types = [
    "authorization_code",
    "implicit",
    "refresh_token"
  ]
}


