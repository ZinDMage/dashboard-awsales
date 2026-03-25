# ✅ Checklist de Auditoria - AwSales Dashboard

**Data:** 2026-03-25 18:00
**Objetivo:** Garantir que você tenha todos os recursos necessários para auditar os dados

---

## 📋 Documentos Disponíveis para Auditoria

### 1. QUERIES-SQL-AUDITORIA.md ✅
- **Localização:** `_bmad-output/planning-artifacts/QUERIES-SQL-AUDITORIA.md`
- **Conteúdo:** 1913 linhas com TODAS as queries SQL
- **Seções:**
  - ✅ Seção A: 7 métricas de valor/gasto (Receita, ROI, Pipeline, etc.)
  - ✅ Seção B: 9 métricas de volume (Impressões, Cliques, Leads, MQL, SQL, etc.)
  - ✅ Seção C: 9 métricas percentuais (CTR, Conversões, Show Up, etc.)
  - ✅ Seção D: 6 métricas de custo (CPL, CPM, CPS, CAC, etc.)
  - ✅ Seção E: 4 métricas de velocidade (Deltas entre etapas)
  - ✅ Seção F: Análises especiais e validação cruzada

### 2. DETALHAMENTO-CALCULOS.md ✅
- **Localização:** `_bmad-output/planning-artifacts/DETALHAMENTO-CALCULOS.md`
- **Conteúdo:** Explicação detalhada de CADA cálculo
- **Inclui:** Código JavaScript atual + SQL equivalente

### 3. DISCREPANCIAS-CRITICAS.md ✅
- **Localização:** `_bmad-output/planning-artifacts/DISCREPANCIAS-CRITICAS.md`
- **Conteúdo:** Problemas identificados e corrigidos
- **Status:** Stage IDs já foram corrigidos no código

### 4. RESULTADOS-VALIDACAO.md ✅
- **Localização:** `_bmad-output/planning-artifacts/RESULTADOS-VALIDACAO.md`
- **Conteúdo:** Mapeamento completo de stages e custom fields do Pipedrive

---

## 🔍 Como Usar as Queries para Auditoria

### Passo 1: Configurar Período
```sql
-- Ajuste estas datas em TODAS as queries
SET @start_date = '2026-03-01';
SET @end_date = '2026-03-31';
```

### Passo 2: Executar Queries de Validação
1. **Primeiro:** Execute as queries da Seção F (Validação Cruzada)
2. **Verifique:** Email matching, consistência de datas, duplicatas
3. **Documente:** Qualquer discrepância encontrada

### Passo 3: Auditar Cada Métrica
Para cada métrica do dashboard:
1. Encontre a query correspondente no documento
2. Execute a query no Supabase
3. Compare com o valor mostrado no dashboard
4. Documente diferenças

### Passo 4: Queries Especiais para Debug
Se encontrar discrepâncias, use as queries de debug:
- **Debug 1:** Verificar Custom Fields Raw
- **Debug 2:** Verificar Stage IDs Existentes
- **Debug 3:** Verificar Valores de Campos YayForms

---

## 📊 Métricas com Maior Risco de Discrepância

### ALTA PRIORIDADE 🔴
1. **SQL Count** - Depende do custom field '2e17191cfb8e6f4a58359adc42a08965a068e8bc'
2. **Reuniões Agendadas/Realizadas** - Dependem de custom fields
3. **Pipeline Total** - Atualmente só considera stage_id = 46
4. **Motivos de Perda** - Mapeamento por stage pode estar incompleto

### MÉDIA PRIORIDADE 🟡
1. **MQL** - Regras de qualificação complexas
2. **View Page** - Meta + Google podem ter definições diferentes
3. **Cliques** - Meta usa actions table, Google usa costs table
4. **Deltas de Velocidade** - Dependem de stage_transitions

### BAIXA PRIORIDADE 🟢
1. **Receita Gerada** - Direto da tabela sales
2. **Impressões** - Soma simples de 3 plataformas
3. **Leads** - Count direto de yayforms_responses
4. **Vendas** - Count direto de sales

---

## 🚨 Pontos de Atenção

### 1. Email Matching
- Usa `LOWER(TRIM())` mas ainda pode haver divergências
- Alguns emails podem estar diferentes entre sistemas

### 2. Datas Base
- Código JavaScript usa `leadDate || dealCreatedAt`
- SQL usa `COALESCE(yr.submitted_at, cd.deal_created_at)`
- Verifique se a lógica está correta

### 3. Custom Fields no Pipedrive
```javascript
// Valores corretos validados via API:
SQL_FLAG: {
  key: '2e17191cfb8e6f4a58359adc42a08965a068e8bc',
  values: { SIM: '75', NAO: '76', A_REVISAR: '79' }
}
DATA_REUNIAO: {
  key: '8eff24b00226da8dfb871caaf638b62af68bf16b'
}
REUNIAO_REALIZADA: {
  key: 'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3',
  values: { SIM: '47', NAO: '59' }
}
```

### 4. Stage IDs Corrigidos
```javascript
// ANTES (incorreto):
MQL: [1, 3, 49]  // Stage 3 é Reunião!
SQL: [4, 50]     // Stage 4 é Proposta!

// DEPOIS (correto):
MQL: [1, 49]
SQL: [19, 50]
REUNIAO_AGENDADA: [3, 45, 51, 27, 37]
PROPOSTA: [4, 46, 29, 39]
```

---

## 📝 Template de Relatório de Auditoria

```markdown
# Relatório de Auditoria - [MÉTRICA]

**Data da Auditoria:** [DATA]
**Período Analisado:** [INÍCIO] a [FIM]

## Valores Encontrados
- **Dashboard:** [VALOR]
- **SQL Query:** [VALOR]
- **Diferença:** [VALOR] ([%])

## Query Utilizada
[COLAR QUERY SQL]

## Análise da Discrepância
[EXPLICAR POSSÍVEL CAUSA]

## Recomendação
[SUGERIR CORREÇÃO]
```

---

## ✅ Confirmação Final

**VOCÊ TEM ACESSO A:**
1. ✅ Todas as 37 seções de queries SQL
2. ✅ Queries com e sem filtros
3. ✅ Queries de debug para troubleshooting
4. ✅ Validações cruzadas entre tabelas
5. ✅ Documentação completa dos cálculos
6. ✅ Mapeamento de stages e custom fields

**PRÓXIMOS PASSOS:**
1. Execute as queries no Supabase
2. Compare com os valores do dashboard
3. Documente discrepâncias encontradas
4. Me envie as queries que você usa para validar
5. Ajustaremos o código conforme necessário

---

**Documento criado para garantir sucesso na auditoria!** 🎯