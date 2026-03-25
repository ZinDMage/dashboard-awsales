# Data Model Requirements - ATUALIZADO COM DDL REAL

## Database Schema Completo

O AwSales Dashboard utiliza um banco de dados PostgreSQL no Supabase com **16 tabelas principais** contendo aproximadamente **111MB de dados** e **57.064 registros**.

### Extensões e Funções Auxiliares

**Extensões:**
- `uuid-ossp` - Geração de UUIDs

**Funções Auxiliares:**
- `cf_val(field jsonb)` - Extrai valor de campo custom JSONB
- `set_updated_at()` - Trigger para atualizar `updated_at` automaticamente
- `dashboard_data(p_start date, p_end date)` - Função principal que agrega métricas do dashboard

---

## 1. TABELA: `sales` (Vendas Fechadas)

**Propósito:** Armazena todas as vendas concretizadas da plataforma

**Campos:**

| Campo | Tipo | Descrição | Constraints |
|-------|------|-----------|-------------|
| `id` | bigint | ID único | PRIMARY KEY |
| `email_stripe` | text | Email do cliente no Stripe | |
| `email_pipedrive` | text | Email do cliente no Pipedrive | |
| `nome` | text | Nome do cliente | NOT NULL |
| `gerente_responsavel` | text | Gerente responsável pela conta | |
| `data_fechamento` | date | Data de fechamento da venda | INDEX |
| `mes` | text | Mês da venda (formato texto) | INDEX |
| `plano` | text | Nome do plano contratado | NOT NULL, INDEX |
| `fonte` | text | Fonte/origem da venda | INDEX |
| `vendedor` | text | Nome do vendedor | |
| `afiliado` | text | Afiliado responsável | |
| `segmento` | text | Segmento de mercado | |
| `isencao_1_mes` | boolean | Cliente tem isenção no 1º mês | DEFAULT false |
| `receita_plano` | numeric | Receita do plano contratado | DEFAULT 0 |
| `implantacao` | numeric | Valor de implantação cobrado | DEFAULT 0 |
| `receita_gerada` | numeric | Receita total gerada | DEFAULT 0 |
| `status` | text | Status da venda (Won/Churn) | INDEX |
| `data_prevista` | text | Data prevista de renovação | |
| `obs` | text | Observações | |
| `created_at` | timestamptz | Data de criação do registro | DEFAULT now() |
| `updated_at` | timestamptz | Data de atualização do registro | DEFAULT now() |

**Índices:**
- `idx_sales_data_fechamento` - Performance em queries por data
- `idx_sales_mes` - Agregação por mês
- `idx_sales_plano` - Filtros por plano
- `idx_sales_fonte` - Análise por fonte
- `idx_sales_status` - Filtro por status (Won/Churn)

**Regras de Negócio:**
- **Receita Total** = SUM(`receita_gerada`) WHERE `data_fechamento` no período
- **Vendas** = COUNT(*) WHERE `data_fechamento` no período
- **Ticket Médio** = Receita Total / Vendas
- **Churn** = SUM(`receita_gerada`) WHERE `status` = 'Churn'
- **Margem de Contribuição** = Receita - (Receita * 0.17) - Churn

**RLS (Row Level Security):**
- ✅ Habilitado
- Policy: "Allow authenticated select" - Usuários autenticados podem ler

---

## 2. TABELA: `meta_ads_costs` (Custos Meta Ads)

**Propósito:** Custos diários de campanhas no Meta Ads (Facebook/Instagram)

**Campos:**

| Campo | Tipo | Descrição | Constraints |
|-------|------|-----------|-------------|
| `id` | bigint | ID único | PRIMARY KEY |
| `ad_id` | text | ID do anúncio no Meta | NOT NULL, UNIQUE (com date) |
| `campaign_id` | text | ID da campanha | NOT NULL, INDEX |
| `campaign_name` | text | Nome da campanha | NOT NULL, INDEX |
| `adset_id` | text | ID do conjunto de anúncios | NOT NULL, INDEX |
| `adset_name` | text | Nome do conjunto de anúncios | NOT NULL, INDEX |
| `ad_name` | text | Nome do anúncio | NOT NULL |
| `date_start` | date | Data de início do período | NOT NULL, INDEX, UNIQUE |
| `date_stop` | date | Data de fim do período | NOT NULL, UNIQUE |
| `impressions` | integer | Número de impressões | DEFAULT 0, NOT NULL |
| `clicks` | integer | Número de cliques | DEFAULT 0, NOT NULL |
| `spend` | numeric | Valor gasto em R$ | DEFAULT 0, NOT NULL |
| `ctr` | numeric | Click-through rate (calculado) | |
| `cpc` | numeric | Custo por clique (calculado) | |
| `cpm` | numeric | Custo por mil impressões (calculado) | |
| `created_at` | timestamptz | Data de criação | DEFAULT now() |
| `updated_at` | timestamptz | Data de atualização | DEFAULT now() |

