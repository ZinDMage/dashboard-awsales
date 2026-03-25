-- =====================================================
-- AUDITORIA DE DUPLICATAS - YAYFORMS_RESPONSES
-- Data: 2026-03-25
--
-- Objetivo: Identificar e remover respostas duplicadas
-- mantendo apenas a mais recente por email ou telefone
-- =====================================================

-- =====================================================
-- 1. ANÁLISE GERAL DE DUPLICATAS
-- =====================================================

-- 1.1 Resumo de duplicatas por EMAIL
WITH duplicatas_email AS (
  SELECT
    lead_email,
    COUNT(*) as total_respostas,
    MIN(submitted_at) as primeira_resposta,
    MAX(submitted_at) as ultima_resposta,
    ARRAY_AGG(id ORDER BY submitted_at DESC) as ids,
    ARRAY_AGG(submitted_at ORDER BY submitted_at DESC) as datas
  FROM yayforms_responses
  WHERE lead_email IS NOT NULL
    AND lead_email != ''
  GROUP BY lead_email
  HAVING COUNT(*) > 1
)
SELECT
  COUNT(*) as total_emails_duplicados,
  SUM(total_respostas) as total_respostas_duplicadas,
  SUM(total_respostas - 1) as respostas_para_deletar,
  MAX(total_respostas) as max_duplicatas_por_email
FROM duplicatas_email;

-- 1.2 Resumo de duplicatas por TELEFONE
WITH duplicatas_phone AS (
  SELECT
    lead_phone,
    COUNT(*) as total_respostas,
    MIN(submitted_at) as primeira_resposta,
    MAX(submitted_at) as ultima_resposta,
    ARRAY_AGG(id ORDER BY submitted_at DESC) as ids,
    ARRAY_AGG(submitted_at ORDER BY submitted_at DESC) as datas
  FROM yayforms_responses
  WHERE lead_phone IS NOT NULL
    AND lead_phone != ''
  GROUP BY lead_phone
  HAVING COUNT(*) > 1
)
SELECT
  COUNT(*) as total_phones_duplicados,
  SUM(total_respostas) as total_respostas_duplicadas,
  SUM(total_respostas - 1) as respostas_para_deletar,
  MAX(total_respostas) as max_duplicatas_por_phone
FROM duplicatas_phone;

-- =====================================================
-- 2. DETALHAMENTO DAS DUPLICATAS
-- =====================================================

-- 2.1 Top 10 emails com mais duplicatas
SELECT
  lead_email,
  COUNT(*) as total_respostas,
  MIN(submitted_at)::date as primeira_resposta,
  MAX(submitted_at)::date as ultima_resposta,
  MAX(submitted_at) - MIN(submitted_at) as intervalo,
  STRING_AGG(lead_revenue_range, ' -> ' ORDER BY submitted_at) as evolucao_faturamento
FROM yayforms_responses
WHERE lead_email IS NOT NULL
  AND lead_email != ''
GROUP BY lead_email
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC
LIMIT 10;

-- 2.2 Análise temporal das duplicatas
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as total_respostas,
  COUNT(DISTINCT lead_email) as emails_unicos,
  COUNT(*) - COUNT(DISTINCT lead_email) as duplicatas_por_email,
  ROUND((COUNT(*) - COUNT(DISTINCT lead_email))::numeric / COUNT(*) * 100, 2) as pct_duplicatas
FROM yayforms_responses
WHERE lead_email IS NOT NULL AND lead_email != ''
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- =====================================================
-- 3. IDENTIFICAR REGISTROS PARA DELETAR
-- =====================================================

-- 3.1 Lista de IDs para deletar (duplicatas por EMAIL - mantém a mais recente)
WITH ranked_responses AS (
  SELECT
    id,
    lead_email,
    submitted_at,
    ROW_NUMBER() OVER (PARTITION BY lead_email ORDER BY submitted_at DESC) as rn
  FROM yayforms_responses
  WHERE lead_email IS NOT NULL
    AND lead_email != ''
)
SELECT
  id,
  lead_email,
  submitted_at,
  'DELETE' as acao
