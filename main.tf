# Set number of nodes

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}


# Configure the GCP provider
provider "google" {
  credentials = file("./credentials.json")
  project     = var.project
  region      = var.region
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project}-gke"
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

# Provision a Managed Node pool
resource "google_container_node_pool" "primary_nodes" {
  name               = google_container_cluster.primary.name
  location           = var.region
  cluster            = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]

    labels = {
      env = var.project
    }

    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${var.project}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Configure kubectl to connect to the GKE cluster
resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project}"
  }
  depends_on = [google_container_node_pool.primary_nodes]
}

# Apply a Helm chart to the GKE cluster
resource "null_resource" "apply_helm_chart" {
  provisioner "local-exec" {
    command = "helm install demochart ./helmchart/demochart-0.1.0.tgz"
  }
  depends_on = [null_resource.configure_kubectl]
}