**Constraints Únicos:**
- `uq_meta_ads_costs_ad_date` - UNIQUE(ad_id, date_start, date_stop)

**Índices:**
- `idx_meta_ads_costs_ad_id`
- `idx_meta_ads_costs_campaign_id`
- `idx_meta_ads_costs_campaign`
- `idx_meta_ads_costs_adset_id`
- `idx_meta_ads_costs_adset`
- `idx_meta_ads_costs_date_start`

**Agregação:**
- Gasto Total em Ads = SUM(`spend`) por período
- Impressões = SUM(`impressions`)
- Cliques = SUM(`clicks`)

**RLS:**
- ✅ Habilitado
- Policy: "Allow authenticated select"

---

## 3. TABELA: `meta_ads_actions` (Ações Meta Ads)

**Propósito:** Ações de usuários nos anúncios Meta (cliques, conversões, etc.)

**Campos:**

| Campo | Tipo | Descrição | Constraints |
|-------|------|-----------|-------------|
| `id` | bigint | ID único | PRIMARY KEY |
| `meta_ads_cost_id` | bigint | FK para meta_ads_costs | NOT NULL, FK, INDEX |
| `ad_id` | text | ID do anúncio | NOT NULL, INDEX |
| `campaign_id` | text | ID da campanha | NOT NULL, INDEX |
| `adset_id` | text | ID do adset | NOT NULL, INDEX |
| `date_start` | date | Data de início | NOT NULL, INDEX |
| `date_stop` | date | Data de fim | NOT NULL |
| `action_type` | text | Tipo de ação | NOT NULL, INDEX |
| `value` | integer | Quantidade de ações | DEFAULT 0, NOT NULL |
| `created_at` | timestamptz | Data de criação | DEFAULT now() |
| `updated_at` | timestamptz | Data de atualização | DEFAULT now() |

**Action Types Principais:**
- `unique_outbound_outbound_click` - Cliques de saída únicos
- `landing_page_view` - Visualizações de página de destino

**Constraints Únicos:**
- `uq_meta_ads_actions_ad_date_type` - UNIQUE(ad_id, date_start, date_stop, action_type)

**Foreign Keys:**
- `meta_ads_actions_meta_ads_cost_id_fkey` → `meta_ads_costs(id)` ON DELETE CASCADE

**Regras de Negócio:**
- **Cliques** = SUM(`value`) WHERE `action_type` = 'unique_outbound_outbound_click'
- **View Page** = SUM(`value`) WHERE `action_type` = 'landing_page_view'

**RLS:**
- ✅ Habilitado
- Policy: "Allow authenticated select"

---

## 4. TABELA: `google_ads_costs` (Custos Google Ads)

**Propósito:** Custos diários de campanhas no Google Ads

**Campos:**

| Campo | Tipo | Descrição | Constraints |
|-------|------|-----------|-------------|
| `id` | bigint | ID único | PRIMARY KEY |
| `campaign_id` | text | ID da campanha | NOT NULL, INDEX |
| `campaign_name` | text | Nome da campanha | NOT NULL |
| `campaign_status` | text | Status da campanha | |
| `ad_group_id` | text | ID do grupo de anúncios | NOT NULL, INDEX |
| `ad_group_name` | text | Nome do grupo de anúncios | NOT NULL |
| `date` | date | Data do registro | NOT NULL, INDEX |
| `device` | text | Dispositivo (Mobile/Desktop/Tablet) | NOT NULL, INDEX |
| `impressions` | integer | Número de impressões | DEFAULT 0, NOT NULL |
| `clicks` | integer | Número de cliques | DEFAULT 0, NOT NULL |
| `spend` | numeric | Valor gasto em R$ | DEFAULT 0, NOT NULL |
| `average_cpc` | numeric | CPC médio | DEFAULT 0 |
| `conversions` | numeric | Conversões (view page) | DEFAULT 0, NOT NULL |
| `all_conversions` | numeric | Todas as conversões | DEFAULT 0, NOT NULL |
| `conversions_value` | numeric | Valor das conversões | DEFAULT 0, NOT NULL |
| `ctr` | numeric | Click-through rate | |
| `cpm` | numeric | Custo por mil impressões | |
| `cost_per_conversion` | numeric | Custo por conversão | |
| `created_at` | timestamptz | Data de criação | DEFAULT now() |
| `updated_at` | timestamptz | Data de atualização | DEFAULT now() |

