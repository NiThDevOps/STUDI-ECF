#############################################
# Applique les manifests K8s du dossier courant
# (EFK + Job Kibana + CronJob webcheck)
# -> Le namespace "monitoring" est créé dans le workflow (kubectl), pas ici
#############################################

locals {
  # --- charge chaque fichier s'il existe (évite les erreurs si certains sont absents) ---
  es_docs               = fileexists("${path.module}/elasticsearch.yaml")            ? [for d in split("\n---\n", file("${path.module}/elasticsearch.yaml"))            : yamldecode(d) if trimspace(d) != ""] : []
  kibana_docs           = fileexists("${path.module}/kibana.yaml")                   ? [for d in split("\n---\n", file("${path.module}/kibana.yaml"))                   : yamldecode(d) if trimspace(d) != ""] : []
  fb_config_docs        = fileexists("${path.module}/fluent-bit-config.yaml")        ? [for d in split("\n---\n", file("${path.module}/fluent-bit-config.yaml"))        : yamldecode(d) if trimspace(d) != ""] : []
  fb_rbac_docs          = fileexists("${path.module}/fluent-bit-rbac.yaml")          ? [for d in split("\n---\n", file("${path.module}/fluent-bit-rbac.yaml"))          : yamldecode(d) if trimspace(d) != ""] : []
  fb_ds_docs            = fileexists("${path.module}/fluent-bit.yaml")               ? [for d in split("\n---\n", file("${path.module}/fluent-bit.yaml"))               : yamldecode(d) if trimspace(d) != ""] : []
  kibana_bootstrap_docs = fileexists("${path.module}/kibana-bootstrap-job.yaml")     ? [for d in split("\n---\n", file("${path.module}/kibana-bootstrap-job.yaml"))     : yamldecode(d) if trimspace(d) != ""] : []
  webcheck_docs         = fileexists("${path.module}/webcheck-frontend-admin.yaml")  ? [for d in split("\n---\n", file("${path.module}/webcheck-frontend-admin.yaml"))  : yamldecode(d) if trimspace(d) != ""] : []

  es_map               = { for o in local.es_docs               : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  kibana_map           = { for o in local.kibana_docs           : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  fb_config_map        = { for o in local.fb_config_docs        : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  fb_rbac_map          = { for o in local.fb_rbac_docs          : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  fb_ds_map            = { for o in local.fb_ds_docs            : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  kibana_bootstrap_map = { for o in local.kibana_bootstrap_docs : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }
  webcheck_map         = { for o in local.webcheck_docs         : format("%s/%s/%s", o.kind, lookup(o.metadata, "namespace", "default"), o.metadata.name) => o }

  # sous-maps pour gérer wait correctement
  es_service_map      = { for k, v in local.es_map      : k => v if v.kind == "Service" }
  es_statefulset_map  = { for k, v in local.es_map      : k => v if v.kind == "StatefulSet" }

  kibana_service_map  = { for k, v in local.kibana_map  : k => v if v.kind == "Service" }
  kibana_deploy_map   = { for k, v in local.kibana_map  : k => v if v.kind == "Deployment" }

  fb_sa_map           = { for k, v in local.fb_ds_map   : k => v if v.kind == "ServiceAccount" }
  fb_daemonset_map    = { for k, v in local.fb_ds_map   : k => v if v.kind == "DaemonSet" }
}

# 1) Elasticsearch
## 1a) Service (pas de wait)
resource "kubernetes_manifest" "elasticsearch_svc" {
  for_each = local.es_service_map
  manifest = each.value
}

## 1b) StatefulSet (wait rollout)
resource "kubernetes_manifest" "elasticsearch_sts" {
  for_each = local.es_statefulset_map
  manifest = each.value
  wait { rollout = true }
}

# 2) Kibana
## 2a) Service (pas de wait)
resource "kubernetes_manifest" "kibana_svc" {
  for_each = local.kibana_service_map
  manifest = each.value
  depends_on = [kubernetes_manifest.elasticsearch_sts]
}

## 2b) Deployment (wait rollout)
resource "kubernetes_manifest" "kibana_deploy" {
  for_each = local.kibana_deploy_map
  manifest = each.value
  wait { rollout = true }
  depends_on = [kubernetes_manifest.elasticsearch_sts]
}

# 3) Fluent Bit
## 3a) ConfigMap (pas de wait)
resource "kubernetes_manifest" "fluent_bit_config" {
  for_each = local.fb_config_map
  manifest = each.value
}

## 3b) RBAC (pas de wait)
resource "kubernetes_manifest" "fluent_bit_rbac" {
  for_each = local.fb_rbac_map
  manifest = each.value
}

## 3c) ServiceAccount (pas de wait)
resource "kubernetes_manifest" "fluent_bit_sa" {
  for_each = local.fb_sa_map
  manifest = each.value
  depends_on = [
    kubernetes_manifest.fluent_bit_config,
    kubernetes_manifest.fluent_bit_rbac
  ]
}

## 3d) DaemonSet (wait rollout)
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

# 4) Job Kibana : Data View fluent-bit*
resource "kubernetes_manifest" "kibana_bootstrap" {
  for_each = local.kibana_bootstrap_map
  manifest = each.value
  depends_on = [
    kubernetes_manifest.kibana_deploy,
    kubernetes_manifest.kibana_svc
  ]
}

# 5) CronJob synthetic monitoring (frontend-admin)
resource "kubernetes_manifest" "webcheck_frontend_admin" {
  for_each = local.webcheck_map
  manifest = each.value
  depends_on = [
    kubernetes_manifest.fluent_bit_ds,
    kubernetes_manifest.kibana_deploy
  ]
}
