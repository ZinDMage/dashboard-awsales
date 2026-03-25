# ⚠️ DISCREPÂNCIAS CRÍTICAS IDENTIFICADAS

**Data:** 2026-03-25 | **Atualização:** 2026-03-25 14:30
**Projeto:** AwSales Dashboard
**Análise:** DDL Real vs dataService.js

---

## 🎯 STATUS GERAL (Atualizado: 2026-03-25 15:15)

| Problema | Severidade | Status | Ação Necessária |
|----------|-----------|--------|-----------------|
| 1. Stage IDs Inconsistentes | 🔴 **CRÍTICO** | ✅ Validado | ⚠️ **CORRIGIR CÓDIGO** |
| 2. Campos sales divergentes | 🟢 Resolvido | ✅ DDL correto | N/A |
| 3. Custom Fields não documentados | 🟡 Médio | ✅ Validado | Refatorar código |
| 4. Lógica View Page diferente | 🟠 Alto | ✅ Decidido | Manter atual |
| 5. Função dashboard_data() não usada | 🟢 Resolvido | ✅ Não existe | N/A |
| 6. Regras MQL hardcoded | 🟡 Baixo | ⏳ Avaliar necessidade | Decisão produto |
| 7. Sales sem FK para CRM | 🟡 Médio | ⏳ Pendente decisão | Avaliar migração |

**🚨 ALERTA:** Problema 1 agora é **CRÍTICO**. Validação via API revelou que stage IDs no código estão **INCORRETOS**, causando contabilização errada de métricas (MQL, SQL, Reuniões).

---

## 🔴 PROBLEMA 1: Stage IDs Inconsistentes → ✅ **VALIDADO VIA API**

### Status: ⚠️ **CRÍTICO - CÓDIGO ESTÁ INCORRETO**

**Validado via Pipedrive API em 2026-03-25 15:00**

### Definição INCORRETA no `dataService.js` (linhas 269-278)

```javascript
// ❌ INCORRETO - Stage IDs não correspondem ao Pipedrive real
const STAGE_IDS = {
  MQL: [1, 3, 49],        // ❌ Stage 3 = "Reunião Ag." (não é MQL!)
  SQL: [4, 50],           // ❌ Stage 4 = "Proposta feita" (não é SQL!)
  REUNIAO: [6, 7, 45],    // ❌ Stage 6 = "Reagendamento", Stage 7 não existe
  NEGOCIACAO: [46],       // ✅ OK
  PROPOSTA: [47]          // ✅ OK (mas é "Contrato Enviado")
};
```

### Mapeamento CORRETO (Validado no Pipedrive)

```javascript
// ✅ CORRETO - Baseado em validação via Pipedrive API
const STAGE_IDS = {
  MQL: [1, 49],           // Pipeline 1 + Pipeline 9 (SDR)
  SQL: [19, 50],          // Pipeline 1 (stage 19) + Pipeline 9 (stage 50)
  REUNIAO_AGENDADA: [3, 45, 51, 27, 37],
  PROPOSTA: [4, 46, 29, 39],
  CONTRATO_ENVIADO: [41, 47, 43, 40],
  REAGENDAMENTO: [6, 48, 38, 57]
};
```

Ver [RESULTADOS-VALIDACAO.md](RESULTADOS-VALIDACAO.md) para mapeamento completo de todos os 44 stages em 10 pipelines.

### 🐛 Bugs Identificados:

1. **Stage 3 ≠ MQL**
   - Código assume: Stage 3 é MQL
   - Pipedrive real: Stage 3 = "🗓️ Reunião Ag." (Pipeline 1)
   - **Impacto:** Reuniões agendadas estão sendo contadas como MQL

2. **Stage 4 ≠ SQL**
   - Código assume: Stage 4 é SQL
   - Pipedrive real: Stage 4 = "🧾 Proposta feita" (Pipeline 1)
   - **Impacto:** Propostas estão sendo contadas como SQL

3. **Stage 6 ≠ Reunião**
   - Código assume: Stage 6 é Reunião
   - Pipedrive real: Stage 6 = "🚫 Reagendamento Pendente" (Pipeline 1)
   - **Impacto:** Reagendamentos estão sendo contados como reuniões