FROM ranked_responses
WHERE rn > 1
ORDER BY lead_email, submitted_at DESC;

-- 3.2 Lista de IDs para deletar (duplicatas por TELEFONE - mantém a mais recente)
WITH ranked_responses AS (
  SELECT
    id,
    lead_phone,
    lead_email,
    submitted_at,
    ROW_NUMBER() OVER (PARTITION BY lead_phone ORDER BY submitted_at DESC) as rn
  FROM yayforms_responses
  WHERE lead_phone IS NOT NULL
    AND lead_phone != ''
)
SELECT
  id,
  lead_phone,
  lead_email,
  submitted_at,
  'DELETE' as acao
FROM ranked_responses
WHERE rn > 1
ORDER BY lead_phone, submitted_at DESC;

-- =====================================================
-- 4. IMPACTO NAS MÉTRICAS MQL
-- =====================================================

-- 4.1 Impacto nas métricas de MQL por mês
WITH duplicatas_para_deletar AS (
  SELECT id
  FROM (
    SELECT
      id,
      ROW_NUMBER() OVER (PARTITION BY lead_email ORDER BY submitted_at DESC) as rn
    FROM yayforms_responses
    WHERE lead_email IS NOT NULL AND lead_email != ''
  ) ranked
  WHERE rn > 1
),
metricas_antes AS (
  SELECT
    DATE_TRUNC('month', submitted_at) as mes,
    COUNT(*) as total_respostas,
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
      THEN 1
    END) as mql_antes
  FROM yayforms_responses
  WHERE DATE_TRUNC('month', submitted_at) >= '2024-01-01'
  GROUP BY DATE_TRUNC('month', submitted_at)
),
metricas_depois AS (
  SELECT
    DATE_TRUNC('month', submitted_at) as mes,
    COUNT(*) as total_respostas,
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
      THEN 1
    END) as mql_depois
  FROM yayforms_responses
  WHERE id NOT IN (SELECT id FROM duplicatas_para_deletar)
    AND DATE_TRUNC('month', submitted_at) >= '2024-01-01'
  GROUP BY DATE_TRUNC('month', submitted_at)
)
SELECT
  TO_CHAR(a.mes, 'YYYY-MM') as mes,
  a.total_respostas as respostas_antes,
  d.total_respostas as respostas_depois,
  a.total_respostas - d.total_respostas as respostas_deletadas,
  a.mql_antes,
  d.mql_depois,
  a.mql_antes - d.mql_depois as mql_deletados,
  CASE
    WHEN a.mql_antes > 0
    THEN ROUND((a.mql_antes - d.mql_depois)::numeric / a.mql_antes * 100, 2)
    ELSE 0
  END as pct_reducao_mql
FROM metricas_antes a
JOIN metricas_depois d ON a.mes = d.mes
ORDER BY a.mes;

-- =====================================================
-- 5. VALIDAÇÃO ANTES DE DELETAR
-- =====================================================

-- 5.1 Verificar casos especiais (mesmo email, informações diferentes)
WITH duplicatas AS (
  SELECT
    lead_email,
    COUNT(DISTINCT lead_revenue_range) as faturamentos_diferentes,
    COUNT(DISTINCT lead_segment) as segmentos_diferentes,
    COUNT(DISTINCT lead_monthly_volume) as volumes_diferentes,
    COUNT(*) as total_respostas,
    MAX(submitted_at) as ultima_resposta,
    MIN(submitted_at) as primeira_resposta
  FROM yayforms_responses
  WHERE lead_email IS NOT NULL AND lead_email != ''
  GROUP BY lead_email
  HAVING COUNT(*) > 1
)
SELECT
  lead_email,
  total_respostas,
  faturamentos_diferentes,
  segmentos_diferentes,
  volumes_diferentes,
  primeira_resposta::date,
  ultima_resposta::date,
  CASE
    WHEN faturamentos_diferentes > 1 OR segmentos_diferentes > 1 OR volumes_diferentes > 1
    THEN 'ATENÇÃO: Informações mudaram entre respostas'
    ELSE 'OK: Informações consistentes'
  END as status
