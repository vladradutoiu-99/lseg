resource "kubernetes_manifest" "kong_key_plugin" {
  manifest = {
    "apiVersion" = "configuration.konghq.com/v1"
    "kind" = "KongPlugin"
    "metadata" = {
      "name" = "ingress-key-auth"
      "namespace" = "default"
    }
    "plugin" = "key-auth"
  }
  depends_on = [helm_release.kong]
}

resource "kubernetes_ingress_v1" "ingress_no_key" {
  metadata {
    name = "ingress-no-key"
    annotations = {
      "konghq.com/strip-path": "true"
    }
  }

  spec {
    ingress_class_name= "kong"
    rule {
      http {
        path {
          backend {
            service {
                name = "stock-service"
                port {
                    number = 80
                }
            }
          }

          path = "/stock-service"
          path_type = "ImplementationSpecific"
        }

      }
    }

  }
}

resource "kubernetes_ingress_v1" "ingress_api_key" {
  metadata {
    name = "ingress-api-key"
    annotations = {
      "konghq.com/strip-path": "true"
      "konghq.com/plugins": "ingress-key-auth"
    }
  }

  spec {
    ingress_class_name= "kong"
    rule {
      http {
        path {
          backend {
            service {
                name = "stock-service"
                port {
                    number = 80
                }
            }
          }

          path = "/auth/stock-service"
          path_type = "ImplementationSpecific"
        }

      }
    }

  }
}