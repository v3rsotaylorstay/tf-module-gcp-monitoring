# Como usar no Foundation

## Estrutura no tf-module-gcp-foundation

```
tf-module-gcp-foundation/
└── prd/
    └── us-east1/
        └── monitoring/
            └── door-control/
                ├── terragrunt.hcl
                └── local.tfvars
```

## Arquivo: terragrunt.hcl

```hcl
terraform {
  source = "git@github.com:v3rsotaylorstay/tf-module-gcp-monitoring"

  extra_arguments "custom_vars" {
    commands = ["apply", "console", "destroy", "import", "plan", "push", "refresh"]
    arguments = [
      "-var-file=${get_terragrunt_dir()}/local.tfvars",
    ]
  }
}

include {
  path = find_in_parent_folders()
}
```

## Arquivo: local.tfvars

### Exemplo inicial (vazio)

```hcl
project                 = "v3rso-prd"
region                  = "us-east1"
service_name            = "be-service-door-control"
environment             = "prd"
notification_channel_id = "projects/v3rso-prd/notificationChannels/XXXXXXXXXX"
alert_name_prefix       = "PRD"

# Alertas - adicionar conforme necessário
custom_alerts = {}
```

### Exemplo com alertas MagiKey

```hcl
project                 = "v3rso-prd"
region                  = "us-east1"
service_name            = "be-service-door-control"
environment             = "prd"
notification_channel_id = "projects/v3rso-prd/notificationChannels/XXXXXXXXXX"
alert_name_prefix       = "PRD"

custom_alerts = {
  # Alerta 1: Erro ao criar evento MagiKey (CRÍTICO)
  magikey_create_event_error = {
    display_name  = "Erro ao criar evento MagiKey"
    log_filter    = "severity=\"ERROR\" AND jsonPayload.message=~\"erro ao criar evento na magikey\""
    severity      = "CRITICAL"
    documentation = <<-DOC
      **🔴 ALERTA CRÍTICO: Erro ao criar evento MagiKey**

      **Impacto:** Hóspede não consegue acessar o imóvel

      **Ação imediata:**
      1. Verificar token do building no Secret Manager
      2. Verificar status da API MagiKey
      3. Verificar logs completos:
         ```
         gcloud logging read "resource.labels.service_name=be-service-door-control AND jsonPayload.message=~\"erro ao criar evento\"" --limit 20
         ```

      **Contato:** Time de operações
    DOC
  }

  # Alerta 2: Erro no token MagiKey
  magikey_token_error = {
    display_name  = "Erro ao obter token MagiKey"
    log_filter    = "jsonPayload.message=~\"Error retrieving token path\""
    severity      = "ERROR"
    documentation = "Token do building não encontrado no banco de dados ou Secret Manager"
  }

  # Alerta 3: Taxa alta de falhas HTTP (threshold)
  magikey_http_failures = {
    display_name = "Taxa alta de falhas HTTP MagiKey"
    log_filter   = "jsonPayload.message=~\"Failed to send HTTP request\""
    threshold    = 5
    duration     = "300s"
    severity     = "WARNING"
    documentation = "Mais de 5 falhas HTTP para MagiKey em 5 minutos - API pode estar instável"
  }
}
```

## Como obter o notification_channel_id

```bash
# Listar canais de notificação disponíveis
gcloud alpha monitoring channels list \
  --project=v3rso-prd \
  --filter="type=chat" \
  --format="table(name,displayName)"

# Output exemplo:
# NAME                                                          DISPLAY_NAME
# projects/v3rso-prd/notificationChannels/1234567890123456789  Google Chat - PRD Alerts
```

Use o valor da coluna `NAME` como `notification_channel_id`.

## Passos para aplicar

### 1. Criar a estrutura no Foundation

```bash
cd /path/to/tf-module-gcp-foundation

# Checkout na branch prd
git checkout prd
git pull origin prd

# Criar nova branch
git checkout -b feature/add-monitoring-door-control

# Criar estrutura de pastas
mkdir -p prd/us-east1/monitoring/door-control
```

### 2. Criar os arquivos

```bash
# Criar terragrunt.hcl
cat > prd/us-east1/monitoring/door-control/terragrunt.hcl << 'EOF'
terraform {
  source = "git@github.com:v3rsotaylorstay/tf-module-gcp-monitoring"

  extra_arguments "custom_vars" {
    commands = ["apply", "console", "destroy", "import", "plan", "push", "refresh"]
    arguments = [
      "-var-file=${get_terragrunt_dir()}/local.tfvars",
    ]
  }
}

include {
  path = find_in_parent_folders()
}
EOF

# Criar local.tfvars (inicialmente vazio)
cat > prd/us-east1/monitoring/door-control/local.tfvars << 'EOF'
project                 = "v3rso-prd"
region                  = "us-east1"
service_name            = "be-service-door-control"
environment             = "prd"
notification_channel_id = "projects/v3rso-prd/notificationChannels/XXXXXXXXXX"
alert_name_prefix       = "PRD"

custom_alerts = {}
EOF
```

### 3. Commit e criar PR

```bash
# Adicionar arquivos
git add prd/us-east1/monitoring/door-control/

# Commit
git commit -m "feat: add monitoring alerts for door-control service"

# Push
git push origin feature/add-monitoring-door-control

# Criar PR (via GitHub UI ou gh CLI)
gh pr create --base prd \
  --title "feat: Add monitoring alerts for door-control" \
  --body "Adiciona estrutura de alertas de monitoramento para o serviço door-control.

Inicialmente configurado sem alertas. Os alertas serão adicionados incrementalmente."
```

### 4. Após merge

O Cloud Build vai:
1. Detectar mudança em `prd/us-east1/monitoring/door-control/`
2. Executar `terragrunt init`
3. Executar `terragrunt plan`
4. Executar `terragrunt apply -auto-approve`

Como `custom_alerts = {}`, nenhum alerta será criado ainda (estrutura pronta para receber).

### 5. Adicionar alertas incrementalmente

Para adicionar alertas depois:

1. Editar `local.tfvars` adicionando alertas em `custom_alerts`
2. Commit e PR novamente
3. Após merge, Cloud Build aplica os novos alertas

## Exemplo de adição incremental

**Commit 1:** Estrutura vazia
```hcl
custom_alerts = {}
```

**Commit 2:** Adicionar primeiro alerta
```hcl
custom_alerts = {
  magikey_create_error = {
    display_name = "Erro ao criar evento MagiKey"
    log_filter   = "severity=\"ERROR\" AND jsonPayload.message=~\"erro ao criar evento\""
    severity     = "CRITICAL"
  }
}
```

**Commit 3:** Adicionar mais alertas
```hcl
custom_alerts = {
  magikey_create_error = { ... },

  magikey_token_error = {
    display_name = "Erro no token MagiKey"
    log_filter   = "jsonPayload.message=~\"token.*error\""
    severity     = "ERROR"
  }
}
```

## Validar alertas criados

```bash
# Listar alertas criados
gcloud alpha monitoring policies list \
  --project=v3rso-prd \
  --filter="displayName:door-control OR displayName:PRD" \
  --format="table(displayName,enabled)"

# Ver detalhes de um alerta
gcloud alpha monitoring policies describe POLICY_ID --project=v3rso-prd
```