4. **Stage 7 não existe**
   - Código usa: Stage 7 em REUNIAO
   - Pipedrive real: Stage 7 não existe (ID obsoleto)
   - **Impacto:** Possível erro em queries

5. **Falta stage 19 em SQL**
   - Código: SQL = [4, 50]
   - Pipedrive real: Stage 19 = "👤 Lead Qualificado (SQL)" (Pipeline 1)
   - **Impacto:** SQLs do Pipeline 1 não estão sendo contabilizados

### 💡 Ação Requerida:

- [x] ~~Validar no Pipedrive quais são os stage_ids reais~~ → **CONCLUÍDO**
- [ ] **URGENTE: Corrigir dataService.js com stage IDs corretos**
- [ ] Rodar análise antes/depois para medir impacto nas métricas
- [ ] Criar testes automatizados para validar stage IDs

---

## ✅ ~~PROBLEMA 2: Campos de `sales` Divergentes~~ → **RESOLVIDO**

### Status: ✅ **DDL Simplificado Confirmado como Correto**

**Resolução:** Após releitura do DDL simplificado (414 linhas), confirmado que:
- O DDL de produção **NÃO contém** a função `dashboard_data()` problemática
- Os campos estão **CORRETOS** e alinhados com `dataService.js`
- A análise inicial estava baseada em versão antiga/deprecated do DDL

### Campos Validados ✅

```javascript
// dataService.js linha 65
fetchAll('sales', 'id, receita_gerada, data_fechamento, status, email_pipedrive, email_stripe')

// DDL (linhas 391-413)
CREATE TABLE public.sales (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  receita_gerada numeric DEFAULT 0,  -- ✅ CORRETO
  data_fechamento date,               -- ✅ CORRETO
  email_pipedrive text,               -- ✅ CORRETO
  email_stripe text                   -- ✅ CORRETO
);
```

### 📝 Nota Histórica:

A função SQL `dashboard_data()` que continha campos incorretos (`total_revenue`, `sale_date`, `crm_deal_id`) estava presente em um DDL exportado anterior (803 linhas) mas **NÃO existe** no DDL simplificado atual.

**Conclusão:** Não há discrepância. Sistema está consistente.

---

## ✅ ~~PROBLEMA 3: Custom Fields Não Documentados~~ → **RESOLVIDO**

### Status: ✅ **VALIDADO VIA API**

**Validado via Pipedrive API em 2026-03-25 15:00**

### Custom Fields Identificados

| Hash | Field ID | Nome | Tipo | Valores |
|------|----------|------|------|---------|
| `2e17191c...` | 80 | **SQL?** | enum | 75="Sim" ✅, 76="Não", 79="A revisar" |
| `8eff24b0...` | 46 | **Data Reunião** | date | YYYY-MM-DD |
| `baf2724f...` | 74 | **Reunião Realizada** | enum | 47="Sim" ✅, 59="Não" |

### Uso no `dataService.js` (linhas 283-304) - ✅ CORRETO

```javascript
const cj = parseCustomFields(d.custom_fields);

// ✅ Custom field 1: SQL? (Field ID: 80)
const isSQL = cj['2e17191cfb8e6f4a58359adc42a08965a068e8bc'] == '75'; // "Sim"

// ✅ Custom field 2: Data Reunião (Field ID: 46)
const agendamentoDate = cj['8eff24b00226da8dfb871caaf638b62af68bf16b'];

// ✅ Custom field 3: Reunião Realizada (Field ID: 74)
if (cj['baf2724fcbeec84a36e90f9dc3299431fe1b0dd3'] == '47') { // "Sim"
  // reunião realizada
}
```

**Conclusão:** Lógica está correta, mas código pode ser refatorado para melhor legibilidade.

### 💡 Recomendação de Refatoração:

- [x] ~~Documentar mapeamento hash → nome do campo no Pipedrive~~ → **CONCLUÍDO**
- [ ] **Opcional:** Adicionar constantes com nomes descritivos:

