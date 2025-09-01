#############################################
# Applique les manifests K8s du dossier courant
# (EFK + Job Kibana + CronJob webcheck)
# -> Le namespace "monitoring" est créé dans le workflow (kubectl), pas ici
#############################################

locals {
  #######################
  # Chargement robuste des YAML :
  # - fileset() renvoie une liste (vide si le fichier n'existe pas)
  # - flatten([...]) évite tout problème de type
  #######################

  es_docs = flatten([
    for f in fileset(path.module, "elasticsearch.yaml") : [
      for d in split("\n---\n", file("${path.module}/${f}")) :
      yamldecode(d) if trimspace(d) != ""
    ]
  ])

  kibana_docs = flatten([
    for f in fileset(path.module, "kibana.yaml") : [
      for d in split("\n---\n", file("${path.module}/${f}")) :
      yamldecode(d) if trimspace(d) != ""
    ]
  ])

  fb_config_docs = flatten([
    for f in fileset(path.module, "fluent-bit-config.yaml") : [
      for d in split("\n---\n", file("${path.module}/${f}")) :
      yamldecode(d) if trimspace(d) != ""
    ]
  ])

  fb_rbac_docs = flatten([
    for f in fileset(path.module, "fluent-bit-rbac.yaml") : [
      for d in split("\n---\n", file("${path.module}/${f}")) :
      yamldecode(d) if trimspace(d) != ""
    ]
  ])

  fb_ds_docs = flatten([
    for f in fileset(path.module, "fluent-bit.yaml") : [
      for d in split("\n---\n", file("${path.module}/${f}")) :
      yamldecode(d) if trimspace(d) != ""
    ]
  ])

  kibana_bootstrap_docs = flatten([
    for f in fileset(path.module, "kibana-bootstrap-job.yaml") : [
      for d in split("\n---\n", file("${path.module}/${f}")) :
      yamldecode(d) if trimspace(d) != ""
    ]
  ])

  webcheck_docs = flatten([
    for f in fileset(path.module, "webcheck-frontend-admin.yaml") : [
      for d in split("\n---\n", file("${path.module}/${f}")) :
      yamldecode(d) if trimspace(d) != ""
    ]
  ])

  # Maps (clé stable : kind/ns/name)
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

#############################################
# 1) Elasticsearch
#############################################

# Service (pas de wait)
resource "kubernetes_manifest" "elasticsearch_svc" {
  for_each = local.es_service_map
  manifest = each.value
}

# StatefulSet (wait rollout)
resource "kubernetes_manifest" "elasticsearch_sts" {
  for_each = local.es_statefulset_map
  manifest = each.value
  wait { rollout = true }
}

#############################################
# 2) Kibana
#############################################

# Service (pas de wait)
resource "kubernetes_manifest" "kibana_svc" {
  for_each = local.kibana_service_map
  manifest = each.value
  depends_on = [kubernetes_manifest.elasticsearch_sts]
}

# Deployment (wait rollout)
resource "kubernetes_manifest" "kibana_deploy" {
  for_each = local.kibana_deploy_map
  manifest = each.value
  wait { rollout = true }
  depends_on = [kubernetes_manifest.elasticsearch_sts]
}

#############################################
# 3) Fluent Bit
#############################################

# ConfigMap (pas de wait)
resource "kubernetes_manifest" "fluent_bit_config" {
  for_each = local.fb_config_map
  manifest = each.value
}

# RBAC (pas de wait)
resource "kubernetes_manifest" "fluent_bit_rbac" {
  for_each = local.fb_rbac_map
  manifest = each.value
}

# ServiceAccount (pas de wait)
resource "kubernetes_manifest" "fluent_bit_sa" {
  for_each = local.fb_sa_map
  manifest = each.value
  depends_on = [
    kubernetes_manifest.fluent_bit_config,
    kubernetes_manifest.fluent_bit_rbac
  ]
}

# DaemonSet (wait rollout)
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

#############################################
# 4) Job Kibana : Data View fluent-bit*
#############################################

resource "kubernetes_manifest" "kibana_bootstrap" {
  for_each = local.kibana_bootstrap_map
  manifest = each.value
  depends_on = [
    kubernetes_manifest.kibana_deploy,
    kubernetes_manifest.kibana_svc
  ]
}

#############################################
# 5) CronJob synthetic monitoring (frontend-admin)
#############################################

resource "kubernetes_manifest" "webcheck_frontend_admin" {
  for_each = local.webcheck_map
  manifest = each.value
  depends_on = [
    kubernetes_manifest.fluent_bit_ds,
    kubernetes_manifest.kibana_deploy
  ]
}
