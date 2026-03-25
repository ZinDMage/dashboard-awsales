# Queries SQL - Métricas do Dashboard AwSales

Queries para auditar as métricas que são apresentadas no dashboard.

## 1. MÉTRICAS DE VALOR (g)

### Receita por Mês de Fechamento (g.rec)

```sql
-- Receita agrupada pelo mês em que a venda foi fechada
SELECT
  DATE_TRUNC('month', data_fechamento) as mes,
  SUM(receita_gerada) as receita_total
FROM sales
GROUP BY DATE_TRUNC('month', data_fechamento)
ORDER BY mes;
```

### Receita por Mês de Criação do Deal (g.rec - cohort)

```sql
-- Receita agrupada pelo mês em que o deal foi criado no Pipedrive
-- Faz JOIN com email_pipedrive OU email_stripe para melhor matching
SELECT
  DATE_TRUNC('month', cd.deal_created_at) as mes,
  SUM(s.receita_gerada) as receita_total
FROM sales s
INNER JOIN crm_deals cd ON (
  LOWER(TRIM(s.email_pipedrive)) = LOWER(TRIM(cd.person_email))
  OR LOWER(TRIM(s.email_stripe)) = LOWER(TRIM(cd.person_email))
)
WHERE (CASE
  WHEN jsonb_typeof(cd.custom_fields) = 'string'
  THEN (cd.custom_fields #>> '{}')::jsonb
  ELSE cd.custom_fields
END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
GROUP BY DATE_TRUNC('month', cd.deal_created_at)
ORDER BY mes;
```

### Gasto em Ads (g.gAds)
```sql
SELECT
  DATE_TRUNC('month', data) as mes,
  SUM(spend) as gasto_ads
FROM (
  SELECT date_start as data, spend FROM meta_ads_costs
  UNION ALL
  SELECT date, spend FROM google_ads_costs
  UNION ALL
  SELECT date, spend FROM linkedin_ads_costs
) ads
GROUP BY DATE_TRUNC('month', data)
ORDER BY mes;
```

### ROI (g.roi = receita / gasto)
```sql
WITH roi_calc AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT SUM(receita_gerada) FROM sales WHERE DATE_TRUNC('month', data_fechamento) = DATE_TRUNC('month', periodo)) as receita,
    (SELECT SUM(spend) FROM (
      SELECT date_start as data, spend FROM meta_ads_costs WHERE DATE_TRUNC('month', date_start) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM google_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM linkedin_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
    ) ads) as gasto
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', data_fechamento) as periodo FROM sales
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date_start) FROM meta_ads_costs
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date) FROM google_ads_costs
  ) periodos
)
SELECT
  mes,
  receita,
  gasto,
  CASE WHEN gasto > 0 THEN ROUND(receita / gasto, 2) ELSE 0 END as roi
FROM roi_calc
ORDER BY mes;
```

### Margem de Contribuição (g.mc = receita - 17% - churn)
```sql
SELECT
  DATE_TRUNC('month', data_fechamento) as mes,
  SUM(receita_gerada) as receita,
  SUM(receita_gerada) * 0.17 as imposto,
  SUM(CASE WHEN status = 'Churn' THEN receita_gerada ELSE 0 END) as churn,
  SUM(receita_gerada) - (SUM(receita_gerada) * 0.17) - SUM(CASE WHEN status = 'Churn' THEN receita_gerada ELSE 0 END) as margem_contribuicao
FROM sales
GROUP BY DATE_TRUNC('month', data_fechamento)
ORDER BY mes;
```

### Pipeline Total (g.pipe - stage_id = 46)
```sql
SELECT
  DATE_TRUNC('month', deal_created_at) as mes,
  SUM(value) as pipeline_total
FROM crm_deals
WHERE stage_id = 46
  AND status = 'open'
GROUP BY DATE_TRUNC('month', deal_created_at)
ORDER BY mes;
```

### Faturamento Projetado (g.fatP = pipeline * 0.2)
```sql
SELECT
  DATE_TRUNC('month', deal_created_at) as mes,
  SUM(value) as pipeline,
  SUM(value) * 0.20 as faturamento_projetado
FROM crm_deals
WHERE stage_id = 46
  AND status = 'open'
GROUP BY DATE_TRUNC('month', deal_created_at)
ORDER BY mes;
```

