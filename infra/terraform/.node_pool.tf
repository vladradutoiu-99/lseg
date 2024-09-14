resource "google_container_node_pool" "test_node_pool" {
  name    = "test-node-pool"
  cluster = google_container_cluster.test_cluster.name

  autoscaling {
    location_policy      = "BALANCED"
    max_node_count       = 2
    min_node_count       = 1
    total_max_node_count = 0
    total_min_node_count = 0
  }

  node_config {
    service_account = google_service_account.default.email
  }
}

resource "google_container_node_pool" "db_node_pool" {
  name    = "db-node-pool"
  cluster = google_container_cluster.test_cluster.name

  autoscaling {
    location_policy      = "BALANCED"
    max_node_count       = 2
    min_node_count       = 1
    total_max_node_count = 0
    total_min_node_count = 0
  }

  node_config {
    service_account = google_service_account.default.email
  }
}
