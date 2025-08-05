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
