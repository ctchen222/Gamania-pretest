output "cluster_name" {
  value = google_container_cluster.main.name
}

output "cluster_region" {
  value = google_container_cluster.main.location
}

output "artifact_registry_image" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}/nginx"
}

output "cloud_armor_policy_name" {
  value = google_compute_security_policy.web.name
}