### Receita Projetada (g.recP = receita + faturamento_projetado)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT SUM(receita_gerada) FROM sales WHERE DATE_TRUNC('month', data_fechamento) = DATE_TRUNC('month', periodo)) as receita,
    (SELECT SUM(value) * 0.20 FROM crm_deals WHERE DATE_TRUNC('month', deal_created_at) = DATE_TRUNC('month', periodo) AND stage_id = 46 AND status = 'open') as faturamento_projetado
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', data_fechamento) as periodo FROM sales
    UNION
    SELECT DISTINCT DATE_TRUNC('month', deal_created_at) FROM crm_deals WHERE stage_id = 46 AND status = 'open'
  ) periodos
)
SELECT
  mes,
  receita,
  faturamento_projetado,
  COALESCE(receita, 0) + COALESCE(faturamento_projetado, 0) as receita_projetada
FROM metricas
ORDER BY mes;
```

## 2. MÉTRICAS DE VOLUME (n)

### Impressões (n.imp)
```sql
SELECT
  DATE_TRUNC('month', data) as mes,
  SUM(impressions) as impressoes
FROM (
  SELECT date_start as data, impressions FROM meta_ads_costs
  UNION ALL
  SELECT date, impressions FROM google_ads_costs
  UNION ALL
  SELECT date, impressions FROM linkedin_ads_costs
) imp
GROUP BY DATE_TRUNC('month', data)
ORDER BY mes;
```

### Cliques (n.cli)
```sql
SELECT
  DATE_TRUNC('month', data) as mes,
  SUM(clicks) as cliques
FROM (
  SELECT date_start as data, value as clicks FROM meta_ads_actions WHERE action_type = 'unique_outbound_outbound_click'
  UNION ALL
  SELECT date, clicks FROM google_ads_costs
  UNION ALL
  SELECT date, clicks FROM linkedin_ads_costs
) cli
GROUP BY DATE_TRUNC('month', data)
ORDER BY mes;
```

### View Page (n.vp)
```sql
SELECT
  DATE_TRUNC('month', data) as mes,
  SUM(view_pages) as view_page
FROM (
  SELECT date_start as data, value as view_pages FROM meta_ads_actions WHERE action_type = 'landing_page_view'
  UNION ALL
  SELECT date, conversions as view_pages FROM google_ads_costs
) vp
GROUP BY DATE_TRUNC('month', data)
ORDER BY mes;
```

### Leads (n.ld)
```sql
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as leads
FROM yayforms_responses
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;
```

### MQL (n.mql)
```sql
-- REGRA ESPECIAL: E-commerce precisa > 10.000 tickets/mês
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as mql
FROM yayforms_responses
WHERE
  -- Faturamento adequado (obrigatório)
  lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )
  -- Não pode ser clínica ou advocacia
  AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
  -- Volume mínimo (E-commerce > 10k, outros > 5k)
  AND (
    -- E-commerce: precisa > 10.000 tickets/mês
    (lead_market = '🛒 Ecommerce'
     AND (lead_monthly_volume IS NULL
          OR lead_monthly_volume NOT IN (
            'Menos de 1.000 por mês',
            'Entre 1.000 e 3.000 por mês',
            'Entre 1.000 e 5.000 por mês',
            'Entre 3.000 e 5.000 por mês',
            'Entre 5.000 e 10.000 por mês'
          )))
    OR
    -- Outros mercados: regra padrão
    (COALESCE(lead_market, '') != '🛒 Ecommerce'
     AND (lead_monthly_volume IS NULL
          OR lead_monthly_volume NOT IN (
            'Menos de 1.000 por mês',
            'Entre 1.000 e 3.000 por mês',
            'Entre 1.000 e 5.000 por mês',
            'Entre 3.000 e 5.000 por mês'
          )))
  )
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;
```

### SQL (n.sql)
```sql
SELECT
  DATE_TRUNC('month', deal_created_at) as mes,
  COUNT(*) as sql
