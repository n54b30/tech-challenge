# Set GCP project and region variables
variable "project" {
  type    = string
  default = "nucleus-380110"
}

variable "region" {
  type    = string
  default = "europe-west2"
}

# Configure the GCP provider
provider "google" {
  credentials = file("./credentials.json")
  project     = var.project
  region      = var.region
}

# Provision a GKE cluster
resource "google_container_cluster" "cluster" {
  name               = "cluster123"
  location           = var.region
  initial_node_count = 3

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
}

# Configure kubectl to connect to the GKE cluster
resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --region ${var.region} --project ${var.project}"
  }
  depends_on = [google_container_cluster.cluster]
}

# Apply a Helm chart to the GKE cluster
resource "null_resource" "apply_helm_chart" {
  provisioner "local-exec" {
    command = "helm install demochart ./helmchart/demochart-0.1.0.tgz"
  }
  depends_on = [null_resource.configure_kubectl]
}
