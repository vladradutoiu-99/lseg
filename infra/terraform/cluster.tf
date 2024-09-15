data "google_client_config" "provider" {}


resource "google_service_account" "default" {
  account_id   = "service-account-id-3"
  display_name = "Service Account"
  project = "spiritual-oxide-435516-u4"
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/container.clusterAdmin"

    members = [
      "serviceAccount:${google_service_account.default.email}"
    ]
  }

  binding {
    role = "roles/artifactregistry.reader"

    members = [
      "serviceAccount:${google_service_account.default.email}",
    ]
  }
}

resource "google_container_cluster" "test_cluster" {
  name               = "test-cluster-2"
  project = "spiritual-oxide-435516-u4"
  location           = "europe-west3"
  node_locations     = ["europe-west3-b"]
  initial_node_count = 2

  network    = "default"
  subnetwork = "default"

  remove_default_node_pool = true

  workload_identity_config {
      workload_pool = "spiritual-oxide-435516-u4.svc.id.goog"
  }

  addons_config {
    gke_backup_agent_config {
      enabled = true
    }
  }

}

resource "google_container_node_pool" "pool-postgres" {
  name    = "pool-postgres"
  location = "europe-west3"
  cluster = google_container_cluster.test_cluster.name
  project = "spiritual-oxide-435516-u4"
  

  node_config {
    workload_metadata_config {
        mode = "GKE_METADATA"
      }
    service_account = google_service_account.default.email
    disk_size_gb    = 20
    disk_type       = "pd-standard"
    machine_type    = "e2-standard-2"
    taint = [
      {
        key    = "app.stateful/component"
        value  = "postgres-operator"
        effect = "NO_SCHEDULE"
      }
    ]
    labels = {
      "app.stateful/component" = "postgres-operator"
    }
  }

  autoscaling {
    max_node_count = 3
    min_node_count = 2
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  timeouts {
    create = "30m"
    update = "20m"
  }
}

resource "google_container_node_pool" "standard_pool" {
  name    = "standard-pool"
  location = "europe-west3"
  cluster = google_container_cluster.test_cluster.name
  project = "spiritual-oxide-435516-u4"
  node_config {
    service_account = google_service_account.default.email
     oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]
    disk_size_gb    = 20
    disk_type       = "pd-standard"
    machine_type    = "e2-standard-4"
  }

  autoscaling {
    max_node_count = 2
    min_node_count = 1
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  timeouts {
    create = "30m"
    update = "20m"
  }
}
