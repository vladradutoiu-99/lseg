resource "google_service_account_key" "google-cloud-key" {
  service_account_id = google_service_account.default.name
}

resource "kubernetes_secret_v1" "google-cloud-key-secret" {
  metadata {
    name = "google-application-credentials"
  }

  data = {
    "key.json" = "${google_service_account_key.google-cloud-key.private_key}"
  }
  
}

# data "template_file" "docker_config_script" {
#   template = "${file("${path.module}/config.json")}"
#   vars = {
#     docker-username           = "_json_key"
#     docker-password           = "${trimspace(base64decode("${google_service_account_key.google-cloud-key.private_key}"))}"
#     docker-server             = "https://europe-west3-docker.pkg.dev"
#     docker-email              = "emai@mail.com"
#     auth                      = "${base64encode("_json_key:${trimspace(base64decode("${google_service_account_key.google-cloud-key.private_key}"))}")}"
#   }
# }

# output "template" {
#   value = data.template_file.docker_config_script.rendered
# }

# resource "kubernetes_secret_v1" "docker-auth" {
#   metadata {
#     name = "google-docker-auth"
#   }

#   type = "kubernetes.io/dockerconfigjson"

#   data = {
#     # ".dockerconfigjson" = "${data.template_file.docker_config_script.rendered}"
#     ".dockerconfigjson" = jsonencode({
#       "auths" : {
#         "https://europe-west3-docker.pkg.dev" : {
#           email    = "mail"
#           username = "_json_key"
#           password = trimspace(base64decode("${google_service_account_key.google-cloud-key.private_key}"))
#           auth     = base64encode("_json_key:${trimspace(base64decode("${google_service_account_key.google-cloud-key.private_key}"))}")
#         }
#       }
#     })
#   }
  
# }

resource "google_project_iam_member" "artifact_role" {
  role = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.default.email}"
  project = "spiritual-oxide-435516-u4"
}

resource "kubernetes_service_account" "ksa" {
  metadata {
    name      = "docker-auth"
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.default.email
    }
  }
}


resource "google_service_account_iam_binding" "service-account-binding" {
  service_account_id = google_service_account.default.name
  role    = "roles/iam.workloadIdentityUser"
  members  = [
  "serviceAccount:spiritual-oxide-435516-u4.svc.id.goog[${kubernetes_service_account.ksa.metadata.0.namespace}/${kubernetes_service_account.ksa.metadata.0.name}]"
  ]
  
}


provider "kubernetes" {
  host  = "https://${google_container_cluster.test_cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.test_cluster.master_auth[0].cluster_ca_certificate,
  )
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gke-gcloud-auth-plugin"
  }
}

resource "kubernetes_namespace_v1" "zalando" {
  metadata {
    annotations = {
      name = "zalando"
    }

    name = "zalando"
  }

}

resource "kubernetes_namespace_v1" "postgres-ns" {
  metadata {
    annotations = {
      name = "postgres-ns"
    }
    name = "postgres-ns"
  }
}

resource "kubernetes_namespace_v1" "kong" {
  metadata {
    annotations = {
      name = "kong"
    }

    name = "kong"
  }
}

provider "helm" {
  debug="true"

  kubernetes {
    host  = "https://${google_container_cluster.test_cluster.endpoint}"
    token = data.google_client_config.provider.access_token
    config_path = "~/.kube/config"
    cluster_ca_certificate = base64decode(
      google_container_cluster.test_cluster.master_auth[0].cluster_ca_certificate
    )
  }
}

resource "helm_release" "postgres-kong" {
  name       = "postgres-kong"
  repository = "https://charts.bitnami.com/bitnami"
  chart = "postgresql"
  namespace  = "kong"
  dependency_update = true
  force_update      = true
  verify=false

  set {
    name  = "primary.persistence.storageClass"
    value = "premium-rwo"
  }
  set {
    name  = "global.postgresql.auth.postgresPassword"
    value = "kong"
  }
  set {
    name  = "global.postgresql.auth.username"
    value = "kong"
  }
  set {
    name  = "global.postgresql.auth.password"
    value = "kong"
  }
  set {
    name  = "global.postgresql.auth.database"
    value = "kong"
  }
}

resource "helm_release" "kong" {
  name       = "kong"
  repository = "https://charts.konghq.com"
  chart = "ingress"
  namespace  = "kong"
  dependency_update = true
  force_update      = true
  verify=false


  set {
    name = "gateway.env.role"
    value = "traditional"
  }
  set {
    name = "gateway.env.database"
    value = "postgres"
  }
  set {
    name = "gateway.env.pg_user"
    value = "kong"
  }
  set {
    name = "gateway.env.pg_database"
    value = "kong"
  }
  set {
    name = "gateway.env.pg_host"
    value = "postgres-kong-postgresql.kong.svc.cluster.local"
  }
  set {
    name = "gateway.env.pg_port"
    value = "5432"
  }
  set {
    name = "gateway.env.pg_password"
    value = "kong"
  }
  set {
    name = "gateway.env.pg_ssl"
    value = "off"
  }

  set {
    name = "gateway.admin.http.enabled"
    value = "true"
  }

}

resource "helm_release" "postgres-operator" {
  name       = "postgres-operator-charts"
  repository = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
  chart = "postgres-operator"
  namespace  = "zalando"
  dependency_update = true
  force_update      = true
  verify=false

  set {
    name  = "configKubernetes.enable_pod_antiaffinity"
    value = "true"
  }
  set {
    name  = "configKubernetes.pod_antiaffinity_preferred_during_scheduling"
    value = "true"
  }
  set {
    name  = "configKubernetes.pod_antiaffinity_topology_key"
    value = "topology.kubernetes.io/zone"
  }
  set {
    name  = "configKubernetes.spilo_fsgroup"
    value = "103"
  }
  set {
    name  = "configKubernetes.enable_cross_namespace_secret"
    value = "true"
  }
}

