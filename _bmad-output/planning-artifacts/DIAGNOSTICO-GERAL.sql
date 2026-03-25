-- ====================================================
-- DIAGNÓSTICO GERAL - VALIDAÇÃO DAS MÉTRICAS
-- Data: 2026-03-25
-- ====================================================

-- ====================================================
-- 1. VALIDAR CUSTOM FIELDS DO PIPEDRIVE
-- ====================================================

-- 1.1 Verificar valores do campo SQL (2e17191cfb8e6f4a58359adc42a08965a068e8bc)
SELECT
  'SQL Custom Field' as campo,
  (CASE
    WHEN jsonb_typeof(custom_fields) = 'string'
    THEN (custom_fields #>> '{}')::jsonb
    ELSE custom_fields
  END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' as valor,
  COUNT(*) as quantidade,
  STRING_AGG(DISTINCT stage_id::text, ', ' ORDER BY stage_id::text) as stages
FROM crm_deals
WHERE custom_fields IS NOT NULL
  AND (CASE
    WHEN jsonb_typeof(custom_fields) = 'string'
    THEN (custom_fields #>> '{}')::jsonb
    ELSE custom_fields
  END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' IS NOT NULL
GROUP BY 1, 2
ORDER BY quantidade DESC;

-- 1.2 Verificar valores do campo Reunião Agendada (8eff24b00226da8dfb871caaf638b62af68bf16b)
SELECT
  'Reunião Agendada' as campo,
  (CASE
    WHEN jsonb_typeof(custom_fields) = 'string'
    THEN (custom_fields #>> '{}')::jsonb
    ELSE custom_fields
  END)->>'8eff24b00226da8dfb871caaf638b62af68bf16b' as valor,
  COUNT(*) as quantidade,
  CASE
    WHEN (CASE
      WHEN jsonb_typeof(custom_fields) = 'string'
      THEN (custom_fields #>> '{}')::jsonb
      ELSE custom_fields
    END)->>'8eff24b00226da8dfb871caaf638b62af68bf16b' ~ '^\d{4}-\d{2}-\d{2}'
    THEN 'Parece ser data'
    ELSE 'Não é data'
  END as tipo_valor
FROM crm_deals
WHERE custom_fields IS NOT NULL
  AND (CASE
    WHEN jsonb_typeof(custom_fields) = 'string'
    THEN (custom_fields #>> '{}')::jsonb
    ELSE custom_fields
  END)->>'8eff24b00226da8dfb871caaf638b62af68bf16b' IS NOT NULL
GROUP BY 1, 2, 4
ORDER BY quantidade DESC
LIMIT 20;

-- 1.3 Verificar valores do campo Reunião Realizada (baf2724fcbeec84a36e90f9dc3299431fe1b0dd3)
SELECT
  'Reunião Realizada' as campo,
  (CASE
    WHEN jsonb_typeof(custom_fields) = 'string'
    THEN (custom_fields #>> '{}')::jsonb
    ELSE custom_fields
  END)->>'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3' as valor,
  COUNT(*) as quantidade,
  STRING_AGG(DISTINCT stage_id::text, ', ' ORDER BY stage_id::text) as stages
FROM crm_deals
WHERE custom_fields IS NOT NULL
  AND (CASE
    WHEN jsonb_typeof(custom_fields) = 'string'
    THEN (custom_fields #>> '{}')::jsonb
    ELSE custom_fields
  END)->>'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3' IS NOT NULL
GROUP BY 1, 2
ORDER BY quantidade DESC;

-- ====================================================
-- 2. VALIDAR TABELA SALES
-- ====================================================

-- 2.1 Verificar se existe campo status com valor 'Churn'
SELECT
  'Status na tabela sales' as validacao,
  status,
  COUNT(*) as quantidade,
  MIN(data_fechamento) as primeira_ocorrencia,
  MAX(data_fechamento) as ultima_ocorrencia
FROM sales
GROUP BY status
ORDER BY quantidade DESC;

-- 2.2 Verificar campos de email para matching
SELECT
  'Emails para matching' as validacao,
  COUNT(*) as total_vendas,
  COUNT(email_pipedrive) as tem_email_pipedrive,
  COUNT(email_stripe) as tem_email_stripe,
  COUNT(CASE WHEN email_pipedrive IS NOT NULL AND email_stripe IS NOT NULL THEN 1 END) as tem_ambos,
  COUNT(CASE WHEN email_pipedrive IS NULL AND email_stripe IS NULL THEN 1 END) as nenhum_email
FROM sales;

-- ====================================================
-- 3. VALIDAR STAGE IDs
-- ====================================================

-- 3.1 Listar todos os stages com suas quantidades
SELECT
  pipeline_id,
  stage_id,
  COUNT(*) as quantidade_deals,
  COUNT(CASE WHEN status = 'open' THEN 1 END) as deals_abertos,
  COUNT(CASE WHEN status = 'won' THEN 1 END) as deals_ganhos,
  COUNT(CASE WHEN status = 'lost' THEN 1 END) as deals_perdidos
FROM crm_deals
GROUP BY pipeline_id, stage_id
ORDER BY pipeline_id, stage_id;

-- 3.2 Verificar stage 46 (usado para pipeline)
SELECT
  'Stage 46 - Pipeline' as validacao,
  pipeline_id,
  status,
  COUNT(*) as quantidade,
  SUM(value) as valor_total,
  AVG(value) as ticket_medio
FROM crm_deals
WHERE stage_id = 46
GROUP BY pipeline_id, status
ORDER BY pipeline_id, status;

-- ====================================================
-- 4. VALIDAR DADOS DE ADS
-- ====================================================

-- 4.1 Verificar períodos cobertos por cada fonte
SELECT
  'Meta Ads' as fonte,
  MIN(date_start) as data_inicio,
  MAX(date_start) as data_fim,
  COUNT(DISTINCT DATE_TRUNC('month', date_start)) as meses_com_dados,
  SUM(spend) as gasto_total
FROM meta_ads_costs
UNION ALL
SELECT
  'Google Ads' as fonte,
  MIN(date) as data_inicio,
  MAX(date) as data_fim,
  COUNT(DISTINCT DATE_TRUNC('month', date)) as meses_com_dados,
  SUM(spend) as gasto_total
FROM google_ads_costs
UNION ALL
SELECT
  'LinkedIn Ads' as fonte,
  MIN(date) as data_inicio,
  MAX(date) as data_fim,
  COUNT(DISTINCT DATE_TRUNC('month', date)) as meses_com_dados,
  SUM(spend) as gasto_total
FROM linkedin_ads_costs
ORDER BY fonte;

-- ====================================================
-- 5. VALIDAR MQLs vs SQLs
-- ====================================================

-- 5.1 Comparar volumes MQL vs SQL por mês
WITH mqls AS (
  SELECT
    DATE_TRUNC('month', submitted_at) as mes,
    COUNT(*) as mql
  FROM yayforms_responses
  WHERE
    lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    )
    AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
    AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
  GROUP BY DATE_TRUNC('month', submitted_at)
),
sqls AS (
  SELECT
    DATE_TRUNC('month', deal_created_at) as mes,
    COUNT(*) as sql
  FROM crm_deals
  WHERE (CASE
    WHEN jsonb_typeof(custom_fields) = 'string'
    THEN (custom_fields #>> '{}')::jsonb
    ELSE custom_fields
  END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
  GROUP BY DATE_TRUNC('month', deal_created_at)
)
SELECT
  COALESCE(m.mes, s.mes) as mes,
  COALESCE(m.mql, 0) as mqls,
  COALESCE(s.sql, 0) as sqls,
  CASE
    WHEN COALESCE(m.mql, 0) > 0
    THEN ROUND((COALESCE(s.sql, 0)::numeric / m.mql) * 100, 2)
    ELSE 0
  END as taxa_conversao_mql_sql
FROM mqls m
FULL OUTER JOIN sqls s ON m.mes = s.mes
WHERE COALESCE(m.mes, s.mes) >= '2024-01-01'
ORDER BY mes;

-- ====================================================
-- 6. VALIDAR MATCHING SALES x CRM_DEALS
-- ====================================================

-- 6.1 Taxa de matching com single vs double JOIN
WITH single_join AS (
  SELECT COUNT(DISTINCT s.id) as matches_single
  FROM sales s
  INNER JOIN crm_deals cd ON LOWER(TRIM(s.email_pipedrive)) = LOWER(TRIM(cd.person_email))
  WHERE (CASE WHEN jsonb_typeof(cd.custom_fields) = 'string'
         THEN (cd.custom_fields #>> '{}')::jsonb
         ELSE cd.custom_fields
         END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
),
double_join AS (
  SELECT COUNT(DISTINCT s.id) as matches_double
  FROM sales s
  INNER JOIN crm_deals cd ON (
    LOWER(TRIM(s.email_pipedrive)) = LOWER(TRIM(cd.person_email))
    OR LOWER(TRIM(s.email_stripe)) = LOWER(TRIM(cd.person_email))
  )
  WHERE (CASE WHEN jsonb_typeof(cd.custom_fields) = 'string'
         THEN (cd.custom_fields #>> '{}')::jsonb
         ELSE cd.custom_fields
         END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
),
total_sales AS (
  SELECT COUNT(*) as total FROM sales
)
SELECT
  t.total as total_vendas,
  s.matches_single as matches_email_pipedrive,
  d.matches_double as matches_ambos_emails,
  d.matches_double - s.matches_single as ganho_com_double_join,
  ROUND((s.matches_single::numeric / t.total) * 100, 2) as pct_match_single,
  ROUND((d.matches_double::numeric / t.total) * 100, 2) as pct_match_double
FROM single_join s, double_join d, total_sales t;

-- ====================================================
-- 7. ANÁLISE DE FUNIL COMPLETO
-- ====================================================

-- 7.1 Funil por mês (últimos 6 meses)
WITH funil AS (
  SELECT
    DATE_TRUNC('month', periodo) as mes,

    -- Volumes
    (SELECT COUNT(*) FROM yayforms_responses WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', periodo)) as leads,

    (SELECT COUNT(*) FROM yayforms_responses
     WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', periodo)
     AND lead_revenue_range IN (
       'Entre R$1 milhão a R$5 milhões',
       'Entre R$5 milhões a R$10 milhões',
       'Entre R$10 milhões a R$25 milhões',
       'Entre R$25 milhões a R$50 milhões',
       'Acima de R$50 milhões',
       'Acima de R$10 milhões'
     )
     AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
     AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
    ) as mqls,

    (SELECT COUNT(*) FROM crm_deals
     WHERE DATE_TRUNC('month', deal_created_at) = DATE_TRUNC('month', periodo)
     AND (CASE WHEN jsonb_typeof(custom_fields) = 'string'
          THEN (custom_fields #>> '{}')::jsonb
          ELSE custom_fields
          END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
    ) as sqls,

    (SELECT COUNT(*) FROM sales WHERE DATE_TRUNC('month', data_fechamento) = DATE_TRUNC('month', periodo)) as vendas,

    -- Valores
    (SELECT SUM(receita_gerada) FROM sales WHERE DATE_TRUNC('month', data_fechamento) = DATE_TRUNC('month', periodo)) as receita

  FROM (
    SELECT DISTINCT DATE_TRUNC('month', submitted_at) as periodo FROM yayforms_responses
    WHERE submitted_at >= CURRENT_DATE - INTERVAL '6 months'
  ) periodos
)
SELECT
  mes,
  leads,
  mqls,
  sqls,
  vendas,
  receita,
  -- Taxas de conversão
  CASE WHEN leads > 0 THEN ROUND((mqls::numeric / leads) * 100, 2) ELSE 0 END as tx_lead_mql,
  CASE WHEN mqls > 0 THEN ROUND((sqls::numeric / mqls) * 100, 2) ELSE 0 END as tx_mql_sql,
  CASE WHEN sqls > 0 THEN ROUND((vendas::numeric / sqls) * 100, 2) ELSE 0 END as tx_sql_venda,
  CASE WHEN vendas > 0 THEN ROUND(receita / vendas, 2) ELSE 0 END as ticket_medio
FROM funil
ORDER BY mes DESC;