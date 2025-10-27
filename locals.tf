locals {
  # Prefixo do nome dos alertas
  alert_prefix = var.alert_name_prefix != "" ? "${var.alert_name_prefix} - " : ""

  # Filtro base comum a todos os alertas
  base_filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.service_name}\""

  # Apenas alertas habilitados
  enabled_alerts = { for k, v in var.custom_alerts : k => v if v.enabled }
}
