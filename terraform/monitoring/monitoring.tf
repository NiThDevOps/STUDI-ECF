#############################################
# Applique les manifests K8s du dossier courant
# (EFK + Job Kibana + CronJob webcheck)
#############################################

locals {
  # -------- charge les YAML --------
  ns_docs               = [for d in split("\n---\n", file("${path.module}/monitoring-namespace.yaml"))    : yamldecode(d) if trimspace(d) != ""]
  es_docs               = [for d in split("\n---\n", file("${path.module}/elasticsearch.yaml"))           : yamldecode(d) if trimspace(d) != ""]
  kibana_docs           = [for d in split("\n---\n", file("${path.module}/kibana.yaml"))                  : yamldecode(d) if trimspace(d) != ""]
  fb_config_docs        = [for d in split("\n---\n", file("${path.module}/fluent-bit-config.yaml"))       : yamldecode(d) if trimspace(d) != ""]
  fb_rbac_docs          = [for d in split("\n---\n", file("${path.module}/fluent-bit-rbac.yaml"))         : yamldecode(d) if trimspace(d) != ""]
  fb_ds_docs            = [for d in split("\n---\n", file("${path.module}/fluent-bit.yaml"))              : yamldecode(d) if trimspace(d) != ""]
  kibana_bootstrap_docs = [for d in split("\n---\n", file("${path.module}/kibana-bootstrap-job.yaml"))    : yamldecode(d) if trimspace(d) != ""]
  webcheck_docs         = [for d in split("\n---\n", file("${path.module}/webcheck-frontend-admin.yaml")) : yamldecode(d) if trimspace(d) != ""]

  # -------- maps complètes (clé stable kind/ns/name) --------
  ns_map               = { for o in local.ns_docs               : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  es_map               = { for o in local.es_docs               : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  kibana_map           = { for o in local.kibana_docs           : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  fb_config_map        = { for o in local.fb_config_docs        : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  fb_rbac_map          = { for o in local.fb_rbac_docs          : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  fb_ds_map            = { for o in local.fb_ds_docs            : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  kibana_bootstrap_map = { for o in local.kibana_bootstrap_docs : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  webcheck_map         = { for o in local.webcheck_docs         : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }

  # -------- sous-maps par type (pour gérer wait proprement) --------
  es_service_map      = { for k, v in local.es_map      : k => v if v.kind == "Service" }
  es_statefulset_map  = { for k, v in local.es_map      : k => v if v.kind == "StatefulSet" }

  kibana_service_map  = { for k, v in local.kibana_map  : k => v if v.kind == "Service" }
  kibana_deploy_map   = { for k, v in local.kibana_map  : k => v if v.kind == "Deployment" }

  fb_sa_map           = { for k, v in local.fb_ds_map   : k => v if v.kind == "ServiceAccount" }
  fb_daemonset_map    = { for k, v in local.fb_ds_map   : k => v if v.kind == "DaemonSet" }
}

# 1) Namespace
resource "kubernetes_manifest" "ns_monitoring" {
  for_each = local.ns_map
  manifest = each.value
}

# 2) Elasticsearch
## 2a) Service (pas de wait)
resource "kubernetes_manifest" "elasticsearch_svc" {
  for_each = local.es_service_map
  manifest = each.value
  depends_on = [kubernetes_manifest.ns_monitoring]
}

## 2b) StatefulSet (wait rollout)
resource "kubernetes_manifest" "elasticsearch_sts" {
  for_each = local.es_statefulset_map
  manifest = each.value
  wait { rollout = true }
  depends_on = [kubernetes_manifest.ns_monitoring]
}

# 3) Kibana
## 3a) Service (pas de wait)
resource "kubernetes_manifest" "kibana_svc" {
  for_each = local.kibana_service_map
  manifest = each.value
  depends_on = [kubernetes_manifest.elasticsearch_sts]
}

## 3b) Deployment (wait rollout)
resource "kubernetes_manifest" "kibana_deploy" {
  for_each = local.kibana_deploy_map
  manifest = each.value
  wait { rollout = true }
  depends_on = [kubernetes_manifest.elasticsearch_sts]
}

# 4) Fluent Bit
## 4a) ConfigMap (pas de wait)
resource "kubernetes_manifest" "fluent_bit_config" {
  for_each = local.fb_config_map
  manifest = each.value
  depends_on = [kubernetes_manifest.ns_monitoring]
}

## 4b) RBAC (pas de wait)
resource "kubernetes_manifest" "fluent_bit_rbac" {
  for_each = local.fb_rbac_map
  manifest = each.value
  depends_on = [kubernetes_manifest.ns_monitoring]
}

## 4c) ServiceAccount (pas de wait)
resource "kubernetes_manifest" "fluent_bit_sa" {
  for_each = local.fb_sa_map
  manifest = each.value
  depends_on = [
    kubernetes_manifest.fluent_bit_config,
    kubernetes_manifest.fluent_bit_rbac
  ]
}

## 4d) DaemonSet (wait rollout)
resource "kubernetes_manifest" "fluent_bit_ds" {
  for_each = local.fb_daemonset_map
  manifest = each.value
  wait { rollout = true }
  depends_on = [
    kubernetes_manifest.fluent_bit_config,
    kubernetes_manifest.fluent_bit_rbac,
    kubernetes_manifest.fluent_bit_sa
  ]
}

# 5) Job Kibana : crée le Data View fluent-bit*
resource "kubernetes_manifest" "kibana_bootstrap" {
  for_each = local.kibana_bootstrap_map
  manifest = each.value
  depends_on = [
    kubernetes_manifest.kibana_deploy,
    kubernetes_manifest.kibana_svc
  ]
}

# 6) CronJob synthetic monitoring (frontend-admin)
resource "kubernetes_manifest" "webcheck_frontend_admin" {
  for_each = local.webcheck_map
  manifest = each.value
  depends_on = [
    kubernetes_manifest.fluent_bit_ds,
    kubernetes_manifest.kibana_deploy
  ]
}