**Constraints Únicos:**
- `uq_google_ads_costs_adgroup_device_date` - UNIQUE(ad_group_id, device, date)

**Índices:**
- `idx_google_ads_costs_campaign_id`
- `idx_google_ads_costs_ad_group_id`
- `idx_google_ads_costs_date`
- `idx_google_ads_costs_device`

**Agregação:**
- Gasto = SUM(`spend`)
- Cliques = SUM(`clicks`)
- Impressões = SUM(`impressions`)
- View Page = SUM(`conversions`)

**RLS:**
- ✅ Habilitado
- Policy: "Allow authenticated select"

---

## 5. TABELA: `linkedin_ads_costs` (Custos LinkedIn Ads)

**Propósito:** Custos diários de campanhas no LinkedIn Ads

**Campos:**

| Campo | Tipo | Descrição | Constraints |
|-------|------|-----------|-------------|
| `id` | bigint | ID único | PRIMARY KEY |
| `creative_urn` | text | URN do criativo | NOT NULL, UNIQUE (com date) |
| `creative_id` | text | ID do criativo | INDEX |
| `date` | date | Data do registro | NOT NULL, INDEX |
| `impressions` | integer | Número de impressões | DEFAULT 0, NOT NULL |
| `clicks` | integer | Número de cliques | DEFAULT 0, NOT NULL |
| `spend` | numeric | Valor gasto em R$ | DEFAULT 0, NOT NULL |
| `leads` | integer | Leads gerados | DEFAULT 0, NOT NULL |
| `video_views` | integer | Visualizações de vídeo | DEFAULT 0, NOT NULL |
| `external_conversions` | integer | Conversões externas | DEFAULT 0, NOT NULL |
| `unique_impressions` | integer | Impressões únicas | DEFAULT 0, NOT NULL |
| `ctr` | numeric | Click-through rate | |
| `cpc` | numeric | Custo por clique | |
| `cpm` | numeric | Custo por mil impressões | |
| `cpl` | numeric | Custo por lead | |
| `created_at` | timestamptz | Data de criação | DEFAULT now() |
| `updated_at` | timestamptz | Data de atualização | DEFAULT now() |

**Constraints Únicos:**
- `uq_linkedin_ads_creative_date` - UNIQUE(creative_urn, date)

**Índices:**
- `idx_linkedin_ads_creative_urn`
- `idx_linkedin_ads_creative_id`
- `idx_linkedin_ads_date`

**RLS:**
- ✅ Habilitado

---

## 6. TABELA: `yayforms_responses` (Formulário de Qualificação)

**Propósito:** Leads capturados através do formulário de qualificação

**Campos Principais:**

| Campo | Tipo | Descrição | Constraints |
|-------|------|-----------|-------------|
| `id` | uuid | ID único | PRIMARY KEY, DEFAULT uuid_generate_v4() |
| `external_id` | text | ID externo do YayForms | NOT NULL, UNIQUE |
| `form_id` | text | ID do formulário | NOT NULL |
| `lead_name` | text | Nome do lead | |
| `lead_email` | text | Email do lead | INDEX |
| `lead_phone` | text | Telefone do lead | INDEX |
| `lead_project_url` | text | URL do projeto | |
| `lead_market` | text | Mercado do lead | INDEX |
| `lead_segment` | text | Segmento de mercado | INDEX |
| `lead_revenue_range` | text | Faixa de faturamento anual | INDEX |
| `lead_monthly_volume` | text | Volume mensal de tickets | INDEX |
| `score` | integer | Score de qualificação | DEFAULT 0, INDEX |
| `variable_2` | integer | Variável customizada 2 | DEFAULT 0 |
| `variable_3` | integer | Variável customizada 3 | DEFAULT 0 |
| `ai_feedback` | jsonb | Feedback da IA | |

**Campos de Tracking (UTM):**
- `utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term` (INDEX em source e campaign)
- `fbc`, `fbp` - Facebook tracking
- `ga_client_id`, `ga_session` - Google Analytics
- `gcl_au` - Google Click ID
- `ttcsid`, `ttp` - TikTok tracking
- `clck`, `clsk` - Click tracking

**Campos de Geolocalização:**
- `geo_country_code` (varchar 5), `geo_country_name`, `geo_region` (varchar 5)
- `geo_state`, `geo_city`, `geo_zipcode` (varchar 20)
- `geo_latitude` (numeric), `geo_longitude` (numeric), `geo_timezone`

**Campos de Dispositivo:**
- `device_type`, `operating_system`, `os_version`
- `browser`, `browser_version`, `user_agent`
- `ip_address`, `referrer_url`

