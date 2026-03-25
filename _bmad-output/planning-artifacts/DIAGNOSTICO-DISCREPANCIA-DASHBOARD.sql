-- =====================================================
-- DIAGNÓSTICO: Discrepância Dashboard vs Query SQL
-- Data: 2026-03-25
--
-- Dashboard mostra:
-- Jan 2026: 119 MQLs
-- Fev 2026: 118 MQLs
-- Mar 2026: 71 MQLs
--
-- Query SQL mostra valores diferentes
-- Precisamos identificar a causa
-- =====================================================

-- =====================================================
-- 1. QUERY SQL VALIDADA (DEVE SER A FONTE DA VERDADE)
-- =====================================================
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,
  COUNT(*) as mql_query_sql
FROM yayforms_responses
WHERE
  -- Faturamento adequado
  lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )

  -- Não pode ser clínica/advocacia
  AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))

  -- Regra de volume com exceção para E-commerce
  AND (
    -- E-commerce: precisa > 10.000 tickets
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
    -- Não E-commerce: regra padrão
    (COALESCE(lead_market, '') != '🛒 Ecommerce'
     AND (lead_monthly_volume IS NULL
          OR lead_monthly_volume NOT IN (
            'Menos de 1.000 por mês',
            'Entre 1.000 e 3.000 por mês',
            'Entre 1.000 e 5.000 por mês',
            'Entre 3.000 e 5.000 por mês'
          )))
  )
  AND DATE_TRUNC('month', submitted_at) >= '2026-01-01'
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- =====================================================
-- 2. ANÁLISE DETALHADA POR MÊS
-- =====================================================

-- Ver todos os dados de Janeiro 2026
SELECT
  lead_revenue_range,
  lead_segment,
  lead_monthly_volume,
  lead_market,
  COUNT(*) as quantidade,
  -- Classificação esperada
  CASE
    WHEN lead_revenue_range NOT IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    ) THEN 'Lead (Faturamento)'

    WHEN lead_segment IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia')
    THEN 'Lead (Segmento)'

    WHEN lead_market = '🛒 Ecommerce' AND lead_monthly_volume IN (
      'Menos de 1.000 por mês',
      'Entre 1.000 e 3.000 por mês',
      'Entre 1.000 e 5.000 por mês',
      'Entre 3.000 e 5.000 por mês',
      'Entre 5.000 e 10.000 por mês'
    ) THEN 'Lead (Vol E-commerce)'

    WHEN COALESCE(lead_market, '') != '🛒 Ecommerce' AND lead_monthly_volume IN (
      'Menos de 1.000 por mês',
      'Entre 1.000 e 3.000 por mês',
      'Entre 1.000 e 5.000 por mês',
      'Entre 3.000 e 5.000 por mês'
    ) THEN 'Lead (Vol Padrão)'

    ELSE 'MQL'
  END as classificacao
FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) = '2026-01-01'
GROUP BY lead_revenue_range, lead_segment, lead_monthly_volume, lead_market
ORDER BY quantidade DESC;

-- =====================================================
-- 3. POSSÍVEIS CAUSAS DA DISCREPÂNCIA
-- =====================================================

-- 3.1 Verificar se há dados sem lead_market
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,
  COUNT(*) FILTER (WHERE lead_market IS NULL) as sem_market,
  COUNT(*) FILTER (WHERE lead_market IS NOT NULL) as com_market,
  COUNT(*) as total
FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) >= '2026-01-01'
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- 3.2 Verificar valores inesperados em lead_market
SELECT DISTINCT
  lead_market,
  COUNT(*) as quantidade
FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) >= '2026-01-01'
  AND lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )
GROUP BY lead_market
ORDER BY quantidade DESC;

-- 3.3 Verificar se há problema com timezone
SELECT
  DATE_TRUNC('month', submitted_at) as mes_truncado,
  TO_CHAR(submitted_at, 'YYYY-MM-DD HH24:MI:SS') as data_completa,
  COUNT(*) as quantidade
FROM yayforms_responses
WHERE submitted_at >= '2025-12-31' AND submitted_at < '2026-02-01'
  AND lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )
GROUP BY DATE_TRUNC('month', submitted_at), TO_CHAR(submitted_at, 'YYYY-MM-DD HH24:MI:SS')
ORDER BY data_completa
LIMIT 10;

-- =====================================================
-- 4. TESTE LÓGICA JAVASCRIPT SIMULADA EM SQL
-- =====================================================

-- Simular exatamente o que o JavaScript faz
WITH classificacao_js AS (
  SELECT
    submitted_at,
    lead_revenue_range,
    lead_segment,
    lead_monthly_volume,
    lead_market,
    -- Simula classifyLead(fat, vol, seg, market)
    CASE
      -- Regra 1: Faturamento desqualificado
      WHEN lead_revenue_range IS NULL
        OR lead_revenue_range IN (
          'Zero até o momento',
          'Menos de R$100 mil',
          'Entre R$100 mil e R$500 mil',
          'Entre R$500 mil e R$1 milhão'
        ) THEN 'Lead'

      -- Regra 1b: Faturamento NÃO qualificado
      WHEN lead_revenue_range NOT IN (
        'Entre R$1 milhão a R$5 milhões',
        'Entre R$5 milhões a R$10 milhões',
        'Entre R$10 milhões a R$25 milhões',
        'Entre R$25 milhões a R$50 milhões',
        'Acima de R$50 milhões',
        'Acima de R$10 milhões'
      ) THEN 'Lead'

      -- Regra 2: Segmento desqualificado
      WHEN lead_segment IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia')
      THEN 'Lead'

      -- Regra 3: Volume E-commerce
      WHEN lead_market = '🛒 Ecommerce'
        AND lead_monthly_volume IN (
          'Menos de 1.000 por mês',
          'Entre 1.000 e 3.000 por mês',
          'Entre 1.000 e 5.000 por mês',
          'Entre 3.000 e 5.000 por mês',
          'Entre 5.000 e 10.000 por mês'
        ) THEN 'Lead'

      -- Regra 3: Volume Outros
      WHEN COALESCE(lead_market, '') != '🛒 Ecommerce'
        AND lead_monthly_volume IN (
          'Menos de 1.000 por mês',
          'Entre 1.000 e 3.000 por mês',
          'Entre 1.000 e 5.000 por mês',
          'Entre 3.000 e 5.000 por mês'
        ) THEN 'Lead'

      ELSE 'MQL'
    END as classificacao_js
  FROM yayforms_responses
  WHERE DATE_TRUNC('month', submitted_at) >= '2026-01-01'
)
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,
  COUNT(*) FILTER (WHERE classificacao_js = 'MQL') as mql_js_simulado,
  COUNT(*) as total
FROM classificacao_js
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- =====================================================
-- 5. EXPORTAR AMOSTRA PARA DEBUGGING
-- =====================================================

-- Pegar 10 exemplos de Janeiro que deveriam ser MQL
SELECT
  id,
  submitted_at,
  lead_revenue_range,
  lead_segment,
  lead_monthly_volume,
  lead_market,
  'Deveria ser MQL' as observacao
FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) = '2026-01-01'
  AND lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )
  AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
  AND (
    (lead_market = '🛒 Ecommerce' AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN (
      'Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês',
      'Entre 3.000 e 5.000 por mês', 'Entre 5.000 e 10.000 por mês'
    )))
    OR
    (COALESCE(lead_market, '') != '🛒 Ecommerce' AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN (
      'Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês', 'Entre 3.000 e 5.000 por mês'
    )))
  )
LIMIT 10;