FROM crm_deals
WHERE (
  CASE
    WHEN jsonb_typeof(custom_fields) = 'string'
    THEN (custom_fields #>> '{}')::jsonb
    ELSE custom_fields
  END
)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
GROUP BY DATE_TRUNC('month', deal_created_at)
ORDER BY mes;
```

### Reuniões Agendadas (n.rAg)
```sql
SELECT
  DATE_TRUNC('month', deal_created_at) as mes,
  COUNT(*) as reunioes_agendadas
FROM crm_deals
WHERE (
  CASE
    WHEN jsonb_typeof(custom_fields) = 'string'
    THEN (custom_fields #>> '{}')::jsonb
    ELSE custom_fields
  END
)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
  AND (
    CASE
      WHEN jsonb_typeof(custom_fields) = 'string'
      THEN (custom_fields #>> '{}')::jsonb
      ELSE custom_fields
    END
  )->>'8eff24b00226da8dfb871caaf638b62af68bf16b' IS NOT NULL
  AND (
    CASE
      WHEN jsonb_typeof(custom_fields) = 'string'
      THEN (custom_fields #>> '{}')::jsonb
      ELSE custom_fields
    END
  )->>'8eff24b00226da8dfb871caaf638b62af68bf16b' != ''
GROUP BY DATE_TRUNC('month', deal_created_at)
ORDER BY mes;
```

### Reuniões Realizadas (n.rRe)
```sql
SELECT
  DATE_TRUNC('month', deal_created_at) as mes,
  COUNT(*) as reunioes_realizadas
FROM crm_deals
WHERE (
  CASE
    WHEN jsonb_typeof(custom_fields) = 'string'
    THEN (custom_fields #>> '{}')::jsonb
    ELSE custom_fields
  END
)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
  AND (
    CASE
      WHEN jsonb_typeof(custom_fields) = 'string'
      THEN (custom_fields #>> '{}')::jsonb
      ELSE custom_fields
    END
  )->>'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3' = '47'
GROUP BY DATE_TRUNC('month', deal_created_at)
ORDER BY mes;
```

### Vendas por Mês de Fechamento (n.v)
```sql
-- Vendas agrupadas pelo mês em que foram fechadas
SELECT
  DATE_TRUNC('month', data_fechamento) as mes,
  COUNT(*) as vendas
FROM sales
GROUP BY DATE_TRUNC('month', data_fechamento)
ORDER BY mes;
```

### Vendas por Mês de Criação do Deal (n.v - cohort)

```sql
-- Vendas agrupadas pelo mês em que o deal foi criado no Pipedrive
-- Faz JOIN com email_pipedrive OU email_stripe para melhor matching
SELECT
  DATE_TRUNC('month', cd.deal_created_at) as mes,
  COUNT(*) as vendas
FROM sales s
INNER JOIN crm_deals cd ON (
  LOWER(TRIM(s.email_pipedrive)) = LOWER(TRIM(cd.person_email))
  OR LOWER(TRIM(s.email_stripe)) = LOWER(TRIM(cd.person_email))
)
WHERE (CASE
  WHEN jsonb_typeof(cd.custom_fields) = 'string'
  THEN (cd.custom_fields #>> '{}')::jsonb
  ELSE cd.custom_fields
END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
GROUP BY DATE_TRUNC('month', cd.deal_created_at)
ORDER BY mes;
```

## 3. TAXAS DE CONVERSÃO (p)

### CTR (p.ctr = cliques / impressões)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', data) as mes,
    SUM(impressions) as impressoes,
    SUM(clicks) as cliques
  FROM (
    SELECT date_start as data, impressions, 0 as clicks FROM meta_ads_costs
    UNION ALL
    SELECT date_start as data, 0 as impressions, value as clicks FROM meta_ads_actions WHERE action_type = 'unique_outbound_outbound_click'
    UNION ALL
    SELECT date, impressions, clicks FROM google_ads_costs
    UNION ALL
    SELECT date, impressions, clicks FROM linkedin_ads_costs
  ) dados
  GROUP BY DATE_TRUNC('month', data)
)
SELECT
  mes,
  impressoes,
  cliques,
  CASE WHEN impressoes > 0 THEN ROUND((cliques::numeric / impressoes) * 100, 2) ELSE 0 END as ctr
FROM metricas
ORDER BY mes;
```

### Connect Rate (p.cr = view_page / cliques)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT SUM(value) FROM meta_ads_actions WHERE action_type = 'unique_outbound_outbound_click' AND DATE_TRUNC('month', date_start) = DATE_TRUNC('month', periodo)) +
    (SELECT COALESCE(SUM(clicks), 0) FROM google_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)) +
    (SELECT COALESCE(SUM(clicks), 0) FROM linkedin_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)) as cliques,
    (SELECT SUM(value) FROM meta_ads_actions WHERE action_type = 'landing_page_view' AND DATE_TRUNC('month', date_start) = DATE_TRUNC('month', periodo)) +
    (SELECT COALESCE(SUM(conversions), 0) FROM google_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)) as view_page
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', date_start) as periodo FROM meta_ads_actions
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date) FROM google_ads_costs
  ) periodos
)
SELECT
  mes,
  cliques,
  view_page,
  CASE WHEN cliques > 0 THEN ROUND((view_page::numeric / cliques) * 100, 2) ELSE 0 END as connect_rate
FROM metricas
ORDER BY mes;
```

### Conversão Captura (p.cc = leads / view_page)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT SUM(value) FROM meta_ads_actions WHERE action_type = 'landing_page_view' AND DATE_TRUNC('month', date_start) = DATE_TRUNC('month', periodo)) +
    (SELECT COALESCE(SUM(conversions), 0) FROM google_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)) as view_page,
    (SELECT COUNT(*) FROM yayforms_responses WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', periodo)) as leads
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', submitted_at) as periodo FROM yayforms_responses
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date_start) FROM meta_ads_actions WHERE action_type = 'landing_page_view'
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date) FROM google_ads_costs
  ) periodos
)
SELECT
  mes,
  view_page,
  leads,
  CASE WHEN view_page > 0 THEN ROUND((leads::numeric / view_page) * 100, 2) ELSE 0 END as conversao_captura
FROM metricas
ORDER BY mes;
```

### Qualified Marketing (p.qm = mql / leads)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', submitted_at) as mes,
    COUNT(*) as leads,
    COUNT(CASE
      WHEN lead_revenue_range IN ('Entre R$1 milhão a R$5 milhões', 'Entre R$5 milhões a R$10 milhões', 'Entre R$10 milhões a R$25 milhões', 'Entre R$25 milhões a R$50 milhões', 'Acima de R$50 milhões', 'Acima de R$10 milhões')
      AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
      AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
      THEN 1
    END) as mql
  FROM yayforms_responses
  GROUP BY DATE_TRUNC('month', submitted_at)
)
SELECT
  mes,
  leads,
  mql,
  CASE WHEN leads > 0 THEN ROUND((mql::numeric / leads) * 100, 2) ELSE 0 END as qualified_marketing
FROM metricas
ORDER BY mes;
```

### Qualified Sales (p.qs = sql / mql)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT COUNT(*) FROM yayforms_responses
     WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', periodo)
     AND lead_revenue_range IN ('Entre R$1 milhão a R$5 milhões', 'Entre R$5 milhões a R$10 milhões', 'Entre R$10 milhões a R$25 milhões', 'Entre R$25 milhões a R$50 milhões', 'Acima de R$50 milhões', 'Acima de R$10 milhões')
     AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
     AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
    ) as mql,
    (SELECT COUNT(*) FROM crm_deals WHERE DATE_TRUNC('month', deal_created_at) = DATE_TRUNC('month', periodo) AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75') as sql
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', submitted_at) as periodo FROM yayforms_responses
    UNION
    SELECT DISTINCT DATE_TRUNC('month', deal_created_at) FROM crm_deals
  ) periodos
)
SELECT
  mes,
  mql,
  sql,
  CASE WHEN mql > 0 THEN ROUND((sql::numeric / mql) * 100, 2) ELSE 0 END as qualified_sales
FROM metricas
ORDER BY mes;
```

### Agendamento (p.ag = reuniões_agendadas / sql)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', deal_created_at) as mes,
    COUNT(*) as sql,
    COUNT(CASE
      WHEN (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'8eff24b00226da8dfb871caaf638b62af68bf16b' IS NOT NULL
      AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'8eff24b00226da8dfb871caaf638b62af68bf16b' != ''
      THEN 1
    END) as reunioes_agendadas
  FROM crm_deals
  WHERE (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
  GROUP BY DATE_TRUNC('month', deal_created_at)
)
SELECT
  mes,
  sql,
  reunioes_agendadas,
  CASE WHEN sql > 0 THEN ROUND((reunioes_agendadas::numeric / sql) * 100, 2) ELSE 0 END as agendamento
FROM metricas
ORDER BY mes;
```

### Show Up (p.su = reuniões_realizadas / reuniões_agendadas)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', deal_created_at) as mes,
    COUNT(CASE
      WHEN (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'8eff24b00226da8dfb871caaf638b62af68bf16b' IS NOT NULL
      AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'8eff24b00226da8dfb871caaf638b62af68bf16b' != ''
      THEN 1
    END) as reunioes_agendadas,
    COUNT(CASE
      WHEN (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3' = '47'
      THEN 1
    END) as reunioes_realizadas
  FROM crm_deals
  WHERE (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
  GROUP BY DATE_TRUNC('month', deal_created_at)
)
SELECT
  mes,
  reunioes_agendadas,
  reunioes_realizadas,
  CASE WHEN reunioes_agendadas > 0 THEN ROUND((reunioes_realizadas::numeric / reunioes_agendadas) * 100, 2) ELSE 0 END as show_up
FROM metricas
ORDER BY mes;
```

### Fechamento Call (p.fc = vendas / reuniões_realizadas)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT COUNT(*) FROM crm_deals
     WHERE DATE_TRUNC('month', deal_created_at) = DATE_TRUNC('month', periodo)
     AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
     AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3' = '47') as reunioes_realizadas,
    (SELECT COUNT(*) FROM sales WHERE DATE_TRUNC('month', data_fechamento) = DATE_TRUNC('month', periodo)) as vendas
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', data_fechamento) as periodo FROM sales
    UNION
    SELECT DISTINCT DATE_TRUNC('month', deal_created_at) FROM crm_deals
  ) periodos
)
SELECT
  mes,
  reunioes_realizadas,
  vendas,
  CASE WHEN reunioes_realizadas > 0 THEN ROUND((vendas::numeric / reunioes_realizadas) * 100, 2) ELSE 0 END as fechamento_call
