# ========================================
# CONFIGURAÇÕES DO SERVIÇO
# ========================================

variable "service_name" {
  type        = string
  description = "Nome do serviço Cloud Run a ser monitorado"
}

variable "environment" {
  type        = string
  description = "Ambiente (prd, qa, hml, dev)"
  default     = "prd"
}

# ========================================
# NOTIFICATION CHANNEL
# ========================================

variable "notification_channel_id" {
  type        = string
  description = "ID do canal de notificação Google Chat"
}

# ========================================
# CONFIGURAÇÕES DE ALERTAS
# ========================================

variable "alert_name_prefix" {
  type        = string
  description = "Prefixo para os nomes dos alertas (ex: PRD, QA)"
  default     = ""
}

variable "custom_alerts" {
  type = map(object({
    display_name                   = string
    log_filter                     = string
    severity                       = optional(string, "ERROR")
    enabled                        = optional(bool, true)
    threshold                      = optional(number)
    duration                       = optional(string, "300s")
    notification_rate_limit_period = optional(string, "300s")
    auto_close_duration            = optional(string, "1800s")
    documentation                  = optional(string, "")
    notification_channel_ids       = optional(list(string), null)
  }))
  description = "Mapa de alertas customizados baseados em logs"
  default     = {}
}
