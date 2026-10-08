variable "project_id" {
  description = "Google Cloud project ID with billing enabled."
  type        = string
}

variable "region" {
  description = "Region for GKE and Artifact Registry."
  type        = string
  default     = "asia-east1"
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
  default     = "sre-pretest"
}
