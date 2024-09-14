resource "kubernetes_config_map_v1" "configmap" {
  metadata {
    name = "configmap"
    namespace = "default"
  }

  data = {
    db_host              = "http://${kubernetes_manifest.postgresql_postgres_ns_postgresql_cluster.manifest.metadata.name}.postgresql.${kubernetes_manifest.postgresql_postgres_ns_postgresql_cluster.manifest.metadata.namespace}.svc.cluster.local:5432"
  }

}