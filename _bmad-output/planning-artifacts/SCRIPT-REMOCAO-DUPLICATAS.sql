-- =====================================================
-- SCRIPT DE REMOÇÃO DE DUPLICATAS - YAYFORMS_RESPONSES
-- Data: 2026-03-25
--
-- ATENÇÃO: Execute em ordem sequencial
-- Sempre faça backup antes de deletar dados!
-- =====================================================

-- =====================================================
-- PASSO 1: CRIAR BACKUP (OBRIGATÓRIO!)
-- =====================================================
CREATE TABLE yayforms_responses_backup_20260325 AS
SELECT * FROM yayforms_responses;

-- Verificar se o backup foi criado corretamente
SELECT
  'Original' as tabela,
  COUNT(*) as total_registros,
  COUNT(DISTINCT lead_email) as emails_unicos,
  COUNT(DISTINCT lead_phone) as telefones_unicos
FROM yayforms_responses
UNION ALL
SELECT
  'Backup' as tabela,
  COUNT(*) as total_registros,
  COUNT(DISTINCT lead_email) as emails_unicos,
  COUNT(DISTINCT lead_phone) as telefones_unicos
FROM yayforms_responses_backup_20260325;

-- =====================================================
-- PASSO 2: ANÁLISE PRÉ-LIMPEZA
-- =====================================================

