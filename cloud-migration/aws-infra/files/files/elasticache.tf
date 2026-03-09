resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_az2.id]

  tags = {
    Name    = "${var.project_name}-redis-subnet-group"
    Project = var.project_name
  }
}

resource "aws_elasticache_replication_group" "redis_prod" {
  replication_group_id = "${var.project_name}-redis-prod"
  description          = "Production Redis - replaces redis-server GCE VM"

  node_type          = "cache.t3.medium"
  num_cache_clusters = 1
  port               = 6379
  engine_version     = "7.0"

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  tags = {
    Name    = "redis-server"
    Project = var.project_name
    Env     = "production"
  }
}

resource "aws_elasticache_replication_group" "redis_stage" {
  replication_group_id = "${var.project_name}-redis-stage"
  description          = "Stage Redis - replaces redis-server-stage GCE VM"

  node_type          = "cache.t3.micro"
  num_cache_clusters = 1
  port               = 6379
  engine_version     = "7.0"

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  tags = {
    Name    = "redis-server-stage"
    Project = var.project_name
    Env     = "staging"
  }
}