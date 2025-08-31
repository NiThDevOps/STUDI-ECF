#############################################
# Applique les manifests K8s du dossier courant
# (EFK + Job Kibana + CronJob webcheck)
#############################################

locals {
  ns_docs               = [for d in split("\n---\n", file("${path.module}/monitoring-namespace.yaml"))    : yamldecode(d) if trimspace(d) != ""]
  es_docs               = [for d in split("\n---\n", file("${path.module}/elasticsearch.yaml"))           : yamldecode(d) if trimspace(d) != ""]
  kibana_docs           = [for d in split("\n---\n", file("${path.module}/kibana.yaml"))                  : yamldecode(d) if trimspace(d) != ""]
  fb_config_docs        = [for d in split("\n---\n", file("${path.module}/fluent-bit-config.yaml"))       : yamldecode(d) if trimspace(d) != ""]
  fb_rbac_docs          = [for d in split("\n---\n", file("${path.module}/fluent-bit-rbac.yaml"))         : yamldecode(d) if trimspace(d) != ""]
  fb_ds_docs            = [for d in split("\n---\n", file("${path.module}/fluent-bit.yaml"))              : yamldecode(d) if trimspace(d) != ""]
  kibana_bootstrap_docs = [for d in split("\n---\n", file("${path.module}/kibana-bootstrap-job.yaml"))    : yamldecode(d) if trimspace(d) != ""]
  webcheck_docs         = [for d in split("\n---\n", file("${path.module}/webcheck-frontend-admin.yaml")) : yamldecode(d) if trimspace(d) != ""]

  ns_map               = { for o in local.ns_docs               : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  es_map               = { for o in local.es_docs               : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  kibana_map           = { for o in local.kibana_docs           : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  fb_config_map        = { for o in local.fb_config_docs        : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  fb_rbac_map          = { for o in local.fb_rbac_docs          : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  fb_ds_map            = { for o in local.fb_ds_docs            : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  kibana_bootstrap_map = { for o in local.kibana_bootstrap_docs : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  webcheck_map         = { for o in local.webcheck_docs         : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
}

# 1) Namespace
resource "kubernetes_manifest" "ns_monitoring" {
  for_each = local.ns_map
  manifest = each.value
}

# 2) Elasticsearch (Service + StatefulSet)
resource "kubernetes_manifest" "elasticsearch" {
  for_each = local.es_map
  manifest = each.value
  wait { rollout = true }
  depends_on = [kubernetes_manifest.ns_monitoring]
}

# 3) Kibana (Deployment + Service)
resource "kubernetes_manifest" "kibana" {
  for_each = local.kibana_map
  manifest = each.value
  wait { rollout = true }
  depends_on = [kubernetes_manifest.elasticsearch]
}

# 4) Fluent Bit (ConfigMap, RBAC, DaemonSet)
resource "kubernetes_manifest" "fluent_bit_config" {
  for_each = local.fb_config_map
  manifest = each.value
  depends_on = [kubernetes_manifest.ns_monitoring]
}

resource "kubernetes_manifest" "fluent_bit_rbac" {
  for_each = local.fb_rbac_map
  manifest = each.value
  depends_on = [kubernetes_manifest.ns_monitoring]
}

resource "kubernetes_manifest" "fluent_bit" {
  for_each = local.fb_ds_map
  manifest = each.value
  wait { rollout = true }
  depends_on = [
    kubernetes_manifest.fluent_bit_config,
    kubernetes_manifest.fluent_bit_rbac
  ]
}

# 5) Job Kibana : crée le Data View fluent-bit*
resource "kubernetes_manifest" "kibana_bootstrap" {
  for_each = local.kibana_bootstrap_map
  manifest = each.value
  depends_on = [kubernetes_manifest.kibana]
}

# 6) CronJob synthetic monitoring (frontend-admin)
resource "kubernetes_manifest" "webcheck_frontend_admin" {
  for_each = local.webcheck_map
  manifest = each.value
  depends_on = [
    kubernetes_manifest.fluent_bit,
    kubernetes_manifest.kibana
  ]
}