**Campos de Timing:**
- `started_at` (timestamptz) - Quando começou a preencher
- `submitted_at` (timestamptz) - Quando submeteu (INDEX)
- `time_to_complete_sec` (numeric) - Tempo de preenchimento
- `created_at`, `updated_at`, `ingested_at`

**Campos de Payload:**
- `raw_payload` (jsonb) - Payload completo original
- `raw_tracking` (jsonb) - Dados de tracking completos

**Índices:**
- `idx_yf_lead_email`, `idx_yf_lead_phone`
- `idx_yf_lead_market`, `idx_yf_lead_segment`
- `idx_yf_revenue_range`, `idx_yf_monthly_volume`
- `idx_yf_score`, `idx_yf_submitted_at`
- `idx_yf_utm_source`, `idx_yf_utm_campaign`
- `idx_yf_device`, `idx_yf_geo_state`

**Regras de Qualificação MQL (hardcoded no dataService.js):**

**Desqualificado (Lead)** se:
- `lead_revenue_range` IN ('Zero até o momento', 'Menos de R$100 mil', 'Entre R$100 mil e R$500 mil', 'Entre R$500 mil e R$1 milhão')
- OU `lead_segment` IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia')
- OU `lead_monthly_volume` IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês')

**Qualificado (MQL)** se:
- `lead_revenue_range` IN ('Entre R$1 milhão a R$5 milhões', 'Entre R$5 milhões a R$10 milhões', 'Entre R$10 milhões a R$25 milhões', 'Entre R$25 milhões a R$50 milhões', 'Acima de R$50 milhões', 'Acima de R$10 milhões')

**Agregação:**
- # Lead = COUNT(*)
- # MQL = COUNT(*) com regras de qualificação aplicadas

**RLS:**
- ✅ Habilitado
- Policy: "Allow authenticated select" + "service_role_all" (service role tem acesso total)

---

## 7. TABELA: `crm_deals` (Pipeline de Vendas)

**Propósito:** Negócios/Deals do CRM Pipedrive com todas as etapas do funil

**Campos:**

| Campo | Tipo | Descrição | Constraints |
|-------|------|-----------|-------------|
| `id` | bigint | ID único interno | PRIMARY KEY |
| `deal_id` | integer | ID do deal no Pipedrive | NOT NULL, UNIQUE, INDEX |
| `person_id` | integer | ID da pessoa | |
| `person_name` | text | Nome da pessoa | |
| `person_email` | text | Email da pessoa | |
| `person_phone` | text | Telefone da pessoa | |
| `org_id` | integer | ID da organização | |
| `org_name` | text | Nome da organização | |
| `pipeline_id` | integer | ID do pipeline | NOT NULL, INDEX |
| `pipeline_name` | text | Nome do pipeline | |
| `stage_id` | integer | ID da etapa atual | NOT NULL, INDEX |
| `stage_name` | text | Nome da etapa | |
| `stage_order` | integer | Ordem da etapa | |
| `funnel_type` | text | Tipo de funil | INDEX |
| `title` | text | Título do deal | |
| `value` | numeric | Valor do deal em R$ | DEFAULT 0 |
| `currency` | text | Moeda | DEFAULT 'BRL' |
| `status` | text | Status do deal | DEFAULT 'open', NOT NULL, INDEX |
| `probability` | integer | Probabilidade de fechamento (%) | |
| `label_ids` | jsonb | IDs de labels/tags | INDEX (GIN) |
| `owner_id` | integer | ID do dono | INDEX |
| `owner_name` | text | Nome do dono | |
| `creator_user_id` | integer | ID do criador | |
| `origin` | text | Origem do deal | |
| `expected_close_date` | date | Data esperada de fechamento | |
| `close_time` | timestamptz | Data/hora de fechamento | |
| `lost_time` | timestamptz | Data/hora de perda | |
| `won_time` | timestamptz | Data/hora de ganho | |
| `first_won_time` | timestamptz | Primeira vez que ganhou | |
| `stage_change_time` | timestamptz | Última mudança de etapa | INDEX |
| `is_archived` | boolean | Deal arquivado? | DEFAULT false, INDEX |
| `archive_time` | timestamptz | Data de arquivamento | |
| `lost_reason` | text | Motivo da perda | |
| `yayforms_response_id` | uuid | FK para yayforms | FK |
| `custom_fields` | jsonb | Campos customizados | INDEX (GIN) |
| `webhook_action` | text | Ação do webhook | |
| `webhook_change_source` | text | Fonte da mudança | |
| `previous_data` | jsonb | Dados anteriores | |
| `deal_created_at` | timestamptz | Data de criação no Pipedrive | INDEX |
| `deal_updated_at` | timestamptz | Data de atualização no Pipedrive | |
| `created_at` | timestamptz | Data de criação no Supabase | DEFAULT now() |
| `updated_at` | timestamptz | Data de atualização no Supabase | DEFAULT now() |

