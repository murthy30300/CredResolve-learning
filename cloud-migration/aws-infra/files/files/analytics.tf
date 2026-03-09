resource "aws_s3_bucket" "analytics" {
  bucket = var.analytics_bucket_name

  tags = {
    Name    = "${var.project_name}-analytics"
    Project = var.project_name
    Purpose = "Data lake - replaces BigQuery"
  }
}

resource "aws_s3_bucket_versioning" "analytics" {
  bucket = aws_s3_bucket.analytics.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics" {
  bucket = aws_s3_bucket.analytics.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "analytics" {
  bucket                  = aws_s3_bucket.analytics.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "folders" {
  for_each = toset([
    "datasets/CAAS/",
    "datasets/DASH/",
    "datasets/SAAS/",
    "datasets/SAAS_Dashboard/",
    "datasets/SAAS_SMFG/",
    "datasets/SAAS_dashboard_realtime/",
    "datasets/analyticsDb/",
    "datasets/cost/",
    "datasets/credresolveProd/",
    "datasets/field_officer_tower/",
    "datasets/prod/",
    "datasets/prod_latest/",
    "dms-exports/",
    "glue-scripts/",
  ])

  bucket  = aws_s3_bucket.analytics.id
  key     = each.value
  content = ""
}

resource "aws_s3_bucket" "athena_results" {
  bucket = var.athena_results_bucket_name

  tags = {
    Name    = "${var.project_name}-athena-results"
    Project = var.project_name
    Purpose = "Athena query output"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket                  = aws_s3_bucket.athena_results.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "expire-query-results"
    status = "Enabled"
    filter {}
    expiration {
      days = 30
    }
  }
}

resource "aws_athena_workgroup" "main" {
  name        = "${var.project_name}-workgroup"
  description = "Credresolve analytics workgroup - replaces BigQuery"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_glue_catalog_database" "analytics" {
  name        = "${var.project_name}_analytics"
  description = "Main analytics database - maps to BigQuery analyticsDb"
}

resource "aws_glue_catalog_database" "saas" {
  name        = "${var.project_name}_saas"
  description = "SAAS dataset - maps to BigQuery SAAS"
}

resource "aws_glue_catalog_database" "credresolve_prod" {
  name        = "${var.project_name}_prod"
  description = "Production dataset - maps to BigQuery credresolveProd and prod"
}

resource "aws_glue_catalog_database" "caas" {
  name        = "${var.project_name}_caas"
  description = "CAAS dataset"
}

resource "aws_glue_catalog_database" "cost" {
  name        = "${var.project_name}_cost"
  description = "Cost dataset"
}

resource "aws_glue_catalog_database" "field_officer" {
  name        = "${var.project_name}_field_officer"
  description = "Field officer tower dataset"
}

resource "aws_iam_role" "glue_crawler" {
  name = "${var.project_name}-glue-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3_access" {
  name = "glue-s3-access"
  role = aws_iam_role.glue_crawler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.analytics.arn,
        "${aws_s3_bucket.analytics.arn}/*"
      ]
    }]
  })
}

resource "aws_glue_crawler" "analytics" {
  name          = "${var.project_name}-analytics-crawler"
  role          = aws_iam_role.glue_crawler.arn
  database_name = aws_glue_catalog_database.analytics.name
  description   = "Crawls S3 analytics data and registers schema for Athena"

  s3_target {
    path = "s3://${aws_s3_bucket.analytics.bucket}/datasets/"
  }

  schedule = "cron(0 2 * * ? *)"

  tags = { Project = var.project_name }
}