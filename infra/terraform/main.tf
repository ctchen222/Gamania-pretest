locals {
  required_apis = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each           = local.required_apis
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "main" {
  name                    = "${var.cluster_name}-network"
  auto_create_subnetworks = false

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "main" {
  name                     = "${var.cluster_name}-subnet"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = "10.10.0.0/20"
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "${var.cluster_name}-pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "${var.cluster_name}-services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

resource "google_container_cluster" "main" {
  name                = var.cluster_name
  location            = var.region
  enable_autopilot    = true
  deletion_protection = false
  network             = google_compute_network.main.name
  subnetwork          = google_compute_subnetwork.main.name
  networking_mode     = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.cluster_name}-pods"
    services_secondary_range_name = "${var.cluster_name}-services"
  }

  release_channel {
    channel = "REGULAR"
  }

  depends_on = [google_project_service.required]
}

resource "google_artifact_registry_repository" "images" {
  location      = var.region
  repository_id = "sre-pretest"
  description   = "Container images for the SRE pretest"
  format        = "DOCKER"

  depends_on = [google_project_service.required]
}

resource "google_compute_security_policy" "web" {
  name        = "sre-pretest-cloud-armor"
  description = "Blocks common XSS patterns for the service"

  rule {
    action      = "deny(403)"
    priority    = 1000
    description = "Deny requests matching the Cloud Armor XSS WAF rule set"

    match {
      expr {
        expression = "evaluatePreconfiguredWaf('xss-stable', {'sensitivity': 1})"
      }
    }
  }

  rule {
    action      = "allow"
    priority    = 2147483647
    description = "Default allow rule; the WAF rule above blocks matching XSS requests"

    match {
      versioned_expr = "SRC_IPS_V1"

      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  depends_on = [google_project_service.required]
}