-- 2.1 Resumo de duplicatas que serão removidas
WITH duplicatas_email AS (
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
duplicatas_phone AS (
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
SELECT
  (SELECT COUNT(*) FROM yayforms_responses) as total_registros_atual,
  (SELECT COUNT(*) FROM duplicatas_email) as duplicatas_por_email,
  (SELECT COUNT(*) FROM duplicatas_phone) as duplicatas_por_telefone,
  (SELECT COUNT(DISTINCT id) FROM (
    SELECT id FROM duplicatas_email
    UNION
    SELECT id FROM duplicatas_phone
  ) all_dup) as total_para_deletar,
  (SELECT COUNT(*) FROM yayforms_responses) -
  (SELECT COUNT(DISTINCT id) FROM (
    SELECT id FROM duplicatas_email
    UNION
    SELECT id FROM duplicatas_phone
  ) all_dup) as registros_apos_limpeza;

-- 2.2 Impacto nos MQLs por mês
WITH duplicatas_ids AS (
  SELECT DISTINCT id
  FROM (
    SELECT id FROM (
      SELECT id, ROW_NUMBER() OVER (PARTITION BY lead_email ORDER BY submitted_at DESC) as rn
      FROM yayforms_responses
      WHERE lead_email IS NOT NULL AND lead_email != ''
    ) e WHERE rn > 1

    UNION

    SELECT id FROM (
      SELECT id, ROW_NUMBER() OVER (PARTITION BY lead_phone ORDER BY submitted_at DESC) as rn
      FROM yayforms_responses
      WHERE lead_phone IS NOT NULL AND lead_phone != ''
    ) p WHERE rn > 1
  ) all_duplicates
)
SELECT
  TO_CHAR(DATE_TRUNC('month', y.submitted_at), 'YYYY-MM') as mes,
  COUNT(*) as total_deletados,
  COUNT(CASE
    WHEN y.lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões',
      'Acima de R$10 milhões'
    )
    AND (y.lead_segment IS NULL OR y.lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
    AND (
      (y.lead_market = '🛒 Ecommerce' AND (y.lead_monthly_volume IS NULL OR y.lead_monthly_volume NOT IN (
        'Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês',
        'Entre 3.000 e 5.000 por mês', 'Entre 5.000 e 10.000 por mês'
      )))
      OR
      (COALESCE(y.lead_market, '') != '🛒 Ecommerce' AND (y.lead_monthly_volume IS NULL OR y.lead_monthly_volume NOT IN (
        'Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês', 'Entre 3.000 e 5.000 por mês'
      )))
    )
    THEN 1
  END) as mqls_deletados
FROM yayforms_responses y
INNER JOIN duplicatas_ids d ON y.id = d.id
WHERE DATE_TRUNC('month', y.submitted_at) >= '2024-01-01'
GROUP BY DATE_TRUNC('month', y.submitted_at)
ORDER BY mes;

-- =====================================================
-- PASSO 3: REMOÇÃO DE DUPLICATAS
-- =====================================================

-- OPÇÃO A: Remover duplicatas por EMAIL (recomendado executar primeiro)
BEGIN;

-- Mostrar quantos registros serão deletados
SELECT COUNT(*) as registros_para_deletar
FROM (
  SELECT id, ROW_NUMBER() OVER (PARTITION BY lead_email ORDER BY submitted_at DESC) as rn
  FROM yayforms_responses
  WHERE lead_email IS NOT NULL AND lead_email != ''
) ranked
WHERE rn > 1;

-- Executar delete
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

-- Verificar resultado
SELECT 'Duplicatas por email removidas' as status, COUNT(*) as registros_restantes
FROM yayforms_responses;

COMMIT;

-- OPÇÃO B: Remover duplicatas por TELEFONE (executar após OPÇÃO A)
BEGIN;

-- Mostrar quantos registros serão deletados
SELECT COUNT(*) as registros_para_deletar
FROM (
  SELECT id, ROW_NUMBER() OVER (PARTITION BY lead_phone ORDER BY submitted_at DESC) as rn
  FROM yayforms_responses
  WHERE lead_phone IS NOT NULL AND lead_phone != ''
) ranked
WHERE rn > 1;

-- Executar delete
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

-- Verificar resultado
SELECT 'Duplicatas por telefone removidas' as status, COUNT(*) as registros_restantes
FROM yayforms_responses;

COMMIT;

-- =====================================================
-- PASSO 4: VALIDAÇÃO PÓS-LIMPEZA
-- =====================================================

-- 4.1 Verificar se ainda existem duplicatas
SELECT
  'Por Email' as tipo,
  COUNT(*) as duplicatas_restantes,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ Limpeza concluída com sucesso'
    ELSE '❌ Ainda existem duplicatas'
  END as status
FROM (
  SELECT lead_email, COUNT(*) as cnt
  FROM yayforms_responses
  WHERE lead_email IS NOT NULL AND lead_email != ''
  GROUP BY lead_email
  HAVING COUNT(*) > 1
) dup_email

UNION ALL

SELECT
  'Por Telefone' as tipo,
  COUNT(*) as duplicatas_restantes,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ Limpeza concluída com sucesso'
    ELSE '❌ Ainda existem duplicatas'
  END as status
FROM (
  SELECT lead_phone, COUNT(*) as cnt
  FROM yayforms_responses
  WHERE lead_phone IS NOT NULL AND lead_phone != ''
  GROUP BY lead_phone
  HAVING COUNT(*) > 1
) dup_phone;

-- 4.2 Comparação antes e depois
SELECT
  'Antes da limpeza' as momento,
  COUNT(*) as total_registros,
  COUNT(DISTINCT lead_email) as emails_unicos,
  COUNT(DISTINCT lead_phone) as telefones_unicos,
  COUNT(*) - COUNT(DISTINCT lead_email) as duplicatas_email,
  COUNT(*) - COUNT(DISTINCT lead_phone) as duplicatas_phone
FROM yayforms_responses_backup_20260325

UNION ALL

SELECT
  'Depois da limpeza' as momento,
  COUNT(*) as total_registros,
  COUNT(DISTINCT lead_email) as emails_unicos,
  COUNT(DISTINCT lead_phone) as telefones_unicos,
  COUNT(*) - COUNT(DISTINCT lead_email) as duplicatas_email,
  COUNT(*) - COUNT(DISTINCT lead_phone) as duplicatas_phone
FROM yayforms_responses;

-- 4.3 Nova contagem de MQLs por mês
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,
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
  END) as mqls_apos_limpeza
FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) >= '2024-01-01'
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;

-- =====================================================
-- PASSO 5: ROLLBACK (SE NECESSÁRIO)
-- =====================================================

-- Se algo deu errado, restaurar do backup:
/*
-- Deletar tabela atual
TRUNCATE TABLE yayforms_responses;

-- Restaurar do backup
INSERT INTO yayforms_responses
SELECT * FROM yayforms_responses_backup_20260325;

-- Verificar
SELECT COUNT(*) FROM yayforms_responses;
*/

-- =====================================================
-- PASSO 6: LIMPEZA FINAL
-- =====================================================

-- Após confirmar que tudo está OK, você pode dropar a tabela de backup
-- (Recomendo manter por pelo menos 30 dias)
/*
DROP TABLE IF EXISTS yayforms_responses_backup_20260325;
*/