```javascript
const CUSTOM_FIELDS = {
  SQL_FLAG: {
    key: '2e17191cfb8e6f4a58359adc42a08965a068e8bc',
    name: 'SQL?',
    values: { SIM: '75', NAO: '76', A_REVISAR: '79' }
  },
  DATA_REUNIAO: {
    key: '8eff24b00226da8dfb871caaf638b62af68bf16b',
    name: 'Data Reunião'
  },
  REUNIAO_REALIZADA: {
    key: 'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3',
    name: 'Reunião Realizada',
    values: { SIM: '47', NAO: '59' }
  }
};

// Uso refatorado (mais legível)
const isSQL = cj[CUSTOM_FIELDS.SQL_FLAG.key] == CUSTOM_FIELDS.SQL_FLAG.values.SIM;
```

- [x] ~~Criar tabela de referência no PRD~~ → **CONCLUÍDO**

---

## ✅ ~~PROBLEMA 4: Lógica de View Page Diferente~~ → **RESOLVIDO**

### Status: ✅ **DECISÃO CONFIRMADA**

**Decidido em 2026-03-25: View Page = Meta Ads + Google Ads**

### Implementação Atual - ✅ CORRETA

```javascript
// dataService.js (linha 212) - Meta Ads
if (act.action_type === 'landing_page_view')
  updateMetrics(m, act, act.value, 'n', 'vp', wk);

// dataService.js (linha 230) - Google Ads
updateMetrics(m, gad, gad.conversions, 'n', 'vp', wk);
```

**Definição oficial:** View Page = Pessoas que clicaram no anúncio e **chegaram na landing page**

### Justificativa da Decisão:

✅ **Opção escolhida: Meta Ads `landing_page_view` + Google Ads `conversions`**

- Captura tráfego pago de múltiplas fontes (Meta + Google)
- Mede pessoas que chegaram na landing page após clicar no anúncio
- Alinhado com funil de marketing digital padrão
- Permite calcular Connect Rate = View Page / Cliques

❌ **Opção rejeitada: YayForms `started_at`**

- Não inclui pessoas que visualizaram a página mas não iniciaram o formulário
- Subestima o tráfego real
- Melhor usar como métrica separada: "Formulários Iniciados"

### Métricas Impactadas:

1. **View Page** (métrica direta)
2. **Connect Rate** = View Page / Cliques
3. **Conversão Página Captura** = Leads / View Page

**Conclusão:** Implementação atual está correta. Não requer mudanças.

---

## ✅ ~~PROBLEMA 5: Função `dashboard_data()` Não é Usada~~ → **RESOLVIDO**

### Status: ✅ **Função Não Existe no DDL de Produção**

**Resolução:** Após releitura do DDL simplificado (414 linhas), confirmado que:
- A função `dashboard_data()` **NÃO existe** no DDL de produção atual
- Estava presente apenas em versão exportada anterior (803 linhas)
- Sistema usa exclusivamente aggregação no frontend via `dataService.js`

### Arquitetura Atual (Validada) ✅

```
┌─────────────────┐
│  React Frontend │
│   (awsales_v6)  │
└────────┬────────┘
         │
         │ fetchMonthlyMetrics()
         ▼
┌─────────────────┐
│  dataService.js │ ← Aggregação aqui (JavaScript)
└────────┬────────┘
         │
         │ fetchAll() - queries individuais
         ▼
┌─────────────────┐
│ Supabase Tables │ ← 16 tabelas sem funções de agregação
└─────────────────┘
```

### 📝 Decisão de Arquitetura Confirmada:

- ✅ **Frontend Aggregation** é a abordagem oficial
- ✅ Não há funções SQL de agregação em produção
- ✅ Toda lógica de negócio está em `dataService.js`

**Conclusão:** Não há discrepância. Arquitetura é intencional e consistente.

---

## 🟡 PROBLEMA 6: Regras MQL Hardcoded vs Configuráveis

### Atual (dataService.js linhas 8-42):

```javascript
const disqualifiedRanges = [
  'Zero até o momento',
  'Menos de R$100 mil',
  // ... hardcoded
];
```

### ❓ Questões:

1. **Quem pode alterar as regras de qualificação?**
   - Apenas dev via código
   - Head de Marketing não tem autonomia

2. **Mudanças frequentes nas regras?**
   - Se sim: criar UI de configuração
   - Se não: manter hardcoded

### 💡 Recomendação:

- [ ] Mover regras para tabela `app_config`
- [ ] Criar interface de admin para ajustar regras
- [ ] OU manter hardcoded se regras são estáveis