resource "kubernetes_manifest" "postgresql_postgres_ns_postgresql_cluster" {
  manifest = {
    "apiVersion" = "acid.zalan.do/v1"
    "kind" = "postgresql"
    "metadata" = {
      "name" = "postgresql-cluster"
      "namespace" = "postgres-ns"
    }
    "spec" = {
      "databases" = {
        "mydatabase" = "mydatabaseowner"
      }
      "dockerImage" = "ghcr.io/zalando/spilo-15:3.0-p1"
      "enableShmVolume" = true
      "nodeAffinity" = {
        "preferredDuringSchedulingIgnoredDuringExecution" = [
          {
            "preference" = {
              "matchExpressions" = [
                {
                  "key" = "app.stateful/component"
                  "operator" = "In"
                  "values" = [
                    "postgres-operator",
                  ]
                },
              ]
            }
            "weight" = 1
          },
        ]
      }
      "numberOfInstances" = 2
      "podAnnotations" = {
        "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
      }
      "postgresql" = {
        "parameters" = {
          "log_statement" = "all"
          "max_connections" = "10"
          "password_encryption" = "scram-sha-256"
          "shared_buffers" = "32MB"
        }
        "version" = "15"
      }
      "resources" = {
        "limits" = {
          "cpu" = "2"
          "memory" = "2Gi"
        }
        "requests" = {
          "cpu" = "1"
          "memory" = "2Gi"
        }
      }
      "sidecars" = [
        {
          "args" = [
            "--collector.stat_statements",
          ]
          "env" = [
            {
              "name" = "DATA_SOURCE_URI"
              "value" = "localhost/postgres?sslmode=require"
            },
            {
              "name" = "DATA_SOURCE_USER"
              "value" = "$(POSTGRES_USER)"
            },
            {
              "name" = "DATA_SOURCE_PASS"
              "value" = "$(POSTGRES_PASSWORD)"
            },
          ]
          "image" = "quay.io/prometheuscommunity/postgres-exporter:v0.14.0"
          "name" = "exporter"
          "ports" = [
            {
              "containerPort" = 9187
              "name" = "exporter"
              "protocol" = "TCP"
            },
          ]
          "resources" = {
            "limits" = {
              "cpu" = "500m"
              "memory" = "256M"
            }
            "requests" = {
              "cpu" = "100m"
              "memory" = "256M"
            }
          }
        },
      ]
      "teamId" = "team-id"
      "tolerations" = [
        {
          "effect" = "NoSchedule"
          "key" = "app.stateful/component"
          "operator" = "Equal"
          "value" = "postgres-operator"
        },
      ]
      "users" = {
        "mydatabaseowner" = [
          "superuser",
          "createdb",
        ]
        "default.myuser" = [
          "createdb",
        ]
      }
      "volume" = {
        "size" = "5Gi"
        "storageClass" = "standard-rwo"
      }
    }
  }

  depends_on = [helm_release.postgres-operator]
}

# resource "google_artifact_registry_repository" "my_repo" {
#   location      = "europe-west3"
#   repository_id = "docker-images"
#   project = "spiritual-oxide-435516-u4"
#   format        = "DOCKER"
# }

data "google_artifact_registry_docker_image" "my_image" {
  provider = google-beta

  location      = "europe-west3"
  repository_id = "docker-images"
  image_name = "stock_service:latest"
}


resource "kubernetes_deployment_v1" "deployment" {
  metadata {
    name = "stock-service-deployment"
    labels = {
      app = "stock-service"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "stock-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "stock-service"
        }
      }

      spec {
        volume {
          name = "google-cloud-key"
          secret {
            secret_name = kubernetes_secret_v1.google-cloud-key-secret.metadata.0.name
          }
        }
        automount_service_account_token = false
        # image_pull_secrets {
        #   name = kubernetes_secret_v1.docker-auth.metadata.0.name
        # }
        service_account_name = kubernetes_service_account.ksa.metadata.0.name
        container {
          image = data.google_artifact_registry_docker_image.my_image.self_link
          name  = "stock-service-container"

          port {
            container_port = 8080
            name           = "stock-svc"
          }

          volume_mount {
            name       = "google-cloud-key"
            mount_path = "/var/secrets/google"
          }

          security_context {
            allow_privilege_escalation = false
            privileged                 = false
            read_only_root_filesystem  = false

            capabilities {
              add  = []
              drop = ["NET_RAW"]
            }
          }

          # liveness_probe {
          #   http_get {
          #     path = "/"
          #     port = "hello-app-svc"

          #     http_header {
          #       name  = "X-Custom-Header"
          #       value = "Awesome"
          #     }
          #   }

          #   initial_delay_seconds = 3
          #   period_seconds        = 3
          # }
          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.configmap.metadata.0.name
            }
          }
          env_from {
            secret_ref {
              name = "default.myuser.postgresql-cluster.credentials.postgresql.acid.zalan.do"
            }
          }
        }

        security_context {
          run_as_non_root = false

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        toleration {
          effect   = "NoSchedule"
          key      = "kubernetes.io/arch"
          operator = "Equal"
          value    = "amd64"
        }
      }
    }


  }

}

resource "kubernetes_service" "service" {
  metadata {
    name = "stock-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.deployment.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}