FROM metricas
ORDER BY mes;
```

### Fechamento SQL (p.fs = vendas / sql)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT COUNT(*) FROM crm_deals WHERE DATE_TRUNC('month', deal_created_at) = DATE_TRUNC('month', periodo) AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75') as sql,
    (SELECT COUNT(*) FROM sales WHERE DATE_TRUNC('month', data_fechamento) = DATE_TRUNC('month', periodo)) as vendas
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', data_fechamento) as periodo FROM sales
    UNION
    SELECT DISTINCT DATE_TRUNC('month', deal_created_at) FROM crm_deals
  ) periodos
)
SELECT
  mes,
  sql,
  vendas,
  CASE WHEN sql > 0 THEN ROUND((vendas::numeric / sql) * 100, 2) ELSE 0 END as fechamento_sql
FROM metricas
ORDER BY mes;
```

## 4. MÉTRICAS DE CUSTO (f)

### Custo por Lead (f.cpL = gasto / leads)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT SUM(spend) FROM (
      SELECT date_start as data, spend FROM meta_ads_costs WHERE DATE_TRUNC('month', date_start) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM google_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM linkedin_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
    ) ads) as gasto,
    (SELECT COUNT(*) FROM yayforms_responses WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', periodo)) as leads
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', submitted_at) as periodo FROM yayforms_responses
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date_start) FROM meta_ads_costs
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date) FROM google_ads_costs
  ) periodos
)
SELECT
  mes,
  gasto,
  leads,
  CASE WHEN leads > 0 THEN ROUND(gasto / leads, 2) ELSE 0 END as custo_por_lead
