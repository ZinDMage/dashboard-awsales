-- =====================================================
-- DIAGNÓSTICO: Discrepância MQLs - Planilha vs SQL
-- Data: 2026-03-25
--
-- Planilha Excel:
-- Janeiro: 114 MQLs
-- Fevereiro: 124 MQLs
-- Março: 117 MQLs
--
-- SQL Query:
-- Janeiro: 130 MQLs
-- Fevereiro: 130 MQLs
-- Março: 78 MQLs
-- =====================================================

-- =====================================================
-- 1. CONTAGEM BÁSICA POR MÊS (Query Atual)
-- =====================================================
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM Month') as mes_nome,
  COUNT(*) as mql_total
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
  AND DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2024-02-01', '2024-03-01')
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- =====================================================
-- 2. BREAKDOWN DETALHADO POR MÊS
-- =====================================================
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,
  COUNT(*) as total_respostas,

  -- Faturamento
  COUNT(CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    ) THEN 1
  END) as passou_faturamento,

  -- Segmento
  COUNT(CASE
    WHEN lead_segment IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia')
    THEN 1
  END) as excluido_por_segmento,

  -- Volume
  COUNT(CASE
    WHEN lead_monthly_volume IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês')
    THEN 1
  END) as excluido_por_volume,

  -- MQLs finais (todas as regras)
  COUNT(CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    )
    AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
    AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
    THEN 1
  END) as mql_final

FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2024-02-01', '2024-03-01')
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- =====================================================
-- 3. ANÁLISE DE VALORES NULL/VAZIOS
-- =====================================================
-- Possível diferença: Excel pode tratar NULL diferente do SQL
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,

  -- Análise de NULLs e vazios
  COUNT(CASE WHEN lead_revenue_range IS NULL THEN 1 END) as faturamento_null,
  COUNT(CASE WHEN lead_revenue_range = '' THEN 1 END) as faturamento_vazio,

  COUNT(CASE WHEN lead_segment IS NULL THEN 1 END) as segmento_null,
  COUNT(CASE WHEN lead_segment = '' THEN 1 END) as segmento_vazio,

  COUNT(CASE WHEN lead_monthly_volume IS NULL THEN 1 END) as volume_null,
  COUNT(CASE WHEN lead_monthly_volume = '' THEN 1 END) as volume_vazio,

  COUNT(*) as total

FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2024-02-01', '2024-03-01')
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- =====================================================
-- 4. LISTAR TODOS OS VALORES ÚNICOS POR CAMPO
-- =====================================================
-- Para verificar se há valores diferentes do esperado

-- 4.1 Valores de Faturamento
SELECT
  'Faturamento' as campo,
  lead_revenue_range as valor,
  COUNT(*) as quantidade,
  CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    ) THEN 'QUALIFICADO'
    WHEN lead_revenue_range IS NULL THEN 'NULL'
    WHEN lead_revenue_range = '' THEN 'VAZIO'
    ELSE 'DESQUALIFICADO'
  END as status_mql
FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2024-02-01', '2024-03-01')
GROUP BY lead_revenue_range
ORDER BY quantidade DESC;

-- 4.2 Valores de Segmento
SELECT
  'Segmento' as campo,
  COALESCE(lead_segment, '[NULL]') as valor,
  COUNT(*) as quantidade,
  CASE
    WHEN lead_segment IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia') THEN 'EXCLUIR'
    WHEN lead_segment IS NULL THEN 'NULL (OK)'
    WHEN lead_segment = '' THEN 'VAZIO (OK)'
    ELSE 'OK'
  END as status_mql
FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2024-02-01', '2024-03-01')
GROUP BY lead_segment
ORDER BY quantidade DESC;

-- 4.3 Valores de Volume
SELECT
  'Volume' as campo,
  COALESCE(lead_monthly_volume, '[NULL]') as valor,
  COUNT(*) as quantidade,
  CASE
    WHEN lead_monthly_volume IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês') THEN 'EXCLUIR'
    WHEN lead_monthly_volume IS NULL THEN 'NULL (OK)'
    WHEN lead_monthly_volume = '' THEN 'VAZIO (OK)'
    ELSE 'OK'
  END as status_mql
FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2024-02-01', '2024-03-01')
GROUP BY lead_monthly_volume
ORDER BY quantidade DESC;

-- =====================================================
-- 5. SIMULAÇÃO DE DIFERENTES LÓGICAS
-- =====================================================
-- Testar diferentes interpretações da regra de negócio

SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,

  -- Lógica 1: SQL atual (NULL é tratado como OK)
  COUNT(CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    )
    AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
    AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
    THEN 1
  END) as logica_sql_atual,

  -- Lógica 2: NULL em segmento/volume é EXCLUÍDO
  COUNT(CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    )
    AND lead_segment IS NOT NULL
    AND lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia')
    AND lead_monthly_volume IS NOT NULL
    AND lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês')
    THEN 1
  END) as logica_null_excluido,

  -- Lógica 3: Apenas faturamento é obrigatório
  COUNT(CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    )
    THEN 1
  END) as logica_so_faturamento,

  -- Lógica 4: Tratando vazio como NULL
  COUNT(CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    )
    AND (lead_segment IS NULL OR lead_segment = '' OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
    AND (lead_monthly_volume IS NULL OR lead_monthly_volume = '' OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
    THEN 1
  END) as logica_vazio_como_null

FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2024-02-01', '2024-03-01')
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- =====================================================
-- 6. EXPORTAR DADOS PARA ANÁLISE NO EXCEL
-- =====================================================
-- Query para exportar todos os dados e você pode aplicar as fórmulas do Excel

SELECT
  submitted_at,
  TO_CHAR(submitted_at, 'YYYY-MM-DD HH24:MI:SS') as data_hora,
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,
  lead_revenue_range,
  lead_segment,
  lead_monthly_volume,

  -- Classificação por critério
  CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    ) THEN 'SIM' ELSE 'NÃO'
  END as faturamento_ok,

  CASE
    WHEN lead_segment IS NULL OR lead_segment = '' OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia')
    THEN 'SIM' ELSE 'NÃO'
  END as segmento_ok,

  CASE
    WHEN lead_monthly_volume IS NULL OR lead_monthly_volume = '' OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês')
    THEN 'SIM' ELSE 'NÃO'
  END as volume_ok,

  -- MQL final
  CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    )
    AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
    AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
    THEN 'MQL' ELSE 'Lead'
  END as classificacao_sql

FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2024-02-01', '2024-03-01')
ORDER BY submitted_at;

-- =====================================================
-- 7. VERIFICAR POSSÍVEL PROBLEMA DE TIMEZONE
-- =====================================================
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,
  COUNT(*) as total,
  MIN(submitted_at) as primeira_resposta,
  MAX(submitted_at) as ultima_resposta,
  -- Verificar se há respostas no limite do mês
  COUNT(CASE WHEN EXTRACT(DAY FROM submitted_at) = 1 AND EXTRACT(HOUR FROM submitted_at) < 3 THEN 1 END) as primeiras_horas_mes,
  COUNT(CASE WHEN EXTRACT(DAY FROM submitted_at + INTERVAL '1 day') = 1 THEN 1 END) as ultimo_dia_mes
FROM yayforms_responses
WHERE submitted_at >= '2024-01-01' AND submitted_at < '2024-04-01'
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;