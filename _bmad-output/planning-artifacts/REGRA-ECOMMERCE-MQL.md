# 🛒 Nova Regra para E-commerce - MQL

## 📋 Resumo da Alteração

**NOVA REGRA**: Leads de E-commerce (`lead_market = '🛒 Ecommerce'`) precisam ter **mais de 10.000 tickets mensais** para serem considerados MQLs.

## 🎯 Regras de Qualificação MQL

### Para E-commerce:
1. ✅ Faturamento entre R$ 1M e R$ 50M+ (obrigatório)
2. ✅ Não ser clínica/advocacia
3. ✅ **Volume > 10.000 tickets/mês** ⚠️ ESPECIAL

### Para Outros Mercados:
1. ✅ Faturamento entre R$ 1M e R$ 50M+ (obrigatório)
2. ✅ Não ser clínica/advocacia
3. ✅ Volume > 5.000 tickets/mês (padrão)

## 📊 Faixas de Volume Excluídas

### E-commerce EXCLUI:
- ❌ Menos de 1.000 por mês
- ❌ Entre 1.000 e 3.000 por mês
- ❌ Entre 1.000 e 5.000 por mês
- ❌ Entre 3.000 e 5.000 por mês
- ❌ **Entre 5.000 e 10.000 por mês** ← DIFERENCIAL

### Outros Mercados EXCLUEM:
- ❌ Menos de 1.000 por mês
- ❌ Entre 1.000 e 3.000 por mês
- ❌ Entre 1.000 e 5.000 por mês
- ❌ Entre 3.000 e 5.000 por mês
- ✅ Entre 5.000 e 10.000 por mês (aceito para não-ecommerce)

## 🔧 Query Atualizada

```sql
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as mql
FROM yayforms_responses
WHERE
  -- Faturamento (obrigatório para todos)
  lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )

  -- Segmento permitido
  AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))

  -- Regra de volume baseada no mercado
  AND (
    -- E-commerce: > 10.000
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
    -- Outros: > 5.000
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

## 📈 Impacto Esperado

### Antes da mudança:
- E-commerces com 5.000-10.000 tickets eram MQLs

### Depois da mudança:
- E-commerces com 5.000-10.000 tickets **NÃO são mais MQLs**
- Redução no número total de MQLs
- Aumento na qualidade dos MQLs de e-commerce

## 🔍 Query de Diagnóstico

Para ver o impacto da mudança:

```sql
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,

  -- E-commerces que SERÃO excluídos
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
    AND lead_monthly_volume IN ('Entre 5.000 e 10.000 por mês')
    THEN 1
  END) as ecommerce_5k_10k_excluidos,

  -- Total MQLs antes
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
    AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN (
      'Menos de 1.000 por mês',
      'Entre 1.000 e 3.000 por mês',
      'Entre 1.000 e 5.000 por mês'
    ))
    THEN 1
  END) as mql_regra_antiga

FROM yayforms_responses
WHERE submitted_at >= '2024-01-01'
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;
```

## 📝 Observações

1. **NULL é aceito**: Se o campo `lead_monthly_volume` for NULL, o lead ainda pode ser MQL (assumimos volume alto)

2. **Validar valores**: Execute a seção 3 do arquivo `MQL-QUERY-ECOMMERCE.sql` para ver todos os valores de volume disponíveis

3. **Ajustar se necessário**: Se houver outros valores representando > 10.000 tickets, adicione à query

## 📅 Data da Implementação
2026-03-25