locals {
  postgres_startup = file("${path.module}/scripts/postgres_startup.sh")

  redis_startup = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y redis-server
    sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
    sed -i 's/# requirepass foobared/requirepass RedisSecure@2024/' /etc/redis/redis.conf
    systemctl restart redis-server
    systemctl enable redis-server
    echo "Redis setup complete" >> /var/log/startup-script.log
  EOT

  metabase_startup = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y openjdk-11-jre-headless wget
    mkdir -p /opt/metabase
    wget -O /opt/metabase/metabase.jar https://downloads.metabase.com/v0.47.0/metabase.jar
    cat > /etc/systemd/system/metabase.service <<EOF
    [Unit]
    Description=Metabase
    After=network.target
    [Service]
    ExecStart=/usr/bin/java -jar /opt/metabase/metabase.jar
    Restart=always
    Environment=MB_DB_TYPE=h2
    WorkingDirectory=/opt/metabase
    [Install]
    WantedBy=multi-user.target
    EOF
    systemctl daemon-reload
    systemctl enable metabase
    systemctl start metabase
    echo "Metabase setup complete" >> /var/log/startup-script.log
  EOT
}

resource "google_compute_instance" "credresolve_prod_database" {
  count        = var.create_large_instances ? 1 : 0
  name         = "credresolve-prod-database"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["all-db", "prod-database"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = local.postgres_startup
  metadata = { enable-oslogin = "TRUE" }
}

resource "google_compute_instance" "credresolve_database_replica" {
  count        = var.create_large_instances ? 1 : 0
  name         = "credresolve-database-replica"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["all-db", "prod-database", "read-only"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = local.postgres_startup
  metadata = { enable-oslogin = "TRUE" }
}

resource "google_compute_instance" "credresolve_data_analytics_db" {
  name         = "credresolve-data-analytics-db"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["all-db"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = local.postgres_startup
  metadata = { enable-oslogin = "TRUE" }
}

resource "google_compute_instance" "communication_prod_database" {
  name         = "communication-prod-database"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["all-db", "prod-database"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = local.postgres_startup
  metadata = { enable-oslogin = "TRUE" }
}

resource "google_compute_instance" "naadh_production_database" {
  name         = "naadh-production-database"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["all-db", "prod-database"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = local.postgres_startup
  metadata = { enable-oslogin = "TRUE" }
}

resource "google_compute_instance" "naadh_database_stage" {
  name         = "naadh-database-stage"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["all-db"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = local.postgres_startup
  metadata = { enable-oslogin = "TRUE" }
}

resource "google_compute_instance" "credresolve_tiny_db" {
  name         = "credresolve-tiny-db"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["all-db"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = local.postgres_startup
  metadata = { enable-oslogin = "TRUE" }
}

resource "google_compute_instance" "redis_server" {
  name         = "redis-server"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["redis"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = local.redis_startup
  metadata = { enable-oslogin = "TRUE" }
}

resource "google_compute_instance" "redis_server_stage" {
  name         = "redis-server-stage"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["redis"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = local.redis_startup
  metadata = { enable-oslogin = "TRUE" }
}

resource "google_compute_instance" "credresolve_metabase" {
  name         = "credresolve-metabase"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["metabase"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = local.metabase_startup
  metadata = { enable-oslogin = "TRUE" }
}