FROM metricas
ORDER BY mes;
```

### Custo por MQL (f.cpM = gasto / mql)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT SUM(spend) FROM (
      SELECT date_start as data, spend FROM meta_ads_costs WHERE DATE_TRUNC('month', date_start) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM google_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM linkedin_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
    ) ads) as gasto,
    (SELECT COUNT(*) FROM yayforms_responses
     WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', periodo)
     AND lead_revenue_range IN ('Entre R$1 milhão a R$5 milhões', 'Entre R$5 milhões a R$10 milhões', 'Entre R$10 milhões a R$25 milhões', 'Entre R$25 milhões a R$50 milhões', 'Acima de R$50 milhões', 'Acima de R$10 milhões')
     AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
     AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))) as mql
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', submitted_at) as periodo FROM yayforms_responses
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date_start) FROM meta_ads_costs
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date) FROM google_ads_costs
  ) periodos
)
SELECT
  mes,
  gasto,
  mql,
  CASE WHEN mql > 0 THEN ROUND(gasto / mql, 2) ELSE 0 END as custo_por_mql
FROM metricas
ORDER BY mes;
```

### Custo por SQL (f.cpS = gasto / sql)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT SUM(spend) FROM (
      SELECT date_start as data, spend FROM meta_ads_costs WHERE DATE_TRUNC('month', date_start) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM google_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM linkedin_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
    ) ads) as gasto,
    (SELECT COUNT(*) FROM crm_deals WHERE DATE_TRUNC('month', deal_created_at) = DATE_TRUNC('month', periodo) AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75') as sql
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', deal_created_at) as periodo FROM crm_deals
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date_start) FROM meta_ads_costs
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date) FROM google_ads_costs
  ) periodos
)
SELECT
  mes,
  gasto,
  sql,
  CASE WHEN sql > 0 THEN ROUND(gasto / sql, 2) ELSE 0 END as custo_por_sql
