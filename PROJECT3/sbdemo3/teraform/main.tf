provider "google" {
  project = "springboot-vm-demo"
  region  = "asia-south1"
  zone    = "asia-south1-a"
}

resource "google_compute_instance" "app_vm" {
  name         = "springboot-vm"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt update
    apt install -y openjdk-17-jdk

    mkdir -p /opt/app
  EOF
}

resource "google_compute_firewall" "allow_app" {
  name    = "allow-8080"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
}

