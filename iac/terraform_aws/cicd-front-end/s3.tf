resource "aws_s3_bucket" "build-cache" {
  bucket = "build-website-pipeline-cache-${var.aws_region}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

}

resource "aws_s3_bucket_policy" "build-cache" {
  bucket = aws_s3_bucket.build-cache.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowTLSRequestsOnly",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          "${aws_s3_bucket.build-cache.arn}",
          "${aws_s3_bucket.build-cache.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "build-cache" {
  bucket = aws_s3_bucket.build-cache.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "build-cache" {
  bucket = aws_s3_bucket.build-cache.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