---

## 🟡 PROBLEMA 7: Tabela `sales` Sem FK para CRM

### Atual:

```sql
-- sales table (DDL linha 391-413)
CREATE TABLE public.sales (
  email_stripe text,
  email_pipedrive text,
  -- ... SEM crm_deal_id
);
```

### Impacto:

- Cálculo de deltas (Lead → Venda) usa email matching
- Frágil: emails podem divergir
- Sem garantia de integridade referencial

### 💡 Recomendação:

- [ ] Adicionar campo `crm_deal_id integer` à tabela `sales`
- [ ] Criar FK: `sales.crm_deal_id` → `crm_deals.deal_id`
- [ ] Atualizar n8n para popular esse campo

---

## 📋 CHECKLIST DE AÇÕES PRIORITÁRIAS (ATUALIZADO)

### ✅ Resolvido:

- [x] ~~**Corrigir função SQL `dashboard_data()`**~~ → Função não existe em produção
- [x] ~~**Validar campos de sales**~~ → DDL está correto

### 🟠 Alto (Inconsistência de dados):

- [ ] **Validar stage_ids no Pipedrive:**
  - Acessar Pipedrive → Settings → Pipelines → Sales Pipeline
  - Documentar mapping real de stage_id → stage_name
  - Confirmar se dataService.js está usando IDs corretos

- [ ] **Decidir lógica de View Page:**
  - Decisão de negócio: Meta Ads landing_page_view OU YayForms started_at
  - Validar com Head de Marketing qual métrica faz mais sentido
  - Padronizar nomenclatura se necessário

### 🟡 Médio (Manutenibilidade):

- [ ] **Documentar custom fields do Pipedrive:**
  - Acessar Pipedrive → Settings → Data fields → Deal custom fields
  - Mapear os 3 hashes usados em dataService.js:
    - `2e17191c...` (SQL flag = '75')
    - `8eff24b0...` (Data agendamento)
    - `baf2724f...` (Reunião realizada = '47')
  - Criar constantes com nomes descritivos no código
  - Adicionar tabela de referência no PRD

- [ ] **Adicionar FK sales → crm_deals (opcional):**
  - Avaliar necessidade vs esforço de migração
  - Se implementar: migração de schema + atualizar n8n
  - Alternativa: manter email matching mas documentar limitação

### 🟢 Baixo (Nice to have):

- [ ] **Regras MQL configuráveis:**
  - Avaliar com Head de Marketing se regras mudam frequentemente
  - Se sim: mover para `app_config` + criar UI de admin
  - Se não: manter hardcoded mas documentar no PRD

---

## 📞 PRÓXIMOS PASSOS

### Fase 1: Validação (1-2 dias)
1. **Acessar Pipedrive** e coletar informações:
   - Stage IDs reais do pipeline atual
   - Nomes dos 3 custom fields usados no código

2. **Reunião com Head de Marketing** para decidir:
   - Definição oficial de "View Page"
   - Frequência de mudanças nas regras MQL

### Fase 2: Documentação (1 dia)
3. **Atualizar PRD** com informações validadas
4. **Atualizar este relatório** marcando itens como resolvidos
5. **Criar guia de referência** para custom fields

### Fase 3: Refatoração (opcional, 2-3 dias)
6. **Criar constantes** para custom fields no dataService.js
7. **Adicionar comentários** explicativos no código
8. **Avaliar migração** para FK em sales (se necessário)

---

## 📊 RESUMO EXECUTIVO (Atualizado: 2026-03-25 15:15)

**Status Atual:** 4/7 validações concluídas ✅

**Problemas Resolvidos:** 4 (Campos sales, Custom Fields, View Page, Função dashboard_data)

**Problemas Críticos Identificados:** 1 🔴 **STAGE IDS INCORRETOS NO CÓDIGO**

**Validações Pendentes:** 0 🎉

**Decisões de Negócio Pendentes:** 2 (Regras MQL configuráveis + FK sales→crm_deals)

**Tempo Estimado para Correção:** 1-2 dias úteis (correção de Stage IDs)

---

**Responsável:** Desenvolvedor + Head Marketing/Comercial
**Última Atualização:** 2026-03-25 14:30
