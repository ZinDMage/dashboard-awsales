-- =====================================================
-- QUERY MQL CORRIGIDA - COM REGRA ESPECIAL PARA E-COMMERCE
-- Data: 2026-03-25
--
-- NOVA REGRA:
-- Se lead_market = '🛒 Ecommerce', precisa ter volume > 10.000 tickets/mês
-- =====================================================

-- =====================================================
-- 1. QUERY MQL COMPLETA COM REGRA E-COMMERCE
-- =====================================================
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as mql
FROM yayforms_responses
WHERE
  -- REGRA 1: Deve ter faturamento adequado (OBRIGATÓRIO)
  lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )

  -- REGRA 2: Não pode ser clínica ou advocacia
  AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))

  -- REGRA 3: Volume mínimo (com exceção especial para E-commerce)
  AND (
    -- Se NÃO for E-commerce, aplica regra normal
    (lead_market != '🛒 Ecommerce' OR lead_market IS NULL)
    AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN (
      'Menos de 1.000 por mês',
      'Entre 1.000 e 3.000 por mês',
      'Entre 1.000 e 5.000 por mês'
    ))

    OR

    -- Se FOR E-commerce, precisa ter > 10.000 tickets/mês
    (lead_market = '🛒 Ecommerce'
     AND lead_monthly_volume IN (
       'Acima de 10.000 por mês',
       'Entre 10.000 e 50.000 por mês',
       'Entre 50.000 e 100.000 por mês',
       'Acima de 100.000 por mês'
       -- Adicionar outros valores que representem > 10.000
     ))
  )
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- =====================================================
-- 2. VERSÃO ALTERNATIVA - MAIS LEGÍVEL
-- =====================================================
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as mql
FROM yayforms_responses
WHERE
  -- Faturamento adequado (sempre obrigatório)
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

  -- Regras de volume baseadas no mercado
  AND (
    CASE
      -- E-commerce precisa > 10.000 tickets
      WHEN lead_market = '🛒 Ecommerce' THEN
        lead_monthly_volume NOT IN (
          'Menos de 1.000 por mês',
          'Entre 1.000 e 3.000 por mês',
          'Entre 1.000 e 5.000 por mês',
          'Entre 5.000 e 10.000 por mês'  -- EXCLUIR até 10.000
        ) OR lead_monthly_volume IS NULL

      -- Outros mercados: regra padrão
      ELSE
        lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN (
          'Menos de 1.000 por mês',
          'Entre 1.000 e 3.000 por mês',
          'Entre 1.000 e 5.000 por mês'
        )
    END
  )
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- =====================================================
-- 3. ANÁLISE: Ver todos os valores de volume disponíveis
-- =====================================================
-- Execute para identificar TODOS os valores de volume no sistema
SELECT DISTINCT
  lead_monthly_volume,
  COUNT(*) as quantidade,
  CASE
    WHEN lead_monthly_volume ~ '^\d+' THEN
      CAST(REGEXP_REPLACE(lead_monthly_volume, '[^0-9]', '', 'g') AS INTEGER)
    ELSE 0
  END as volume_numerico_aproximado
FROM yayforms_responses
WHERE lead_monthly_volume IS NOT NULL
GROUP BY lead_monthly_volume
ORDER BY volume_numerico_aproximado;

-- =====================================================
-- 4. DIAGNÓSTICO: Impacto da nova regra E-commerce
-- =====================================================
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,

  -- MQLs sem regra E-commerce (atual)
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
  END) as mql_sem_regra_ecommerce,

  -- E-commerces que seriam excluídos pela nova regra
  COUNT(CASE
    WHEN lead_market = '🛒 Ecommerce'
    AND lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    )
    AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
    AND lead_monthly_volume IN ('Entre 5.000 e 10.000 por mês', 'Entre 3.000 e 5.000 por mês')
    THEN 1
  END) as ecommerce_excluidos,

  -- E-commerces que permanecem MQL (> 10.000)
  COUNT(CASE
    WHEN lead_market = '🛒 Ecommerce'
    AND lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    )
    AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
    AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN (
      'Menos de 1.000 por mês',
      'Entre 1.000 e 3.000 por mês',
      'Entre 1.000 e 5.000 por mês',
      'Entre 5.000 e 10.000 por mês'
    ))
    THEN 1
  END) as ecommerce_mantidos

FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2024-02-01', '2024-03-01')
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- =====================================================
-- 5. BREAKDOWN DETALHADO: E-commerce por faixa de volume
-- =====================================================
SELECT
  lead_monthly_volume,
  COUNT(*) as quantidade,
  COUNT(CASE WHEN lead_market = '🛒 Ecommerce' THEN 1 END) as ecommerce,
  COUNT(CASE WHEN lead_market != '🛒 Ecommerce' OR lead_market IS NULL THEN 1 END) as outros_mercados
FROM yayforms_responses
WHERE lead_revenue_range IN (
  'Entre R$1 milhão a R$5 milhões',
  'Entre R$5 milhões a R$10 milhões',
  'Entre R$10 milhões a R$25 milhões',
  'Entre R$25 milhões a R$50 milhões',
  'Acima de R$50 milhões',
  'Acima de R$10 milhões'
)
AND DATE_TRUNC('month', submitted_at) >= '2024-01-01'
GROUP BY lead_monthly_volume
ORDER BY
  CASE
    WHEN lead_monthly_volume = 'Menos de 1.000 por mês' THEN 1
    WHEN lead_monthly_volume = 'Entre 1.000 e 3.000 por mês' THEN 2
    WHEN lead_monthly_volume = 'Entre 3.000 e 5.000 por mês' THEN 3
    WHEN lead_monthly_volume = 'Entre 1.000 e 5.000 por mês' THEN 3.5
    WHEN lead_monthly_volume = 'Entre 5.000 e 10.000 por mês' THEN 4
    WHEN lead_monthly_volume = 'Entre 10.000 e 50.000 por mês' THEN 5
    WHEN lead_monthly_volume = 'Entre 50.000 e 100.000 por mês' THEN 6
    WHEN lead_monthly_volume = 'Acima de 10.000 por mês' THEN 7
    WHEN lead_monthly_volume = 'Acima de 100.000 por mês' THEN 8
    WHEN lead_monthly_volume IS NULL THEN 99
    ELSE 50
  END;

-- =====================================================
-- 6. QUERY FINAL RECOMENDADA
-- =====================================================
-- Esta é a query mais robusta considerando a regra E-commerce

SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as mql
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
     AND (lead_monthly_volume IS NULL  -- NULL conta como OK para e-commerce com faturamento alto
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
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;