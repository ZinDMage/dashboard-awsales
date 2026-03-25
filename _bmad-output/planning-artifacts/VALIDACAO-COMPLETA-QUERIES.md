# Validação Completa das Queries SQL - Dashboard AwSales

## 🔍 PROBLEMAS IDENTIFICADOS E CORREÇÕES

### 1. MÉTRICAS DE VALOR (g)

#### ❌ PROBLEMA 1: Margem de Contribuição (linha 94)
**Erro**: Taxa de imposto está como 0.095 (9.5%) mas deveria ser 0.17 (17%)
```sql
-- INCORRETO (linha 94)
SUM(receita_gerada) - (SUM(receita_gerada) * 0.095) - SUM(CASE WHEN status = 'Churn' THEN receita_gerada ELSE 0 END)

-- CORRETO
SUM(receita_gerada) - (SUM(receita_gerada) * 0.17) - SUM(CASE WHEN status = 'Churn' THEN receita_gerada ELSE 0 END)
```

#### ⚠️ POSSÍVEL PROBLEMA 2: Churn na Margem
**Questão**: A query assume que existe um campo `status = 'Churn'` na tabela `sales`. Verificar se isso existe ou se churn vem de outra fonte.

#### ⚠️ POSSÍVEL PROBLEMA 3: Pipeline e Faturamento Projetado
**Questão**: Estão agrupando por `deal_created_at` mas pipeline geralmente é uma foto do momento atual, não histórica. Considerar usar data atual ou snapshot date.

### 2. MÉTRICAS DE VOLUME (n)

#### ❌ PROBLEMA 4: MQL (já corrigido)
**Status**: ✅ Já corrigido - operadores AND/OR estavam mal estruturados

#### ⚠️ POSSÍVEL PROBLEMA 5: SQL Custom Field
**Questão**: A query assume que o campo personalizado `2e17191cfb8e6f4a58359adc42a08965a068e8bc` com valor '75' identifica SQLs. Validar se:
1. Este é o campo correto
2. O valor '75' está correto
3. Não existem outros valores que também deveriam ser SQLs

### 3. ANÁLISE DETALHADA POR QUERY

## 📊 QUERIES DE VALORES

### g.rec - Receita por Mês de Fechamento
```sql
-- ✅ QUERY PARECE CORRETA
SELECT
  DATE_TRUNC('month', data_fechamento) as mes,
  SUM(receita_gerada) as receita_total
FROM sales
GROUP BY DATE_TRUNC('month', data_fechamento)
ORDER BY mes;
```
**Validação**: Simples e direta, sem problemas aparentes.

### g.rec (cohort) - Receita por Mês de Criação
```sql
-- ✅ QUERY CORRETA (já com double JOIN)
-- Possível melhoria: adicionar filtro de data para performance
```

### g.gAds - Gasto em Ads
```sql
-- ✅ QUERY PARECE CORRETA
-- Une dados de Meta, Google e LinkedIn
```
**Possível validação**: Verificar se existem outras fontes de ads (TikTok, etc)

### g.roi - ROI
```sql
-- ⚠️ POSSÍVEL PROBLEMA: ROI deveria ser (receita - gasto) / gasto, não receita / gasto
-- ROI atual mostra retorno total, não retorno sobre investimento
```

### g.mc - Margem de Contribuição
```sql
-- ❌ ERRO CONFIRMADO: Taxa de 0.095 deve ser 0.17
-- ⚠️ VERIFICAR: Campo status = 'Churn' existe?
```

### g.pipe - Pipeline
```sql
-- ⚠️ QUESTÃO: Pipeline agrupado por deal_created_at?
-- Pipeline geralmente é valor atual, não histórico
-- Considerar usar CURRENT_DATE ou snapshot
```

## 📊 QUERIES DE VOLUMES

### n.leads - Total de Leads
```sql
-- ✅ QUERY PARECE CORRETA
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as leads
FROM yayforms_responses
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;
```

### n.mql - MQLs
```sql
-- ✅ CORRIGIDO: Operadores AND agora estão corretos
-- Validar regras de negócio com stakeholders
```