**Stage IDs (Etapas do Funil) - CONFORME DDL:**

⚠️ **ATENÇÃO:** Os Stage IDs no DDL são diferentes dos documentados no dataService.js!

**Conforme função `dashboard_data()`:**
- **MQL:** stage_id IN (1, 49, 2)
- **SQL:** stage_id IN (19, 50) OU (3, 4, 41, 45, 46, 47) OU status='won'
- **Reunião Agendada:** stage_id IN (3, 51, 45, 37, 27)
- **Reunião Realizada + Proposta:** stage_id IN (4, 46, 39, 29)
- **Pipeline (Negociação):** stage_id IN (3, 4, 41, 45, 46, 47, 39, 40)

**Motivos de Perda (por etapa):**
- **Perdas MQL:** `status` = 'lost' AND `stage_id` IN (1, 49, 2)
- **Perdas SQL:** `status` = 'lost' AND `stage_id` IN (19, 50, 6, 48)
- **Perdas Proposta:** `status` = 'lost' AND `stage_id` IN (3, 4, 41, 45, 46, 47, 39, 29, 51)

**Custom Fields (campos JSONB):**

⚠️ **NOTA:** Custom fields podem vir como string JSON ou objeto. Usar função `cf_val()` para extrair.

Exemplos de custom fields do dataService.js (NÃO VALIDADOS NO DDL):
- `2e17191cfb8e6f4a58359adc42a08965a068e8bc` = '75' → SQL?
- `8eff24b00226da8dfb871caaf638b62af68bf16b` → Data reunião agendada?
- `baf2724fcbeec84a36e90f9dc3299431fe1b0dd3` = '47' → Reunião realizada?

**Regras de Negócio:**
- **Pipeline Total** = SUM(`value`) WHERE `status` = 'open' AND `stage_id` IN (3,4,41,45,46,47,39,40)
- **Faturamento Projetado** = Pipeline Total * `probability` / 100 (média se null = 50%)
- **Receita Projetada** = Receita Gerada + (Faturamento Projetado * 0.7)

**Foreign Keys:**
- `crm_deals_yayforms_response_id_fkey` → `yayforms_responses(id)` ON DELETE SET NULL

**RLS:**
- ✅ Habilitado
- Policy: "Allow authenticated select"

---

## 8. TABELA: `crm_stage_transitions` (Transições de Etapas)

**Propósito:** Rastreamento de transições entre etapas do funil para cálculo de velocidade

**Campos:**

| Campo | Tipo | Descrição | Constraints |
|-------|------|-----------|-------------|
| `id` | bigint | ID único | PRIMARY KEY |
| `deal_id` | integer | ID do deal | NOT NULL, FK |
| `deal_title` | text | Título do deal | |
| `pipeline_id` | integer | ID do pipeline | NOT NULL |
| `pipeline_name` | text | Nome do pipeline | |
| `funnel_type` | text | Tipo de funil | INDEX (com transitioned_at) |
| `from_stage_id` | integer | Etapa de origem | |
| `from_stage_name` | text | Nome da etapa origem | |
| `from_stage_order` | integer | Ordem da etapa origem | |
| `to_stage_id` | integer | Etapa de destino | NOT NULL, INDEX (com pipeline_id) |
| `to_stage_name` | text | Nome da etapa destino | |
| `to_stage_order` | integer | Ordem da etapa destino | |
| `direction` | text | Direção (forward/backward) | INDEX (com transitioned_at) |
| `transitioned_at` | timestamptz | Data/hora da transição | NOT NULL, INDEX |
| `time_in_previous_stage_sec` | numeric | Tempo na etapa anterior (segundos) | |
| `owner_id` | integer | ID do dono | |
| `owner_name` | text | Nome do dono | |
| `deal_value` | numeric | Valor do deal | |
| `deal_status` | text | Status do deal | |
| `webhook_action` | text | Ação do webhook | |
| `created_at` | timestamptz | Data de criação | DEFAULT now() |

**Índices Compostos:**
- `idx_stage_trans_deal_time` - (deal_id, transitioned_at)
- `idx_stage_trans_direction` - (direction, transitioned_at)
- `idx_stage_trans_funnel_time` - (funnel_type, transitioned_at)
- `idx_stage_trans_pipeline_stage_time` - (pipeline_id, to_stage_id, transitioned_at)

**Foreign Keys:**
- `fk_stage_transitions_deal` → `crm_deals(deal_id)`