FROM metricas
ORDER BY mes;
```

### Custo por Reunião Agendada (f.cpRA = gasto / reuniões_agendadas)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT SUM(spend) FROM (
      SELECT date_start as data, spend FROM meta_ads_costs WHERE DATE_TRUNC('month', date_start) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM google_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM linkedin_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
    ) ads) as gasto,
    (SELECT COUNT(*) FROM crm_deals
     WHERE DATE_TRUNC('month', deal_created_at) = DATE_TRUNC('month', periodo)
     AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
     AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'8eff24b00226da8dfb871caaf638b62af68bf16b' IS NOT NULL
     AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'8eff24b00226da8dfb871caaf638b62af68bf16b' != '') as reunioes_agendadas
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', deal_created_at) as periodo FROM crm_deals
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date_start) FROM meta_ads_costs
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date) FROM google_ads_costs
  ) periodos
)
SELECT
  mes,
  gasto,
  reunioes_agendadas,
  CASE WHEN reunioes_agendadas > 0 THEN ROUND(gasto / reunioes_agendadas, 2) ELSE 0 END as custo_por_reuniao_agendada
FROM metricas
ORDER BY mes;
```

### Custo por Reunião Realizada (f.cpRR = gasto / reuniões_realizadas)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT SUM(spend) FROM (
      SELECT date_start as data, spend FROM meta_ads_costs WHERE DATE_TRUNC('month', date_start) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM google_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM linkedin_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
    ) ads) as gasto,
    (SELECT COUNT(*) FROM crm_deals
     WHERE DATE_TRUNC('month', deal_created_at) = DATE_TRUNC('month', periodo)
     AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
     AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3' = '47') as reunioes_realizadas
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', deal_created_at) as periodo FROM crm_deals
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date_start) FROM meta_ads_costs
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date) FROM google_ads_costs
  ) periodos
)
SELECT
  mes,
  gasto,
  reunioes_realizadas,
  CASE WHEN reunioes_realizadas > 0 THEN ROUND(gasto / reunioes_realizadas, 2) ELSE 0 END as custo_por_reuniao_realizada
FROM metricas
ORDER BY mes;
```

### CAC - Custo por Venda (f.cpV = gasto / vendas)
```sql
WITH metricas AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,
    (SELECT SUM(spend) FROM (
      SELECT date_start as data, spend FROM meta_ads_costs WHERE DATE_TRUNC('month', date_start) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM google_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM linkedin_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
    ) ads) as gasto,
    (SELECT COUNT(*) FROM sales WHERE DATE_TRUNC('month', data_fechamento) = DATE_TRUNC('month', periodo)) as vendas
  FROM (
    SELECT DISTINCT DATE_TRUNC('month', data_fechamento) as periodo FROM sales
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date_start) FROM meta_ads_costs
    UNION
    SELECT DISTINCT DATE_TRUNC('month', date) FROM google_ads_costs
  ) periodos
)
SELECT
  mes,
  gasto,
  vendas,
  CASE WHEN vendas > 0 THEN ROUND(gasto / vendas, 2) ELSE 0 END as cac
