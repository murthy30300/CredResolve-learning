resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_az2.id]

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

resource "aws_db_parameter_group" "postgres14" {
  name   = "${var.project_name}-postgres14-params"
  family = "postgres14"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "wal_sender_timeout"
    value        = "0"
    apply_method = "pending-reboot"
  }

  tags = { Project = var.project_name }
}

resource "aws_db_instance" "naadh_production" {
  identifier        = "naadh-production-database"
  engine            = "postgres"
  engine_version    = "14"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "naadh_prod"
  username = "postgres"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.postgres14.name

  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 1
  storage_encrypted       = true

  tags = {
    Name    = "naadh-production-database"
    Project = var.project_name
    Env     = "production"
  }
}

resource "aws_db_instance" "naadh_stage" {
  identifier        = "naadh-database-stage"
  engine            = "postgres"
  engine_version    = "14"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "naadh_stage"
  username = "postgres"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.postgres14.name

  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 1
  storage_encrypted       = true

  tags = {
    Name    = "naadh-database-stage"
    Project = var.project_name
    Env     = "staging"
  }
}

resource "aws_db_instance" "credresolve_prod" {
  identifier        = "credresolve-prod-database"
  engine            = "postgres"
  engine_version    = "14"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "credresolve_prod"
  username = "postgres"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.postgres14.name

  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 1
  storage_encrypted       = true

  tags = {
    Name    = "credresolve-prod-database"
    Project = var.project_name
    Env     = "production"
  }
}

resource "aws_db_instance" "communication_prod" {
  identifier        = "communication-prod-database"
  engine            = "postgres"
  engine_version    = "14"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "communication_prod"
  username = "postgres"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.postgres14.name

  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 1
  storage_encrypted       = true

  tags = {
    Name    = "communication-prod-database"
    Project = var.project_name
    Env     = "production"
  }
}

resource "aws_db_instance" "credresolve_tiny" {
  identifier        = "credresolve-tiny-db"
  engine            = "postgres"
  engine_version    = "14"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "credresolve_tiny"
  username = "postgres"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.postgres14.name

  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 1
  storage_encrypted       = true

  tags = {
    Name    = "credresolve-tiny-db"
    Project = var.project_name
  }
}

resource "aws_db_instance" "data_analytics" {
  identifier        = "credresolve-data-analytics-db"
  engine            = "postgres"
  engine_version    = "14"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "analytics_db"
  username = "postgres"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.postgres14.name

  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 1
  storage_encrypted       = true

  tags = {
    Name    = "credresolve-data-analytics-db"
    Project = var.project_name
  }
}