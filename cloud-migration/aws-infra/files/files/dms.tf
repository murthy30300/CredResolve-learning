resource "aws_iam_role" "dms" {
  name = "${var.project_name}-dms-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "dms.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dms_vpc" {
  role       = aws_iam_role.dms.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

resource "aws_iam_role_policy_attachment" "dms_cloudwatch" {
  role       = aws_iam_role.dms.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

resource "aws_iam_role_policy" "dms_s3" {
  name = "dms-s3-access"
  role = aws_iam_role.dms.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket", "s3:GetObject"]
      Resource = [
        aws_s3_bucket.analytics.arn,
        "${aws_s3_bucket.analytics.arn}/*"
      ]
    }]
  })
}

resource "aws_dms_replication_subnet_group" "main" {
  replication_subnet_group_id          = "${var.project_name}-dms-subnet-group"
  replication_subnet_group_description = "DMS subnet group - private subnets"
  subnet_ids                           = [aws_subnet.private.id, aws_subnet.private_az2.id]

  tags = { Project = var.project_name }

  depends_on = [aws_iam_role_policy_attachment.dms_vpc]
}

resource "aws_dms_replication_instance" "main" {
  replication_instance_id    = "${var.project_name}-dms-instance"
  replication_instance_class = "dms.t3.medium"
  allocated_storage          = 50
  engine_version             = "3.5.2"

  vpc_security_group_ids      = [aws_security_group.dms.id]
  replication_subnet_group_id = aws_dms_replication_subnet_group.main.id
  publicly_accessible         = false
  multi_az                    = false
  auto_minor_version_upgrade  = true

  tags = {
    Name    = "${var.project_name}-dms"
    Project = var.project_name
  }

  depends_on = [aws_dms_replication_subnet_group.main]
}

resource "aws_dms_endpoint" "naadh_prod_source" {
  endpoint_id   = "naadh-prod-source"
  endpoint_type = "source"
  engine_name   = "postgres"
  server_name   = "10.1.2.9"
  port          = 5432
  database_name = "postgres"
  username      = "dms_user"
  password      = "DmsSecure@2024"

  extra_connection_attributes = "pluginName=pglogical;heartbeatFrequency=1"

  tags = { Project = var.project_name }
}

resource "aws_dms_endpoint" "communication_prod_source" {
  endpoint_id   = "communication-prod-source"
  endpoint_type = "source"
  engine_name   = "postgres"
  server_name   = "10.1.2.4"
  port          = 5432
  database_name = "postgres"
  username      = "dms_user"
  password      = "DmsSecure@2024"

  extra_connection_attributes = "pluginName=pglogical;heartbeatFrequency=1"

  tags = { Project = var.project_name }
}

resource "aws_dms_endpoint" "credresolve_analytics_source" {
  endpoint_id   = "credresolve-analytics-source"
  endpoint_type = "source"
  engine_name   = "postgres"
  server_name   = "10.1.2.3"
  port          = 5432
  database_name = "postgres"
  username      = "dms_user"
  password      = "DmsSecure@2024"

  extra_connection_attributes = "pluginName=pglogical;heartbeatFrequency=1"

  tags = { Project = var.project_name }
}

resource "aws_dms_endpoint" "credresolve_tiny_source" {
  endpoint_id   = "credresolve-tiny-source"
  endpoint_type = "source"
  engine_name   = "postgres"
  server_name   = "10.1.2.5"
  port          = 5432
  database_name = "postgres"
  username      = "dms_user"
  password      = "DmsSecure@2024"

  extra_connection_attributes = "pluginName=pglogical;heartbeatFrequency=1"

  tags = { Project = var.project_name }
}

resource "aws_dms_endpoint" "naadh_prod_target" {
  endpoint_id   = "naadh-prod-target"
  endpoint_type = "target"
  engine_name   = "postgres"
  server_name   = aws_db_instance.naadh_production.address
  port          = 5432
  database_name = "naadh_prod"
  username      = "postgres"
  password      = var.db_password

  tags = { Project = var.project_name }
}

resource "aws_dms_endpoint" "communication_prod_target" {
  endpoint_id   = "communication-prod-target"
  endpoint_type = "target"
  engine_name   = "postgres"
  server_name   = aws_db_instance.communication_prod.address
  port          = 5432
  database_name = "communication_prod"
  username      = "postgres"
  password      = var.db_password

  tags = { Project = var.project_name }
}

resource "aws_dms_endpoint" "credresolve_tiny_target" {
  endpoint_id   = "credresolve-tiny-target"
  endpoint_type = "target"
  engine_name   = "postgres"
  server_name   = aws_db_instance.credresolve_tiny.address
  port          = 5432
  database_name = "credresolve_tiny"
  username      = "postgres"
  password      = var.db_password

  tags = { Project = var.project_name }
}

resource "aws_dms_endpoint" "analytics_s3_target" {
  endpoint_id   = "analytics-s3-target"
  endpoint_type = "target"
  engine_name   = "s3"

  s3_settings {
    bucket_name             = aws_s3_bucket.analytics.bucket
    bucket_folder           = "dms-exports"
    service_access_role_arn = aws_iam_role.dms.arn
    data_format             = "parquet"
    compression_type        = "GZIP"
    timestamp_column_name   = "migrated_at"
  }

  tags = { Project = var.project_name }
}

locals {
  table_mappings = jsonencode({
    rules = [{
      rule-type = "selection"
      rule-id   = "1"
      rule-name = "include-all"
      object-locator = {
        schema-name = "%"
        table-name  = "%"
      }
      rule-action = "include"
    }]
  })

  replication_task_settings = jsonencode({
    TargetMetadata = {
      TargetSchema       = ""
      SupportLobs        = true
      FullLobMode        = false
      LobChunkSize       = 64
      LimitedSizeLobMode = true
      LobMaxSize         = 32
    }
    FullLoadSettings = {
      TargetTablePrepMode                 = "DO_NOTHING"
      CreatePkAfterFullLoad               = false
      StopTaskCachedChangesApplied        = false
      StopTaskCachedChangesNotApplied     = false
      MaxFullLoadSubTasks                 = 8
      TransactionConsistencyTimeout       = 600
      CommitRate                          = 50000
    }
    Logging = {
      EnableLogging = true
    }
  })
}

resource "aws_dms_replication_task" "naadh_prod" {
  replication_task_id      = "naadh-prod-migration"
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.main.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.naadh_prod_source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.naadh_prod_target.endpoint_arn
  table_mappings           = local.table_mappings
  replication_task_settings = local.replication_task_settings

  tags = { Name = "naadh-prod-migration", Project = var.project_name }
}

resource "aws_dms_replication_task" "communication_prod" {
  replication_task_id      = "communication-prod-migration"
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.main.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.communication_prod_source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.communication_prod_target.endpoint_arn
  table_mappings           = local.table_mappings
  replication_task_settings = local.replication_task_settings

  tags = { Name = "communication-prod-migration", Project = var.project_name }
}

resource "aws_dms_replication_task" "analytics_to_s3" {
  replication_task_id      = "analytics-to-s3"
  migration_type           = "full-load"
  replication_instance_arn = aws_dms_replication_instance.main.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.credresolve_analytics_source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.analytics_s3_target.endpoint_arn
  table_mappings           = local.table_mappings
  replication_task_settings = local.replication_task_settings

  tags = { Name = "analytics-to-s3", Project = var.project_name }
}