FROM metricas
ORDER BY mes;
```

## 5. DELTAS DE VELOCIDADE (dt)

### Delta MQL → SQL (dt.ms)
```sql
SELECT
  DATE_TRUNC('month', cd.deal_created_at) as mes,
  AVG(cst.time_in_previous_stage_sec / 86400.0) as dias_mql_sql
FROM crm_deals cd
INNER JOIN crm_stage_transitions cst ON cd.deal_id = cst.deal_id
WHERE cst.to_stage_id IN (19, 50)
  AND cst.time_in_previous_stage_sec > 0
  AND (CASE WHEN jsonb_typeof(cd.custom_fields) = 'string' THEN (cd.custom_fields #>> '{}')::jsonb ELSE cd.custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
GROUP BY DATE_TRUNC('month', cd.deal_created_at)
ORDER BY mes;
```

### Delta SQL → Reunião (dt.sr)
```sql
SELECT
  DATE_TRUNC('month', cd.deal_created_at) as mes,
  AVG(cst.time_in_previous_stage_sec / 86400.0) as dias_sql_reuniao
FROM crm_deals cd
INNER JOIN crm_stage_transitions cst ON cd.deal_id = cst.deal_id
WHERE cst.to_stage_id IN (3, 45, 51, 27, 37)
  AND cst.time_in_previous_stage_sec > 0
  AND (CASE WHEN jsonb_typeof(cd.custom_fields) = 'string' THEN (cd.custom_fields #>> '{}')::jsonb ELSE cd.custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
GROUP BY DATE_TRUNC('month', cd.deal_created_at)
ORDER BY mes;
```

### Delta Reunião → Venda (dt.rv)
```sql
SELECT
  DATE_TRUNC('month', s.data_fechamento) as mes,
  AVG(EXTRACT(EPOCH FROM (s.data_fechamento - ((CASE WHEN jsonb_typeof(cd.custom_fields) = 'string' THEN (cd.custom_fields #>> '{}')::jsonb ELSE cd.custom_fields END)->>'8eff24b00226da8dfb871caaf638b62af68bf16b')::date)) / 86400.0) as dias_reuniao_venda
FROM sales s
INNER JOIN crm_deals cd ON (
  LOWER(TRIM(s.email_pipedrive)) = LOWER(TRIM(cd.person_email))
  OR LOWER(TRIM(s.email_stripe)) = LOWER(TRIM(cd.person_email))
)
WHERE (CASE WHEN jsonb_typeof(cd.custom_fields) = 'string' THEN (cd.custom_fields #>> '{}')::jsonb ELSE cd.custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
  AND (CASE WHEN jsonb_typeof(cd.custom_fields) = 'string' THEN (cd.custom_fields #>> '{}')::jsonb ELSE cd.custom_fields END)->>'8eff24b00226da8dfb871caaf638b62af68bf16b' IS NOT NULL
GROUP BY DATE_TRUNC('month', s.data_fechamento)
ORDER BY mes;
```

### Delta Lead → Venda (dt.lv)
```sql
SELECT
  DATE_TRUNC('month', s.data_fechamento) as mes,
  AVG(EXTRACT(EPOCH FROM (s.data_fechamento - cd.deal_created_at)) / 86400.0) as dias_lead_venda
FROM sales s
INNER JOIN crm_deals cd ON (
  LOWER(TRIM(s.email_pipedrive)) = LOWER(TRIM(cd.person_email))
  OR LOWER(TRIM(s.email_stripe)) = LOWER(TRIM(cd.person_email))
)
WHERE (CASE WHEN jsonb_typeof(cd.custom_fields) = 'string' THEN (cd.custom_fields #>> '{}')::jsonb ELSE cd.custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
GROUP BY DATE_TRUNC('month', s.data_fechamento)
ORDER BY mes;
```

## 6. MOTIVOS DE PERDA

### Perdas por Etapa
```sql
SELECT
  DATE_TRUNC('month', deal_created_at) as mes,
  CASE
    WHEN stage_id IN (1, 49) THEN 'MQL'
    WHEN stage_id IN (19, 50) THEN 'SQL'
    WHEN stage_id IN (4, 46, 29, 39, 41, 47, 43, 40) THEN 'Proposta/Contrato'
    ELSE 'Outras'
  END as etapa,
  lost_reason as motivo,
  COUNT(*) as quantidade
FROM crm_deals
WHERE status = 'lost'
  AND lost_reason IS NOT NULL
GROUP BY DATE_TRUNC('month', deal_created_at),
         CASE
           WHEN stage_id IN (1, 49) THEN 'MQL'
           WHEN stage_id IN (19, 50) THEN 'SQL'
           WHEN stage_id IN (4, 46, 29, 39, 41, 47, 43, 40) THEN 'Proposta/Contrato'
           ELSE 'Outras'
         END,
         lost_reason
ORDER BY mes, etapa, quantidade DESC;
```

## DASHBOARD CONSOLIDADO

### Todas as Métricas em Uma Query
```sql
WITH dashboard AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,

    -- VALORES
    (SELECT SUM(receita_gerada) FROM sales WHERE DATE_TRUNC('month', data_fechamento) = DATE_TRUNC('month', periodo)) as receita,
    (SELECT SUM(spend) FROM (
      SELECT date_start as data, spend FROM meta_ads_costs WHERE DATE_TRUNC('month', date_start) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM google_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
      UNION ALL
      SELECT date, spend FROM linkedin_ads_costs WHERE DATE_TRUNC('month', date) = DATE_TRUNC('month', periodo)
    ) ads) as gasto_ads,
    (SELECT SUM(value) FROM crm_deals WHERE DATE_TRUNC('month', deal_created_at) = DATE_TRUNC('month', periodo) AND stage_id = 46 AND status = 'open') as pipeline,

    -- VOLUMES
    (SELECT COUNT(*) FROM yayforms_responses WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', periodo)) as leads,
    (SELECT COUNT(*) FROM yayforms_responses
     WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', periodo)
     AND lead_revenue_range IN ('Entre R$1 milhão a R$5 milhões', 'Entre R$5 milhões a R$10 milhões', 'Entre R$10 milhões a R$25 milhões', 'Entre R$25 milhões a R$50 milhões', 'Acima de R$50 milhões', 'Acima de R$10 milhões')
     AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
     AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))) as mql,
    (SELECT COUNT(*) FROM crm_deals WHERE DATE_TRUNC('month', deal_created_at) = DATE_TRUNC('month', periodo) AND (CASE WHEN jsonb_typeof(custom_fields) = 'string' THEN (custom_fields #>> '{}')::jsonb ELSE custom_fields END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75') as sql,
    (SELECT COUNT(*) FROM sales WHERE DATE_TRUNC('month', data_fechamento) = DATE_TRUNC('month', periodo)) as vendas

  FROM (
    SELECT DISTINCT DATE_TRUNC('month', data) as periodo
    FROM (
      SELECT data_fechamento as data FROM sales
      UNION SELECT submitted_at FROM yayforms_responses
      UNION SELECT deal_created_at FROM crm_deals
      UNION SELECT date_start FROM meta_ads_costs
      UNION SELECT date FROM google_ads_costs
    ) all_dates
    WHERE data IS NOT NULL
  ) periodos
)
SELECT
  mes,
  COALESCE(receita, 0) as receita,
  COALESCE(gasto_ads, 0) as gasto_ads,
  CASE WHEN gasto_ads > 0 THEN ROUND(receita / gasto_ads, 2) ELSE 0 END as roi,
  COALESCE(pipeline, 0) as pipeline,
  COALESCE(pipeline * 0.20, 0) as faturamento_projetado,
  COALESCE(receita + (pipeline * 0.20), 0) as receita_projetada,
  COALESCE(leads, 0) as leads,
  COALESCE(mql, 0) as mql,
  COALESCE(sql, 0) as sql,
  COALESCE(vendas, 0) as vendas,
  CASE WHEN leads > 0 THEN ROUND((mql::numeric / leads) * 100, 2) ELSE 0 END as taxa_mql,
  CASE WHEN mql > 0 THEN ROUND((sql::numeric / mql) * 100, 2) ELSE 0 END as taxa_sql,
  CASE WHEN sql > 0 THEN ROUND((vendas::numeric / sql) * 100, 2) ELSE 0 END as taxa_fechamento,
  CASE WHEN leads > 0 THEN ROUND(gasto_ads / leads, 2) ELSE 0 END as cpl,
  CASE WHEN vendas > 0 THEN ROUND(gasto_ads / vendas, 2) ELSE 0 END as cac
FROM dashboard
ORDER BY mes DESC;
```