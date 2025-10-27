# Módulo Terraform - GCP Monitoring

Módulo para criar alertas baseados em logs do Cloud Run no Google Cloud Platform.

## Recursos criados

- Alert Policies no Google Cloud Monitoring baseadas em logs

## Variáveis

### Obrigatórias

- `service_name` - Nome do serviço Cloud Run a ser monitorado
- `notification_channel_id` - ID do canal de notificação Google Chat

### Opcionais

- `project` - Projeto GCP. Padrão: "v3rso-project"
- `region` - Região GCP. Padrão: "us-east1"
- `environment` - Ambiente (prd, qa, hml, dev). Padrão: "prd"
- `alert_name_prefix` - Prefixo para os alertas. Padrão: ""
- `custom_alerts` - Mapa de alertas customizados. Padrão: {}

## Estrutura do custom_alerts

```hcl
custom_alerts = {
  nome_do_alerta = {
    display_name                   = "Nome exibido no GCP"
    log_filter                     = "severity=\"ERROR\" AND jsonPayload.message=~\"erro\""
    severity                       = "CRITICAL"  # CRITICAL, ERROR, WARNING
    enabled                        = true
    threshold                      = 5           # Opcional: volume de erros
    duration                       = "300s"      # Período do threshold
    notification_rate_limit_period = "300s"      # Rate limit
    auto_close_duration            = "1800s"     # Auto-close
    documentation                  = "Documentação do alerta em markdown"
  }
}
```

## Exemplos de uso

### Exemplo 1: Alerta imediato para log específico

```hcl
custom_alerts = {
  magikey_create_error = {
    display_name  = "Erro ao criar evento MagiKey"
    log_filter    = "severity=\"ERROR\" AND jsonPayload.message=~\"erro ao criar evento na magikey\""
    severity      = "CRITICAL"
    documentation = <<-DOC
      **🔴 Erro crítico ao criar evento MagiKey**

      Hóspede não conseguirá acessar o imóvel.

      **Ação:**
      1. Verificar token do building
      2. Verificar API MagiKey
    DOC
  }
}
```

### Exemplo 2: Alerta por volume (threshold)

```hcl
custom_alerts = {
  payment_failures = {
    display_name  = "Taxa alta de falhas em pagamentos"
    log_filter    = "jsonPayload.message=~\"payment.*failed\""
    threshold     = 5
    duration      = "300s"
    severity      = "ERROR"
    documentation = "Mais de 5 falhas em pagamentos em 5 minutos"
  }
}
```

### Exemplo 3: Múltiplos alertas

```hcl
custom_alerts = {
  magikey_token_error = {
    display_name = "Erro no token MagiKey"
    log_filter   = "jsonPayload.message=~\"token.*error\""
    severity     = "ERROR"
  }

  checkin_failed = {
    display_name = "Falha no check-in"
    log_filter   = "jsonPayload.message=~\"check-?in.*failed\""
    threshold    = 3
    severity     = "CRITICAL"
  }

  payment_timeout = {
    display_name = "Timeout no pagamento"
    log_filter   = "jsonPayload.message=~\"payment.*timeout\""
    enabled      = false  # Desabilitado
  }
}
```

## Filtros de logs (log_filter)

O módulo adiciona automaticamente o filtro base para o serviço:
```
resource.type="cloud_run_revision" AND resource.labels.service_name="<service_name>"
```

Você precisa fornecer apenas o filtro adicional específico do alerta.

### Exemplos de filtros:

**Busca exata:**
```hcl
log_filter = "jsonPayload.message=\"erro específico\""
```

**Busca com regex:**
```hcl
log_filter = "jsonPayload.message=~\"erro.*magikey\""
```

**Múltiplas condições (AND):**
```hcl
log_filter = "severity=\"ERROR\" AND jsonPayload.operation=\"createEvent\""
```

**Múltiplas condições (OR):**
```hcl
log_filter = "(jsonPayload.message=~\"erro 1\" OR jsonPayload.message=~\"erro 2\")"
```

## Tipos de alertas

### Alerta Imediato
Dispara em qualquer ocorrência do log (não especificar `threshold`):

```hcl
custom_alerts = {
  critical_error = {
    display_name = "Erro crítico"
    log_filter   = "severity=\"ERROR\" AND jsonPayload.message=~\"critical\""
    # Sem threshold = dispara imediatamente
  }
}
```

### Alerta por Volume
Dispara apenas se atingir um volume de ocorrências (especificar `threshold`):

```hcl
custom_alerts = {
  high_error_rate = {
    display_name = "Taxa alta de erros"
    log_filter   = "severity=\"ERROR\""
    threshold    = 5      # 5 ocorrências
    duration     = "300s" # em 5 minutos
  }
}
```

## Severidades

- `CRITICAL` - Erros críticos que requerem ação imediata
- `ERROR` - Erros que precisam de atenção
- `WARNING` - Avisos que devem ser monitorados

## Observações

- Alertas com `threshold` monitoram volume de erros em um período
- Alertas sem `threshold` disparam em qualquer ocorrência
- Documentação suporta Markdown para formatação rica
- `notification_rate_limit_period` evita spam de notificações (padrão: 5 minutos)
- `auto_close_duration` fecha automaticamente alertas sem novas ocorrências (padrão: 30 minutos)

## Recursos relacionados

- [Google Cloud Monitoring - Alert Policies](https://cloud.google.com/monitoring/alerts)
- [Log-based Alerts](https://cloud.google.com/logging/docs/alerting/log-based-alerts)
- [Logging Query Language](https://cloud.google.com/logging/docs/view/logging-query-language)