FROM duplicatas
WHERE faturamentos_diferentes > 1
   OR segmentos_diferentes > 1
   OR volumes_diferentes > 1
ORDER BY total_respostas DESC
LIMIT 20;

-- =====================================================
-- 6. SCRIPTS DE LIMPEZA
-- =====================================================

-- 6.1 BACKUP antes de deletar (criar tabela de backup)
/*
CREATE TABLE yayforms_responses_backup_20260325 AS
SELECT * FROM yayforms_responses;

-- Verificar backup
SELECT COUNT(*) FROM yayforms_responses_backup_20260325;
*/

-- 6.2 DELETE duplicatas por EMAIL (mantém a mais recente)
/*
WITH duplicatas_para_deletar AS (
  SELECT id
  FROM (
    SELECT
      id,
      ROW_NUMBER() OVER (PARTITION BY lead_email ORDER BY submitted_at DESC) as rn
    FROM yayforms_responses
    WHERE lead_email IS NOT NULL AND lead_email != ''
  ) ranked
  WHERE rn > 1
)
DELETE FROM yayforms_responses
WHERE id IN (SELECT id FROM duplicatas_para_deletar);
*/

-- 6.3 DELETE duplicatas por TELEFONE (mantém a mais recente)
/*
WITH duplicatas_para_deletar AS (
  SELECT id
  FROM (
    SELECT
      id,
      ROW_NUMBER() OVER (PARTITION BY lead_phone ORDER BY submitted_at DESC) as rn
    FROM yayforms_responses
    WHERE lead_phone IS NOT NULL AND lead_phone != ''
  ) ranked
  WHERE rn > 1
)
DELETE FROM yayforms_responses
WHERE id IN (SELECT id FROM duplicatas_para_deletar);
*/

-- 6.4 ALTERNATIVA: Delete combinando EMAIL OU TELEFONE
/*
WITH duplicatas_para_deletar AS (
  SELECT DISTINCT id
  FROM (
    -- Duplicatas por email
    SELECT id
    FROM (
      SELECT
        id,
        ROW_NUMBER() OVER (PARTITION BY lead_email ORDER BY submitted_at DESC) as rn
      FROM yayforms_responses
      WHERE lead_email IS NOT NULL AND lead_email != ''
    ) ranked_email
    WHERE rn > 1

    UNION

    -- Duplicatas por telefone
    SELECT id
    FROM (
      SELECT
        id,
        ROW_NUMBER() OVER (PARTITION BY lead_phone ORDER BY submitted_at DESC) as rn
      FROM yayforms_responses
      WHERE lead_phone IS NOT NULL AND lead_phone != ''
    ) ranked_phone
    WHERE rn > 1
  ) all_duplicates
)
DELETE FROM yayforms_responses
WHERE id IN (SELECT id FROM duplicatas_para_deletar);
*/

-- =====================================================
-- 7. VALIDAÇÃO PÓS-LIMPEZA
-- =====================================================

-- 7.1 Verificar se ainda existem duplicatas
SELECT
  'Email' as tipo,
  COUNT(*) as duplicatas_restantes
FROM (
  SELECT lead_email
  FROM yayforms_responses
  WHERE lead_email IS NOT NULL AND lead_email != ''
  GROUP BY lead_email
  HAVING COUNT(*) > 1
) dup_email

UNION ALL

SELECT
  'Telefone' as tipo,
  COUNT(*) as duplicatas_restantes
FROM (
  SELECT lead_phone
  FROM yayforms_responses
  WHERE lead_phone IS NOT NULL AND lead_phone != ''
  GROUP BY lead_phone
  HAVING COUNT(*) > 1
) dup_phone;