**Uso para Deltas de Velocidade:**
- **MQL → SQL:** Transições para `to_stage_id` IN (4, 50) ou (19, 50)
- **SQL → Reunião:** Transições para `to_stage_id` IN (6, 7, 45) ou (3, 51, 45, 37, 27)
- **Reunião → Venda:** Calculado usando `calendly_events` + `sales`
- **Lead → Venda:** deal_created_at vs data_fechamento

**Cálculo de Dias:**
`time_in_previous_stage_sec` / (60 * 60 * 24) = dias

**RLS:**
- ✅ Habilitado
- Policies: "Allow authenticated select" + "Allow insert for service_role"

---

## 9. TABELA: `crm_deal_activities` (Atividades dos Deals)

**Propósito:** Registro de atividades realizadas nos deals (calls, reuniões, emails)

**Campos:**

| Campo | Tipo | Descrição | Constraints |
|-------|------|-----------|-------------|
| `id` | bigint | ID único interno | PRIMARY KEY |
| `activity_id` | integer | ID da atividade no Pipedrive | NOT NULL, UNIQUE, INDEX |
| `deal_id` | integer | ID do deal | NOT NULL, INDEX |
| `deal_title` | text | Título do deal | |
| `activity_type` | text | Tipo de atividade | NOT NULL, INDEX |
| `activity_type_name` | text | Nome do tipo | |
| `subject` | text | Assunto da atividade | |
| `note_html` | text | Nota em HTML | |
| `note_clean` | text | Nota em texto limpo | |
| `public_description` | text | Descrição pública | |
| `due_date` | date | Data prevista | INDEX |
| `due_time` | time | Hora prevista | |
| `duration` | text | Duração | |
| `busy_flag` | boolean | Marca calendário ocupado | DEFAULT false |
| `done` | boolean | Atividade concluída | DEFAULT false, NOT NULL, INDEX |
| `marked_as_done_time` | timestamptz | Data/hora de conclusão | INDEX |
| `active_flag` | boolean | Atividade ativa | DEFAULT true |
| `user_id` | integer | ID do usuário | INDEX |
| `owner_name` | text | Nome do dono | |
| `assigned_to_user_id` | integer | ID do responsável | INDEX |
| `created_by_user_id` | integer | ID do criador | |
| `update_user_id` | integer | ID do último editor | |
| `person_id` | integer | ID da pessoa | |
| `person_name` | text | Nome da pessoa | |
| `org_id` | integer | ID da organização | |
| `org_name` | text | Nome da organização | |
| `activity_created_at` | timestamptz | Data de criação no Pipedrive | |
| `activity_updated_at` | timestamptz | Data de atualização no Pipedrive | |
| `created_at` | timestamptz | Data de criação no Supabase | DEFAULT now() |
| `updated_at` | timestamptz | Data de atualização no Supabase | DEFAULT now() |

**Tipos de Atividade Principais:**
- `call` - Chamadas telefônicas
- `meeting` - Reuniões
- `email` - Emails
- `task` - Tarefas

**Uso no Dashboard:**
- **Reuniões Realizadas** = COUNT(DISTINCT deal_id) WHERE `activity_type` = 'call' AND `done` = true

**Índices:**
- `idx_crm_act_activity_id`, `idx_crm_act_deal_id`
- `idx_crm_act_type`, `idx_crm_act_done`
- `idx_crm_act_user_id`, `idx_crm_act_assigned_to`
- `idx_crm_act_due_date`, `idx_crm_act_marked_done_time`

**RLS:**
- ✅ Habilitado

---

## 10. TABELA: `calendly_events` (Agendamentos Calendly)

**Propósito:** Eventos de agendamento via Calendly (reuniões agendadas)

**Campos:**