### n.sql - SQLs
```sql
-- ⚠️ VALIDAR: Custom field e valor '75' estão corretos?
-- Considerar adicionar mais validações ou comentários
```

### n.rAg - Reuniões Agendadas
```sql
-- ⚠️ VALIDAR: Custom field '8eff24b00226da8dfb871caaf638b62af68bf16b'
-- Este campo realmente indica reunião agendada?
```

### n.rRe - Reuniões Realizadas
```sql
-- ⚠️ VALIDAR: Custom field 'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3' = '47'
-- Valor '47' está correto para reunião realizada?
```

## 📊 TAXAS DE CONVERSÃO

### p.ctr - CTR
```sql
-- ✅ QUERY PARECE CORRETA
-- União de Meta, Google e LinkedIn
```

### p.cr - Conversion Rate (leads/cliques)
```sql
-- ⚠️ POSSÍVEL PROBLEMA: Períodos podem não alinhar perfeitamente
-- Considerar usar LEFT JOIN em vez de subqueries
```

### p.qs - Qualified Sales (SQL/MQL)
```sql
-- ⚠️ DEPENDE: Se MQL está correto (já foi), esta métrica estará correta
```

## 📊 CUSTOS

### f.cac - CAC (Custo de Aquisição)
```sql
-- ⚠️ QUESTÃO: CAC calculado sobre MQLs ou sobre vendas?
-- Geralmente CAC = gasto / vendas (não MQLs)
```

### f.cpl - CPL (Custo por Lead)
```sql
-- ✅ QUERY PARECE CORRETA
-- gasto_ads / leads totais
```

## 📊 DELTAS (Velocidade)

### dt.ms - Delta MQL → SQL
```sql
-- ⚠️ COMPLEXO: Usa stage_transitions
-- Validar stage_ids: to_stage_id IN (19, 50)
```

### dt.sr - Delta SQL → Reunião
```sql
-- ⚠️ COMPLEXO: Validar stage_ids
-- to_stage_id IN (3, 45, 51, 27, 37)
```

### dt.rv - Delta Reunião → Venda
```sql
-- ✅ CORRIGIDO: Double JOIN implementado
-- ⚠️ VALIDAR: Conversão de string para date no custom field
```

## 🔧 CORREÇÕES NECESSÁRIAS

### CRÍTICAS (devem ser corrigidas):
1. **Margem de Contribuição**: Mudar 0.095 para 0.17 na linha 94
2. **ROI**: Considerar mudar fórmula para (receita - gasto) / gasto

### IMPORTANTES (validar com negócio):
1. Verificar se campo `status = 'Churn'` existe na tabela sales
2. Validar todos os custom fields IDs e valores
3. Confirmar se pipeline deve ser agrupado por deal_created_at
4. Confirmar se CAC deve usar MQLs ou vendas

### MELHORIAS:
1. Adicionar comentários com IDs dos custom fields
2. Criar constantes/views para custom fields
3. Adicionar validações de data para performance
4. Considerar criar CTEs reutilizáveis

## 📝 QUERIES DE VALIDAÇÃO

### Validar Custom Fields
```sql
-- Ver valores únicos do custom field de SQL
SELECT DISTINCT
  (CASE
    WHEN jsonb_typeof(custom_fields) = 'string'
    THEN (custom_fields #>> '{}')::jsonb
    ELSE custom_fields
  END)->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' as sql_value,
  COUNT(*) as quantidade
FROM crm_deals
WHERE custom_fields IS NOT NULL
GROUP BY 1
ORDER BY quantidade DESC;
```

### Validar se existe campo Churn
```sql
-- Verificar se existe status = 'Churn'
SELECT DISTINCT status, COUNT(*)
FROM sales
GROUP BY status
ORDER BY COUNT(*) DESC;
```

### Validar Stage IDs
```sql
-- Ver todos os stage_ids e suas quantidades
SELECT
  stage_id,
  pipeline_id,
  COUNT(*) as quantidade
FROM crm_deals
GROUP BY stage_id, pipeline_id
ORDER BY pipeline_id, stage_id;
```

## 📅 Data da Validação
2026-03-25