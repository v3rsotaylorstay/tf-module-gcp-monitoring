# ========================================
# LOG-BASED ALERT POLICIES
# ========================================

resource "google_monitoring_alert_policy" "custom_log_alert" {
  for_each = local.enabled_alerts

  display_name = "${local.alert_prefix}${each.value.display_name}"
  combiner     = "OR"
  enabled      = each.value.enabled

  conditions {
    display_name = each.value.display_name

    # Alerta com threshold (volume de erros)
    dynamic "condition_threshold" {
      for_each = each.value.threshold != null ? [1] : []

      content {
        filter          = "${local.base_filter} AND ${each.value.log_filter}"
        comparison      = "COMPARISON_GT"
        threshold_value = each.value.threshold
        duration        = each.value.duration

        aggregations {
          alignment_period   = "60s"
          per_series_aligner = "ALIGN_RATE"
        }
      }
    }

    # Alerta imediato (log matched)
    dynamic "condition_matched_log" {
      for_each = each.value.threshold == null ? [1] : []

      content {
        filter = "${local.base_filter} AND ${each.value.log_filter}"
      }
    }
  }

  notification_channels = (
    each.value.notification_channel_ids != null 
      ? each.value.notification_channel_ids 
      : [var.notification_channel_id]
  )

  alert_strategy {
    notification_rate_limit {
      period = each.value.notification_rate_limit_period
    }
    auto_close = each.value.auto_close_duration
  }

  documentation {
    content   = each.value.documentation
    mime_type = "text/markdown"
  }
}
