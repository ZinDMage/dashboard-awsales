# 🔍 Análise da Discrepância: MQLs Excel vs SQL

## 📊 Resumo da Discrepância

| Mês | Planilha Excel | Query SQL | Diferença | Status |
|-----|---------------|-----------|-----------|---------|
| Janeiro | 114 MQLs | 130 MQLs | +16 | SQL conta MAIS |
| Fevereiro | 124 MQLs | 130 MQLs | +6 | SQL conta MAIS |
| Março | 117 MQLs | 78 MQLs | -39 | SQL conta MENOS |

## 🎯 Possíveis Causas da Diferença

### 1. **Tratamento de Valores NULL** ⭐ MAIS PROVÁVEL
**SQL**: `lead_segment IS NULL OR lead_segment NOT IN (...)`
- NULL é tratado como "OK" (não excluído)

**Excel**: Fórmulas podem tratar células vazias diferente
- SE(célula="", ...) pode dar resultado diferente de NULL no SQL
- Excel pode considerar célula vazia como texto vazio "", não NULL

### 2. **Tratamento de Strings Vazias vs NULL**
```sql
-- SQL diferencia entre:
NULL      -- ausência de valor
''        -- string vazia
' '       -- espaço em branco
```

**Excel** pode tratar todos como a mesma coisa dependendo da fórmula.

### 3. **Problema de Timezone/Data**
- Respostas próximas à virada do mês podem cair em meses diferentes
- Excel pode estar usando timezone local, SQL usando UTC

### 4. **Diferença nas Strings de Comparação**
Verificar se os valores são EXATAMENTE iguais:
- `'Entre R$1 milhão a R$5 milhões'` vs `'Entre R$1 milhão a R$5 milhões'` (espaços diferentes)
- Caracteres invisíveis ou encoding diferente
- Maiúsculas/minúsculas

### 5. **Lógica de Exclusão Diferente**
**SQL Atual**:
```sql
AND (lead_segment IS NULL OR lead_segment NOT IN ('🩺 Clínica / consultório', '⚖️ Escritório de advocacia'))
```
Significa: "Se o segmento for NULL OU não for clínica/advocacia, está OK"

**Possível Excel**:
- Pode estar excluindo NULLs/vazios
- Pode ter lógica invertida em algum ponto

## 🔧 Queries de Diagnóstico para Executar

### QUERY 1: Comparar diferentes lógicas
Execute a **Seção 5** do arquivo `DIAGNOSTICO-DISCREPANCIA-MQL.sql`:
```sql
-- Compara 4 lógicas diferentes:
-- 1. SQL atual (NULL = OK)
-- 2. NULL é excluído
-- 3. Apenas faturamento importa
-- 4. Vazio = NULL
```

### QUERY 2: Ver valores únicos
Execute as **Seções 4.1, 4.2, 4.3** para ver TODOS os valores únicos de cada campo e identificar valores inesperados.

### QUERY 3: Exportar para Excel
Execute a **Seção 6** para exportar os dados com classificação e comparar com sua planilha:
```sql
-- Exporta todos os campos com classificação SIM/NÃO para cada critério
-- Você pode aplicar as mesmas fórmulas do Excel e comparar
```

## 📝 Como Identificar o Problema

### PASSO 1: Execute esta query para ver os totais com diferentes lógicas
```sql
SELECT
  TO_CHAR(DATE_TRUNC('month', submitted_at), 'YYYY-MM') as mes,

  -- Lógica atual
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
  END) as sql_atual,

  -- Sem validar segmento e volume (só faturamento)
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
  END) as apenas_faturamento,

  -- NULL não é aceito
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
  END) as null_excluido

FROM yayforms_responses
WHERE DATE_TRUNC('month', submitted_at) IN ('2024-01-01', '2024-02-01', '2024-03-01')
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;
```

### PASSO 2: Compare com Excel
1. Exporte os dados brutos (Seção 6)
2. Aplique suas fórmulas do Excel
3. Identifique quais registros estão sendo classificados diferente

### PASSO 3: Ajuste a Query
Baseado na diferença encontrada, ajuste a lógica SQL para bater com o Excel.

## 🚨 Ação Recomendada

1. **Execute o arquivo `DIAGNOSTICO-DISCREPANCIA-MQL.sql`** completo
2. **Compare os resultados da Seção 5** (diferentes lógicas) com seus números do Excel
3. **Identifique qual lógica** mais se aproxima dos seus números
4. **Valide com alguns registros específicos** exportando para Excel (Seção 6)

## 💡 Hipótese Mais Provável

Baseado no padrão:
- Janeiro/Fevereiro: SQL conta MAIS (+16, +6)
- Março: SQL conta MENOS (-39)

**Suspeita**:
1. Pode haver uma mudança nos dados em Março (novos valores nos campos?)
2. Ou a planilha Excel tem uma fórmula diferente que foi alterada
3. Ou há um problema de timezone/data específico de Março

Execute as queries de diagnóstico e me envie os resultados para identificarmos exatamente onde está a diferença!