| Campo | Tipo | Descrição | Constraints |
|-------|------|-----------|-------------|
| `id` | bigint | ID único | PRIMARY KEY |
| `invitee_uuid` | text | UUID do convidado | NOT NULL, UNIQUE, INDEX |
| `event_uuid` | text | UUID do evento | NOT NULL, INDEX |
| `event_type_uuid` | text | UUID do tipo de evento | INDEX |
| `webhook_event` | text | Tipo de webhook | NOT NULL, INDEX |
| `event_name` | text | Nome do evento | |
| `event_status` | text | Status do evento | DEFAULT 'active', NOT NULL, INDEX |
| `host_name` | text | Nome do host | |
| `host_email` | text | Email do host | INDEX |
| `invitee_name` | text | Nome do convidado | |
| `invitee_email` | text | Email do convidado | INDEX |
| `invitee_phone` | text | Telefone do convidado | |
| `invitee_timezone` | text | Timezone do convidado | |
| `start_time` | timestamptz | Data/hora de início | INDEX |
| `end_time` | timestamptz | Data/hora de fim | |
| `rescheduled` | boolean | Reagendado? | DEFAULT false, NOT NULL |
| `canceled_by` | text | Cancelado por quem | |
| `canceler_type` | text | Tipo de cancelador | |
| `cancellation_reason` | text | Motivo do cancelamento | |
| `canceled_at` | timestamptz | Data/hora do cancelamento | |
| `utm_source` | text | UTM source | |
| `utm_medium` | text | UTM medium | |
| `utm_campaign` | text | UTM campaign | |
| `utm_content` | text | UTM content | |
| `utm_term` | text | UTM term | |
| `yayforms_response_id` | uuid | FK para yayforms | FK |
| `crm_deal_id` | integer | FK para crm_deals | FK, INDEX |
| `raw_payload` | jsonb | Payload completo | |
| `invitee_created_at` | timestamptz | Data de criação do convidado | |
| `invitee_updated_at` | timestamptz | Data de atualização do convidado | |
| `webhook_received_at` | timestamptz | Data de recebimento do webhook | |
| `created_at` | timestamptz | Data de criação | DEFAULT now() |
| `updated_at` | timestamptz | Data de atualização | DEFAULT now() |

**Foreign Keys:**
- `calendly_events_yayforms_response_id_fkey` → `yayforms_responses(id)` ON DELETE SET NULL
- `calendly_events_crm_deal_id_fkey` → `crm_deals(deal_id)` ON DELETE SET NULL

**Índices:**
- `idx_calendly_invitee_uuid`, `idx_calendly_event_uuid`
- `idx_calendly_invitee_email`, `idx_calendly_host_email`
- `idx_calendly_start_time`, `idx_calendly_event_status`
- `idx_calendly_crm_deal_id`

**RLS:**
- ✅ Habilitado

---

## 11-14. TABELAS AUXILIARES DE CRM

### `crm_pipelines` (Pipelines do CRM)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | integer | ID do pipeline | PRIMARY KEY |
| `name` | text | Nome do pipeline | NOT NULL |
| `active` | boolean | Pipeline ativo | DEFAULT true |
| `order_nr` | integer | Ordem de exibição | |
| `synced_at` | timestamptz | Data de sincronização | DEFAULT now() |

**RLS:** ✅ Habilitado

---

### `crm_stages` (Etapas/Stages)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | integer | ID da etapa | PRIMARY KEY |
| `pipeline_id` | integer | ID do pipeline | NOT NULL, FK, INDEX |
| `name` | text | Nome da etapa | NOT NULL |
| `order_flag` | integer | Ordem da etapa | |
| `active_flag` | boolean | Etapa ativa | DEFAULT true |
| `synced_at` | timestamptz | Data de sincronização | DEFAULT now() |

**Foreign Keys:**
- `pipedrive_stages_pipeline_id_fkey` → `crm_pipelines(id)` ON DELETE CASCADE

**RLS:** ✅ Habilitado

---

### `crm_users` (Usuários do CRM)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | integer | ID do usuário | PRIMARY KEY |
| `name` | text | Nome do usuário | NOT NULL |
| `email` | text | Email | |
| `active` | boolean | Usuário ativo | DEFAULT true |
| `role_id` | integer | ID da função/role | |
| `synced_at` | timestamptz | Data de sincronização | DEFAULT now() |

**RLS:** ✅ Habilitado

---

### `crm_deal_fields` (Campos Customizados)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `key` | text | Chave do campo | PRIMARY KEY |
| `name` | text | Nome do campo | NOT NULL, INDEX |
| `field_type` | text | Tipo do campo | NOT NULL |
| `options` | jsonb | Opções (dropdown) | |
| `edit_flag` | boolean | Editável | DEFAULT true |
| `synced_at` | timestamptz | Data de sincronização | DEFAULT now() |

**RLS:** ✅ Habilitado

---

## 15-16. TABELAS DE CONTROLE

### `app_config` (Configurações da Aplicação)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | bigint | ID único | PRIMARY KEY |
| `key` | text | Chave da configuração | NOT NULL, UNIQUE |
| `value` | text | Valor | |
| `description` | text | Descrição | |
| `is_secret` | boolean | É segredo? | DEFAULT false, NOT NULL |
| `updated_at` | timestamptz | Data de atualização | DEFAULT now() |

**RLS:** ✅ Habilitado

---

