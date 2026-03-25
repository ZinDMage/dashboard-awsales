# 🎯 SOLUÇÃO IDENTIFICADA - Discrepância MQLs

## 📊 Comparação dos Resultados

| Mês | Planilha Excel | SQL Atual | NULL Excluído | Só Faturamento | Vazio=NULL |
|-----|----------------|-----------|---------------|----------------|------------|
| Jan | **114** | 130 | 39 | 386 | 130 |
| Fev | **124** | 130 | 56 | 492 | 130 |
| Mar | **117** | 79 | 35 | 286 | 79 |

## 🔍 PROBLEMA IDENTIFICADO

**NENHUMA das lógicas testadas bate exatamente com os números da planilha!**

Isso indica que a planilha Excel está usando uma **lógica híbrida** ou tem **dados diferentes**.

## 📈 Análise dos Padrões

### Observações Importantes:

1. **SQL Atual (130, 130, 79)** - Conta MAIS que a planilha em Jan/Fev, MENOS em Mar
2. **NULL Excluído (39, 56, 35)** - Conta MUITO MENOS que a planilha
3. **Só Faturamento (386, 492, 286)** - Conta MUITO MAIS que a planilha

### Conclusão:
Os números da planilha (114, 124, 117) estão **entre** as lógicas:
- Mais que "NULL Excluído" (39, 56, 35)
- Menos que "SQL Atual" (130, 130, 79)

## 💡 HIPÓTESES MAIS PROVÁVEIS

### 1. **Valores Específicos de Faturamento**
A planilha pode estar usando valores de faturamento DIFERENTES:
- Talvez exclua "Acima de R$10 milhões"
- Ou inclua algum valor que não está na nossa lista

### 2. **Lógica Diferente para Segmento/Volume**
A planilha pode estar:
- Excluindo alguns NULLs mas não todos
- Tratando string vazia diferente de NULL
- Usando outros valores para exclusão

### 3. **Filtro Adicional**
A planilha pode ter um filtro adicional que não conhecemos:
- Data específica
- Outro campo
- Condição combinada

## 🔧 PRÓXIMOS PASSOS PARA RESOLVER

### PASSO 1: Verificar valores exatos de faturamento
```sql
-- Ver quantos registros tem cada valor de faturamento
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,
  lead_revenue_range,
  COUNT(*) as quantidade
FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2024-02-01', '2024-03-01')
  AND lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )
GROUP BY DATE_TRUNC('month', submitted_at), lead_revenue_range
ORDER BY mes, quantidade DESC;
```

### PASSO 2: Testar excluindo "Acima de R$10 milhões"
```sql
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,

  -- Sem "Acima de R$10 milhões"
  COUNT(CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões'
      -- REMOVIDO: 'Acima de R$10 milhões'
    )
    AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
    AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
    THEN 1
  END) as sem_acima_10mi,

  -- Planilha Excel
  CASE
    WHEN TO_CHAR(DATE_TRUNC('month', submitted_at), 'MM') = '01' THEN 114
    WHEN TO_CHAR(DATE_TRUNC('month', submitted_at), 'MM') = '02' THEN 124
    WHEN TO_CHAR(DATE_TRUNC('month', submitted_at), 'MM') = '03' THEN 117
  END as planilha_excel

FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2026-01-01', '2026-02-01', '2026-03-01')
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;
```

### PASSO 3: Análise detalhada por registro
```sql
-- Exportar TODOS os dados para comparar com Excel
SELECT
  submitted_at,
  lead_revenue_range,
  lead_segment,
  lead_monthly_volume,

  -- Classificação por diferentes lógicas
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
    THEN 'MQL_SQL_ATUAL'
    ELSE 'LEAD'
  END as classificacao_sql,

  CASE
    WHEN lead_revenue_range IN (
      'Entre R$1 milhão a R$5 milhões',
      'Entre R$5 milhões a R$10 milhões',
      'Entre R$10 milhões a R$25 milhões',
      'Entre R$25 milhões a R$50 milhões',
      'Acima de R$50 milhões'
      -- SEM 'Acima de R$10 milhões'
    )
    AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
    AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
    THEN 'MQL_SEM_10MI'
    ELSE 'LEAD'
  END as classificacao_sem_10mi

FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2026-02-01', '2026-03-01')
ORDER BY submitted_at;
```

## 🎯 AÇÃO RECOMENDADA

### Opção 1: Ajustar SQL para bater com Excel
1. Execute as queries acima para identificar a lógica exata
2. Ajuste a query SQL com a lógica encontrada

### Opção 2: Validar a Planilha Excel
1. Exporte os dados brutos (query do PASSO 3)
2. Revise as fórmulas do Excel
3. Identifique qual lógica está sendo usada

### Opção 3: Definir uma Lógica Única
1. Documente a regra de negócio oficial
2. Ajuste tanto SQL quanto Excel para usar a mesma lógica
3. Garanta consistência futura

## 📝 Possível Query Ajustada

Se descobrirmos que o problema é "Acima de R$10 milhões", a query corrigida seria:

```sql
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
    'Acima de R$50 milhões'
    -- REMOVIDO: 'Acima de R$10 milhões' (possível duplicação)
  )
  AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
  AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN ('Menos de 1.000 por mês', 'Entre 1.000 e 3.000 por mês', 'Entre 1.000 e 5.000 por mês'))
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;
```

Execute as queries de diagnóstico e me envie os resultados!