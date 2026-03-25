-- DIAGNÓSTICO: Problema com contagem de MQLs
-- Data: 2026-03-25

-- ========================================
-- 1. QUERY ATUAL (COM PROBLEMA)
-- ========================================
-- PROBLEMA IDENTIFICADO: Lógica AND/OR mal estruturada
-- A última linha usa OR quando deveria estar dentro de um AND
-- Isso está causando a inclusão incorreta de registros

SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as mql_incorreto
FROM yayforms_responses
WHERE lead_revenue_range IN (
  'Entre R$1 milhão a R$5 milhões',
  'Entre R$5 milhões a R$10 milhões',
  'Entre R$10 milhões a R$25 milhões',
  'Entre R$25 milhões a R$50 milhões',
  'Acima de R$50 milhões',
  'Acima de R$10 milhões'
)
AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
OR (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- ========================================
-- 2. QUERY CORRIGIDA
-- ========================================
-- CORREÇÃO: Agrupar condições com parênteses apropriados

SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as mql
FROM yayforms_responses
WHERE
  -- Condição de faturamento (OBRIGATÓRIA)
  lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )
  -- E não pode ser clínica/advocacia
  AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
  -- E precisa ter volume adequado
  AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- ========================================
-- 3. QUERIES DE DIAGNÓSTICO
-- ========================================

-- 3.1. Total de respostas por mês
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as total_respostas
FROM yayforms_responses
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- 3.2. Breakdown por faixa de faturamento
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  lead_revenue_range,
  COUNT(*) as quantidade
FROM yayforms_responses
WHERE submitted_at >= '2024-01-01'
GROUP BY DATE_TRUNC('month', submitted_at), lead_revenue_range
ORDER BY mes, quantidade DESC;

-- 3.3. Verificar quais registros estão sendo incluídos incorretamente
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  lead_revenue_range,
  lead_segment,
  lead_monthly_volume,
  COUNT(*) as quantidade,
  CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    ) THEN 'Faturamento OK'
    ELSE 'Faturamento FORA'
  END as status_faturamento,
  CASE
    WHEN lead_segment IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia') THEN 'Segmento EXCLUÍDO'
    ELSE 'Segmento OK'
  END as status_segmento,
  CASE
    WHEN lead_monthly_volume IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês') THEN 'Volume BAIXO'
    ELSE 'Volume OK'
  END as status_volume
FROM yayforms_responses
WHERE submitted_at >= '2024-01-01'
GROUP BY
  DATE_TRUNC('month', submitted_at),
  lead_revenue_range,
  lead_segment,
  lead_monthly_volume
ORDER BY mes, quantidade DESC;

-- 3.4. Comparar contagem incorreta vs correta
WITH incorreta AS (
  SELECT
    DATE_TRUNC('month', submitted_at) as mes,
    COUNT(*) as mql_incorreto
  FROM yayforms_responses
  WHERE lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )
  AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
  OR (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
  GROUP BY DATE_TRUNC('month', submitted_at)
),
correta AS (
  SELECT
    DATE_TRUNC('month', submitted_at) as mes,
    COUNT(*) as mql_correto
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
)
SELECT
  COALESCE(i.mes, c.mes) as mes,
  COALESCE(i.mql_incorreto, 0) as mql_incorreto,
  COALESCE(c.mql_correto, 0) as mql_correto,
  COALESCE(i.mql_incorreto, 0) - COALESCE(c.mql_correto, 0) as diferenca
FROM incorreta i
FULL OUTER JOIN correta c ON i.mes = c.mes
ORDER BY mes;

-- 3.5. Ver exemplos de registros que estão sendo incluídos incorretamente
SELECT
  submitted_at,
  lead_revenue_range,
  lead_segment,
  lead_monthly_volume,
  'INCLUÍDO INCORRETAMENTE' as problema
FROM yayforms_responses
WHERE
  -- Condição que captura registros incorretos (sem faturamento adequado mas com volume OK)
  (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
  AND (
    lead_revenue_range IS NULL
    OR lead_revenue_range NOT IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    )
  )
ORDER BY submitted_at DESC
LIMIT 10;

-- ========================================
-- 4. QUERY ALTERNATIVA MAIS CLARA
-- ========================================
-- Versão mais explícita para facilitar manutenção

SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as mql
FROM yayforms_responses
WHERE 1=1
  -- REGRA 1: Deve ter faturamento adequado
  AND lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )
  -- REGRA 2: Não pode ser clínica ou advocacia
  AND (
    lead_segment IS NULL
    OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia')
  )
  -- REGRA 3: Não pode ter volume baixo
  AND (
    lead_monthly_volume IS NULL
    OR lead_monthly_volume NOT IN (
      'Menos de 1.000 por mês',
      'Entre 1.000 e 3.000 por mês',
      'Entre 1.000 e 5.000 por mês'
    )
  )
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;