### `sync_control` (Controle de Sincronização)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | bigint | ID único | PRIMARY KEY |
| `flow_name` | text | Nome do fluxo | NOT NULL, INDEX |
| `source` | text | Fonte dos dados | NOT NULL, INDEX |
| `date_from` | date | Data início | |
| `date_to` | date | Data fim | |
| `cursor_after` | text | Cursor de paginação | |
| `page_number` | integer | Número da página | DEFAULT 1 |
| `total_records` | integer | Total de registros | DEFAULT 0 |
| `status` | text | Status da sincronização | DEFAULT 'running', NOT NULL, INDEX |
| `records_inserted` | integer | Registros inseridos | DEFAULT 0 |
| `records_updated` | integer | Registros atualizados | DEFAULT 0 |
| `records_skipped` | integer | Registros ignorados | DEFAULT 0 |
| `error_message` | text | Mensagem de erro | |
| `started_at` | timestamptz | Data de início | DEFAULT now(), INDEX (DESC) |
| `updated_at` | timestamptz | Data de atualização | DEFAULT now() |
| `completed_at` | timestamptz | Data de conclusão | |

**Índices:**
- `idx_sync_control_flow_name`
- `idx_sync_control_source`
- `idx_sync_control_started_at` (DESC)
- `idx_sync_control_status`

**RLS:** ✅ Habilitado

---

## FUNÇÃO PRINCIPAL: `dashboard_data(p_start date, p_end date)`

**Propósito:** Função SQL que agrega todas as métricas do dashboard para um período específico

**Parâmetros:**
- `p_start` (date) - Data de início do período
- `p_end` (date) - Data de fim do período

**Retorno:** JSONB com estrutura:

```json
{
  "impressoes": bigint,
  "cliques": bigint,
  "gasto_ads": numeric,
  "view_page": bigint,
  "leads": bigint,
  "mql": bigint,
  "sql": bigint,
  "reunioes_agendadas": bigint,
  "reunioes_realizadas": bigint,
  "vendas": bigint,
  "receita": numeric,
  "pipeline_total": numeric,
  "fat_projetado": numeric,
  "receita_projetada": numeric,
  "tmf_dias": numeric,
  "perdas": {
    "mql": [{"motivo": text, "cnt": int}],
    "sql": [{"motivo": text, "cnt": int}],
    "proposta": [{"motivo": text, "cnt": int}]
  }
}
```

**Lógica de Agregação:**
- **Impressões/Cliques/Gasto:** UNION de meta_ads_costs + google_ads_costs + linkedin_ads_costs
- **View Page:** COUNT de yayforms_responses.started_at no período
- **Leads:** COUNT de yayforms_responses.submitted_at no período
- **MQL:** COUNT de crm_deals WHERE pipeline_id IN (1,9)
- **SQL:** COUNT de crm_deals WHERE pipeline_id IN (1,8,9) AND (stage_id IN (19,50) OR stage_id IN (3,4,41,45,46,47) OR status='won')
- **Reuniões Agendadas:** COUNT de crm_deals WHERE pipeline_id IN (1,8,9,7,5) AND stage_id IN (3,51,45,37,27,4,46,39,29)
- **Reuniões Realizadas:** COUNT DISTINCT de crm_deal_activities WHERE activity_type='call' AND done=true
- **Vendas:** COUNT de sales
- **Receita:** SUM de sales.total_revenue (campo não documentado - possível bug?)
- **Pipeline:** SUM de crm_deals.value WHERE status='open' AND stage_id IN (3,4,41,45,46,47,39,40)
- **Faturamento Projetado:** SUM de (value * probability/100)
- **Receita Projetada:** fat_projetado * 0.7
- **TMF (Tempo Médio de Fechamento):** Média de dias entre deal_created_at e sale_date
- **Perdas:** Top 5 motivos por etapa (MQL, SQL, Proposta)

**Discrepâncias Identificadas:**

⚠️ **CRÍTICO:** A função `dashboard_data()` usa lógica DIFERENTE do `dataService.js`:
1. Stage IDs são diferentes
2. Pipeline IDs são diferentes
3. Campos de sales (total_revenue, sale_date) não existem no DDL atual
4. Lógica de View Page diferente (started_at vs conversions do Google Ads)

---

## RESUMO DAS DISCREPÂNCIAS

| Item | dataService.js | dashboard_data() SQL | DDL Real |
|------|----------------|----------------------|----------|
| Stage MQL | 1, 3, 49 | 1, 49, 2 | Não especificado |
| Stage SQL | 4, 50 | 19, 50 + outros | Não especificado |
| Pipeline SQL | Não usa | 1, 8, 9 | Não especificado |
| Campo sales.receita | receita_gerada | total_revenue | receita_gerada ✅ |
| Campo sales.data | data_fechamento | sale_date | data_fechamento ✅ |
| Custom fields | Hardcoded hash keys | Não usa | cf_val() function |

**Recomendação:** Validar qual lógica está correta (dataService.js vs SQL function) e padronizar.

---
