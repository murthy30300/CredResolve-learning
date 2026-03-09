# ─────────────────────────────────────────────
# IAM ROLE FOR EC2 (SSM access — no SSH needed)
# ─────────────────────────────────────────────
resource "aws_iam_role" "ec2_ssm" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${var.project_name}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

# ─────────────────────────────────────────────
# METABASE EC2
# Source: credresolve-metabase (10.1.2.2) — n2-custom-2-4096
# AWS equivalent: t3.medium (2 vCPU, 4GB)
# ─────────────────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "metabase" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  # Startup — installs Metabase and points it to RDS
  user_data = base64encode(<<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y openjdk-11-jre-headless wget

    mkdir -p /opt/metabase
    wget -O /opt/metabase/metabase.jar https://downloads.metabase.com/v0.47.0/metabase.jar

    # Environment — Metabase uses its own H2 DB by default
    # For production, point MB_DB_* to an RDS PostgreSQL instance
    cat > /etc/systemd/system/metabase.service <<EOF
    [Unit]
    Description=Metabase Analytics
    After=network.target

    [Service]
    ExecStart=/usr/bin/java -jar /opt/metabase/metabase.jar
    Restart=always
    Environment=MB_DB_TYPE=h2
    Environment=MB_JETTY_PORT=3000
    WorkingDirectory=/opt/metabase
    StandardOutput=journal
    StandardError=journal

    [Install]
    WantedBy=multi-user.target
    EOF

    systemctl daemon-reload
    systemctl enable metabase
    systemctl start metabase
  EOT
  )

  tags = {
    Name    = "credresolve-metabase"
    Project = var.project_name
  }
}
