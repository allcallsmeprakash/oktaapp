output "s3_bucket_name" {
  value = aws_s3_bucket.website_bucket.bucket
}

output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.website_distribution.domain_name
}
