# Análise do Problema: MQLs não estão batendo

## 🔴 PROBLEMA IDENTIFICADO

A query de MQLs tinha um **erro crítico de lógica** com operadores AND/OR mal estruturados.

### Query com Problema (ANTES):
```sql
WHERE lead_revenue_range IN (...)
AND (lead_segment IS NULL OR lead_segment NOT IN (...))
OR (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN (...))  -- ❌ ERRO: OR solto aqui!
```

O último `OR` estava **fora do agrupamento correto**, causando a inclusão de registros que:
- Não tinham faturamento adequado MAS
- Tinham volume OK

Isso fazia a query incluir TODOS os leads com volume adequado, independente do faturamento!

### Query Corrigida (DEPOIS):
```sql
WHERE lead_revenue_range IN (...)
AND (lead_segment IS NULL OR lead_segment NOT IN (...))
AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN (...))  -- ✅ CORRETO: AND aqui!
```

## 📊 Regras de Negócio para MQL

Um lead é considerado MQL quando **TODAS** as condições abaixo são atendidas:

### 1. Faturamento Adequado (OBRIGATÓRIO)
Deve ter um dos seguintes faturamentos:
- Entre R$1 milhão a R$5 milhões
- Entre R$5 milhões a R$10 milhões
- Entre R$10 milhões a R$25 milhões
- Entre R$25 milhões a R$50 milhões
- Acima de R$50 milhões
- Acima de R$10 milhões

### 2. Segmento Permitido
NÃO pode ser:
- 🩺 Clínica / consultório
- ⚖️ Escritório de advocacia

### 3. Volume Adequado
NÃO pode ter volume baixo:
- Menos de 1.000 por mês
- Entre 1.000 e 3.000 por mês
- Entre 1.000 e 5.000 por mês

## 🔍 Como Validar a Correção

### 1. Comparar Contagens
```sql
-- Executar query de diagnóstico do arquivo DIAGNOSTICO-MQL.sql
-- Seção 3.4 mostra a diferença entre contagem incorreta vs correta
```

### 2. Verificar Registros Incluídos Incorretamente
```sql
-- Ver exemplos de registros que estavam sendo incluídos incorretamente
SELECT
  submitted_at,
  lead_revenue_range,
  lead_segment,
  lead_monthly_volume
FROM yayforms_responses
WHERE
  -- Tem volume OK mas não tem faturamento adequado
  (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN (
    'Menos de 1.000 por mês',
    'Entre 1.000 e 3.000 por mês',
    'Entre 1.000 e 5.000 por mês'
  ))
  AND lead_revenue_range NOT IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )
ORDER BY submitted_at DESC
LIMIT 20;
```

### 3. Verificar Breakdown por Mês
```sql
-- Comparar MQLs por mês (antes vs depois da correção)
WITH corrigido AS (
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
)
SELECT
  mes,
  mql as mql_corrigido
FROM corrigido
WHERE mes >= '2024-01-01'
ORDER BY mes;
```

## 🎯 Impacto Esperado

### Antes (com erro):
- MQLs inflados incluindo leads sem faturamento adequado
- Taxa de conversão MQL→SQL artificialmente baixa
- CAC distorcido (mais MQLs = menor CAC aparente)

### Depois (corrigido):
- ✅ MQLs refletindo apenas leads verdadeiramente qualificados
- ✅ Taxa de conversão MQL→SQL mais realista
- ✅ CAC mais preciso
- ✅ Métricas de funil mais confiáveis

## 📝 Próximos Passos

1. **Executar queries de validação** no arquivo `DIAGNOSTICO-MQL.sql`
2. **Comparar resultados** antes e depois da correção
3. **Verificar impacto** nas métricas derivadas:
   - Taxa de conversão MQL→SQL (p.qs)
   - CAC (f.cac = gasto_ads / mql)
   - ROI (roi = (receita - gasto_ads) / gasto_ads)

## 🚨 Outros Pontos de Atenção

### Verificar Consistência com JavaScript
O arquivo `dataService.js` tem a função `classifyLead()` que deve usar a mesma lógica:
```javascript
function classifyLead(fat, vol, seg) {
  if (disqualifiedRanges.includes(fat)) return 'Lead';
  if (seg && disqualifiedSegments.includes(seg)) return 'Lead';
  if (vol && disqualifiedTicketVolumes.includes(vol)) return 'Lead';
  if (qualifiedRanges.includes(fat)) return 'MQL';
  return 'Lead';
}
```

**IMPORTANTE**: A lógica JavaScript está correta! Ela verifica:
1. Se o faturamento é desqualificado → Lead
2. Se o segmento é desqualificado → Lead
3. Se o volume é baixo → Lead
4. Se passou em tudo E tem faturamento qualificado → MQL

## 📅 Data da Correção
2026-03-25