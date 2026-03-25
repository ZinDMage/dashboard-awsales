# 📊 Detalhamento Completo dos Cálculos - AwSales Dashboard

**Data:** 2026-03-25 16:30
**Arquivo Fonte:** `Dash AwSales/dataService.js`
**Objetivo:** Documentar como cada métrica é calculada para validação e ajuste

---

## 📋 Índice

1. [Métricas de Gasto (g)](#métricas-de-gasto-g)
2. [Métricas de Número/Contagem (n)](#métricas-de-númerocontagem-n)
3. [Métricas Percentuais (p)](#métricas-percentuais-p)
4. [Métricas de Custo por Etapa (f)](#métricas-de-custo-por-etapa-f)
5. [Métricas de Delta/Velocidade (dt)](#métricas-de-deltavelocidade-dt)
6. [Motivos de Perda](#motivos-de-perda)

---

## 📊 Estrutura de Dados

```javascript
const initMetrics = () => ({
  g: {   // Gastos/Valores
    rec: 0,      // Receita Gerada
    gAds: 0,     // Gasto em Ads
    roi: 0,      // ROI
    mc: 0,       // Margem de Contribuição
    pipe: 0,     // Pipeline Total
    fatP: 0,     // Faturamento Projetado
    recP: 0,     // Receita Projetada
    vendas: 0,   // [não usado]
    tmf: 0       // [não usado]
  },
  n: {   // Números/Contagens
    imp: 0,      // Impressões
    cli: 0,      // Cliques
    vp: 0,       // View Page
    ld: 0,       // Leads
    mql: 0,      // MQL
    sql: 0,      // SQL
    rAg: 0,      // Reuniões Agendadas
    rRe: 0,      // Reuniões Realizadas
    v: 0         // Vendas
  },
  p: {   // Percentuais
    ctr: 0,      // CTR
    cr: 0,       // Connect Rate
    cc: 0,       // Conversão Captura
    qm: 0,       // Qualified Marketing
    qs: 0,       // Qualified Sales
    ag: 0,       // Agendamento
    su: 0,       // Show Up
    fc: 0,       // Fechamento Call
    fs: 0        // Fechamento SQL
  },
  f: {   // Custos
    gAds: 0,     // [duplicado de g.gAds]
    cpL: 0,      // Custo por Lead
    cpM: 0,      // Custo por MQL
    cpS: 0,      // Custo por SQL
    cpRA: 0,     // Custo por Reunião Agendada
    cpRR: 0,     // Custo por Reunião Realizada
    cpV: 0       // Custo por Venda
  },
  dt: {  // Deltas/Tempo médio
    ms: 0,       // MQL → SQL (dias)
    sr: 0,       // SQL → Reunião (dias)
    rv: 0,       // Reunião → Venda (dias)
    lv: 0        // Lead → Venda (dias)
  },
  perdas: {
    mql: [],     // Array de motivos de perda MQL
    sql: [],     // Array de motivos de perda SQL
    proposta: [] // Array de motivos de perda Proposta
  }
});
```

---

## 1. Métricas de Gasto (g)

### 💰 g.rec - Receita Gerada

**Fonte de Dados:** `sales` table

**Cálculo Atual (dataService.js linhas 183-189):**
```javascript
if (sales) {
  sales.forEach(s => {
    const mk = getMonthKey(s.data_fechamento);
    const wk = getWeekKey(s.data_fechamento);
    if (!mk) return;
    const m = initMonth(mk);

    updateMetrics(m, s, s.receita_gerada, 'g', 'rec', wk);
    // ...
  });
}
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', data_fechamento) as mes,
  SUM(receita_gerada) as receita_total
FROM sales
WHERE data_fechamento IS NOT NULL
GROUP BY DATE_TRUNC('month', data_fechamento)
ORDER BY mes;
```

**Regra:**
- ✅ Soma `receita_gerada` de todos os registros de `sales`
- ✅ Agrupa por mês da `data_fechamento`
- ❓ **Não filtra por status** (inclui Churn?)

---

### 💰 g.gAds - Gasto em Ads

**Fonte de Dados:** `meta_ads_costs`, `google_ads_costs`, `linkedin_ads_costs`

**Cálculo Atual (dataService.js linhas 191-213):**
```javascript
// Meta Ads
if (metaCosts) {
  metaCosts.forEach(mc => {
    const mk = getMonthKey(mc.date_start);
    const wk = getWeekKey(mc.date_start);
    if (!mk) return;
    const m = initMonth(mk);

    updateMetrics(m, mc, mc.spend, 'f', 'gAds', wk);  // ❓ tipo 'f' mas deveria ser 'g'
  });
}

// Google Ads
if (googleCosts) {
  googleCosts.forEach(gc => {
    // ... mesmo padrão
    updateMetrics(m, gc, gc.spend, 'f', 'gAds', wk);
  });
}

// LinkedIn Ads (mesmo padrão)
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', date_start) as mes,
  SUM(spend) as gasto_total
FROM (
  SELECT date_start, spend FROM meta_ads_costs
  UNION ALL
  SELECT date, spend FROM google_ads_costs
  UNION ALL
  SELECT date, spend FROM linkedin_ads_costs
) combined
GROUP BY DATE_TRUNC('month', date_start)
ORDER BY mes;
```

**Regra:**
- ✅ Soma `spend` de Meta Ads + Google Ads + LinkedIn Ads
- ✅ Agrupa por mês da `date_start` (ou `date`)

---

### 💰 g.roi - ROI

**Cálculo Atual (dataService.js linha 439):**
```javascript
g.roi = calcP(g.rec, f.gAds);

// calcP = (a, b) => b === 0 ? 0 : (a / b) * 100
```

**Fórmula:**
```
ROI = (Receita Gerada / Gasto em Ads) * 100
```

**Exemplo:**
- Receita: R$ 100.000
- Gasto: R$ 10.000
- ROI: (100.000 / 10.000) * 100 = **1000%**

❓ **Questão:** ROI tradicional seria `((Receita - Gasto) / Gasto) * 100`?

---

### 💰 g.mc - Margem de Contribuição

**Cálculo Atual (dataService.js linhas 448-449):**
```javascript
const churnValue = m._churnTemp || 0;
g.mc = g.rec - (g.rec * 0.17) - churnValue;
```

**Fórmula:**
```
MC = Receita - (Receita × 17%) - Churn
```

**Componentes:**
- **Receita:** Soma de `receita_gerada`
- **17%:** Imposto fixo
- **Churn:** Soma de `receita_gerada` WHERE `status = 'Churn'`

**Cálculo do Churn (linhas 184-188):**
```javascript
if (s.status?.toLowerCase() === 'churn') {
  m._churnTemp = (m._churnTemp || 0) + (s.receita_gerada || 0);
  if (wk && m.wk[wk]) {
    m.wk[wk]._churnTemp = (m.wk[wk]._churnTemp || 0) + (s.receita_gerada || 0);
  }
}
```

---

### 💰 g.pipe - Pipeline Total

**Fonte de Dados:** `crm_deals`

**Cálculo Atual (dataService.js linhas 334-337):**
```javascript
// Pipeline Total: Sum(crm_deals.value) WHERE stage_id IN PIPELINE_TOTAL
if (STAGE_IDS.PIPELINE_TOTAL.includes(d.stage_id)) {
  updateMetrics(m, d, d.value, 'g', 'pipe', wk);
}
```

**STAGE_IDS.PIPELINE_TOTAL:**
```javascript
PIPELINE_TOTAL: [46]  // Pipeline 8 (Inbound Closer) - "🧾 Proposta feita"
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', deal_created_at) as mes,
  SUM(value) as pipeline_total
FROM crm_deals
WHERE stage_id = 46
  AND status = 'open'  -- ❓ Código não filtra por status
GROUP BY DATE_TRUNC('month', deal_created_at)
ORDER BY mes;
```

❓ **Questões:**
- Deveria filtrar `status = 'open'`?
- Stage 46 é o único? E outros pipelines?

---

### 💰 g.fatP - Faturamento Projetado

**Cálculo Atual (dataService.js linha 440):**
```javascript
g.fatP = g.pipe * 0.20;
```

**Fórmula:**
```
Faturamento Projetado = Pipeline Total × 20%
```

---

### 💰 g.recP - Receita Projetada

**Cálculo Atual (dataService.js linha 441):**
```javascript
g.recP = g.rec + g.fatP;
```

**Fórmula:**
```
Receita Projetada = Receita Gerada + Faturamento Projetado
```

---

## 2. Métricas de Número/Contagem (n)

### 🔢 n.imp - Impressões

**Fonte de Dados:** `meta_ads_costs`, `google_ads_costs`, `linkedin_ads_costs`

**Cálculo Atual (dataService.js linhas 191-213):**
```javascript
// Meta Ads
updateMetrics(m, mc, mc.impressions, 'n', 'imp', wk);

// Google Ads
updateMetrics(m, gc, gc.impressions, 'n', 'imp', wk);

// LinkedIn Ads
updateMetrics(m, lc, lc.impressions, 'n', 'imp', wk);
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', date_start) as mes,
  SUM(impressions) as total_impressoes
FROM (
  SELECT date_start, impressions FROM meta_ads_costs
  UNION ALL
  SELECT date, impressions FROM google_ads_costs
  UNION ALL
  SELECT date, impressions FROM linkedin_ads_costs
) combined
GROUP BY DATE_TRUNC('month', date_start);
```

---

### 🔢 n.cli - Cliques

**Fonte de Dados:** `meta_ads_actions`, `google_ads_costs`, `linkedin_ads_costs`

**Cálculo Atual (dataService.js linhas 215-238):**
```javascript
// Meta Ads Actions
if (metaActions) {
  metaActions.forEach(act => {
    // ...
    if (act.action_type === 'unique_outbound_outbound_click') {
      updateMetrics(m, act, act.value, 'n', 'cli', wk);
    }
  });
}

// Google Ads Costs
updateMetrics(m, gad, gad.clicks, 'n', 'cli', wk);

// LinkedIn Ads
updateMetrics(m, lad, lad.clicks, 'n', 'cli', wk);
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', date_start) as mes,
  SUM(cliques) as total_cliques
FROM (
  -- Meta Ads (de actions)
  SELECT date_start, value as cliques
  FROM meta_ads_actions
  WHERE action_type = 'unique_outbound_outbound_click'

  UNION ALL

  -- Google Ads
  SELECT date, clicks as cliques
  FROM google_ads_costs

  UNION ALL

  -- LinkedIn Ads
  SELECT date, clicks as cliques
  FROM linkedin_ads_costs
) combined
GROUP BY DATE_TRUNC('month', date_start);
```

---

### 🔢 n.vp - View Page

**Fonte de Dados:** `meta_ads_actions`, `google_ads_costs`

**Cálculo Atual (dataService.js linhas 215-238):**
```javascript
// Meta Ads Actions
if (act.action_type === 'landing_page_view') {
  updateMetrics(m, act, act.value, 'n', 'vp', wk);
}

// Google Ads - Conversions são View Page
updateMetrics(m, gad, gad.conversions, 'n', 'vp', wk);
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', date_start) as mes,
  SUM(view_pages) as total_view_page
FROM (
  -- Meta Ads
  SELECT date_start, value as view_pages
  FROM meta_ads_actions
  WHERE action_type = 'landing_page_view'

  UNION ALL

  -- Google Ads
  SELECT date, conversions as view_pages
  FROM google_ads_costs
) combined
GROUP BY DATE_TRUNC('month', date_start);
```

❓ **Questão:** LinkedIn Ads não tem View Page?

---

### 🔢 n.ld - Leads

**Fonte de Dados:** `yayforms_responses`

**Cálculo Atual (dataService.js linhas 220-244):**
```javascript
if (leads) {
  leads.forEach(l => {
    const mk = getMonthKey(l.submitted_at);
    const wk = getWeekKey(l.submitted_at);
    if (!mk) return;
    const m = initMonth(mk);

    updateMetrics(m, l, 1, 'n', 'ld', wk);  // Conta 1 por registro

    // ... classificação MQL é feita depois
  });
}
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as total_leads
FROM yayforms_responses
WHERE submitted_at IS NOT NULL
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;
```

**Regra:**
- ✅ Conta TODOS os registros de `yayforms_responses`
- ✅ Agrupa por mês de `submitted_at`

---

### 🔢 n.mql - MQL (Marketing Qualified Lead)

**Fonte de Dados:** `yayforms_responses`

**Cálculo Atual (dataService.js linhas 220-244):**
```javascript
const classification = classifyLead(
  l.lead_revenue_range,
  l.lead_monthly_volume,
  l.lead_segment
);

if (classification === 'MQL') {
  updateMetrics(m, l, 1, 'n', 'mql', wk);
}
```

**Função classifyLead (linhas 36-42):**
```javascript
function classifyLead(fat, vol, seg) {
  // DESQUALIFICADO se:
  if (disqualifiedRanges.includes(fat)) return 'Lead';
  if (seg && disqualifiedSegments.includes(seg)) return 'Lead';
  if (vol && disqualifiedTicketVolumes.includes(vol)) return 'Lead';

  // QUALIFICADO se:
  if (qualifiedRanges.includes(fat)) return 'MQL';

  return 'Lead';
}
```

**Regras de Desqualificação:**
```javascript
// Faturamento anual
disqualifiedRanges = [
  'Zero até o momento',
  'Menos de R$100 mil',
  'Entre R$100 mil e R$500 mil',
  'Entre R$500 mil e R$1 milhão'
];

// Volume de tickets
disqualifiedTicketVolumes = [
  'Menos de 1.000 por mês',
  'Entre 1.000 e 3.000 por mês',
  'Entre 1.000 e 5.000 por mês'
];

// Segmentos
disqualifiedSegments = [
  '🩺 Clínica / consultório',
  '⚖️ Escritório de advocacia'
];
```

**Regras de Qualificação:**
```javascript
qualifiedRanges = [
  'Entre R$1 milhão a R$5 milhões',
  'Entre R$5 milhões a R$10 milhões',
  'Entre R$10 milhões a R$25 milhões',
  'Entre R$25 milhões a R$50 milhões',
  'Acima de R$50 milhões',
  'Acima de R$10 milhões'
];
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', submitted_at) as mes,
  COUNT(*) as total_mql
FROM yayforms_responses
WHERE submitted_at IS NOT NULL
  -- Qualificado por faturamento
  AND lead_revenue_range IN (
    'Entre R$1 milhão a R$5 milhões',
    'Entre R$5 milhões a R$10 milhões',
    'Entre R$10 milhões a R$25 milhões',
    'Entre R$25 milhões a R$50 milhões',
    'Acima de R$50 milhões',
    'Acima de R$10 milhões'
  )
  -- E NÃO desqualificado por segmento
  AND (lead_segment IS NULL OR lead_segment NOT IN (
    '🩺 Clínica / consultório',
    '⚖️ Escritório de advocacia'
  ))
  -- E NÃO desqualificado por volume
  AND (lead_monthly_volume IS NULL OR lead_monthly_volume NOT IN (
    'Menos de 1.000 por mês',
    'Entre 1.000 e 3.000 por mês',
    'Entre 1.000 e 5.000 por mês'
  ))
GROUP BY DATE_TRUNC('month', submitted_at)
ORDER BY mes;
```

---

### 🔢 n.sql - SQL (Sales Qualified Lead)

**Fonte de Dados:** `crm_deals` (via custom field)

**Cálculo Atual (dataService.js linhas 358-373):**
```javascript
const cj = parseCustomFields(d.custom_fields);

// Verifica se deal está marcado como SQL no custom field "SQL?"
const isSQL = cj[CUSTOM_FIELDS.SQL_FLAG.key] == CUSTOM_FIELDS.SQL_FLAG.values.SIM;

if (isSQL) {
  // Usa data do lead (se houver) ou data de criação do deal
  const dealEmail = d.person_email?.toLowerCase().trim();
  const leadDate = dealEmail ? leadDateByEmail[dealEmail] : null;
  const sqlDate = leadDate || d.deal_created_at;

  const sqlMk = getMonthKey(sqlDate);
  const sqlWk = getWeekKey(sqlDate);
  if (!sqlMk) return;
  const sqlM = initMonth(sqlMk);

  updateMetrics(sqlM, d, 1, 'n', 'sql', sqlWk);
}
```

**Custom Field SQL:**
```javascript
CUSTOM_FIELDS.SQL_FLAG = {
  key: '2e17191cfb8e6f4a58359adc42a08965a068e8bc',
  values: {
    SIM: '75',    // "Sim"
    NAO: '76',    // "Não"
    A_REVISAR: '79'
  }
};
```

**Query SQL Equivalente:**
```sql
WITH sql_deals AS (
  SELECT
    cd.deal_id,
    cd.deal_created_at,
    cd.person_email,
    cd.custom_fields,
    -- Extrai valor do custom field SQL
    CASE
      WHEN cd.custom_fields::jsonb->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
      THEN true
      ELSE false
    END as is_sql,
    -- Busca data do lead por email
    yr.submitted_at as lead_date
  FROM crm_deals cd
  LEFT JOIN yayforms_responses yr
    ON LOWER(TRIM(cd.person_email)) = LOWER(TRIM(yr.lead_email))
)
SELECT
  DATE_TRUNC('month', COALESCE(lead_date, deal_created_at)) as mes,
  COUNT(*) as total_sql
FROM sql_deals
WHERE is_sql = true
GROUP BY DATE_TRUNC('month', COALESCE(lead_date, deal_created_at))
ORDER BY mes;
```

**Regras:**
- ✅ Custom field `SQL?` = "75" (Sim)
- ✅ Data base: `submitted_at` do lead (via email matching) OU `deal_created_at`
- ❓ Não filtra por `status` ou `stage_id`

---

### 🔢 n.rAg - Reuniões Agendadas

**Fonte de Dados:** `crm_deals` (via custom field)

**Cálculo Atual (dataService.js linhas 375-379):**
```javascript
// Dentro do bloco isSQL === true

// Reunião agendada: verifica se campo "Data Reunião" está preenchido
const agendamentoDate = cj[CUSTOM_FIELDS.DATA_REUNIAO.key];
if (agendamentoDate && agendamentoDate !== '') {
  updateMetrics(sqlM, d, 1, 'n', 'rAg', sqlWk);
}
```

**Custom Field Data Reunião:**
```javascript
CUSTOM_FIELDS.DATA_REUNIAO = {
  key: '8eff24b00226da8dfb871caaf638b62af68bf16b',
  // Tipo: date (YYYY-MM-DD)
};
```

**Query SQL Equivalente:**
```sql
WITH sql_deals AS (
  SELECT
    cd.deal_id,
    cd.deal_created_at,
    cd.person_email,
    cd.custom_fields,
    CASE
      WHEN cd.custom_fields::jsonb->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
      THEN true
      ELSE false
    END as is_sql,
    cd.custom_fields::jsonb->>'8eff24b00226da8dfb871caaf638b62af68bf16b' as data_reuniao,
    yr.submitted_at as lead_date
  FROM crm_deals cd
  LEFT JOIN yayforms_responses yr
    ON LOWER(TRIM(cd.person_email)) = LOWER(TRIM(yr.lead_email))
)
SELECT
  DATE_TRUNC('month', COALESCE(lead_date, deal_created_at)) as mes,
  COUNT(*) as total_reunioes_agendadas
FROM sql_deals
WHERE is_sql = true
  AND data_reuniao IS NOT NULL
  AND data_reuniao != ''
GROUP BY DATE_TRUNC('month', COALESCE(lead_date, deal_created_at))
ORDER BY mes;
```

**Regras:**
- ✅ Apenas deals com `SQL?` = "Sim"
- ✅ Campo `Data Reunião` preenchido (não vazio)
- ✅ Data base: data do lead OU deal_created_at

---

### 🔢 n.rRe - Reuniões Realizadas

**Fonte de Dados:** `crm_deals` (via custom field)

**Cálculo Atual (dataService.js linhas 381-385):**
```javascript
// Dentro do bloco isSQL === true

// Reunião realizada: verifica se campo "Reunião Realizada" = "Sim"
const reuniaoRealizada = cj[CUSTOM_FIELDS.REUNIAO_REALIZADA.key] == CUSTOM_FIELDS.REUNIAO_REALIZADA.values.SIM;
if (reuniaoRealizada) {
  updateMetrics(sqlM, d, 1, 'n', 'rRe', sqlWk);
}
```

**Custom Field Reunião Realizada:**
```javascript
CUSTOM_FIELDS.REUNIAO_REALIZADA = {
  key: 'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3',
  values: {
    SIM: '47',  // "Sim"
    NAO: '59'   // "Não"
  }
};
```

**Query SQL Equivalente:**
```sql
WITH sql_deals AS (
  SELECT
    cd.deal_id,
    cd.deal_created_at,
    cd.person_email,
    cd.custom_fields,
    CASE
      WHEN cd.custom_fields::jsonb->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'
      THEN true
      ELSE false
    END as is_sql,
    cd.custom_fields::jsonb->>'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3' as reuniao_realizada,
    yr.submitted_at as lead_date
  FROM crm_deals cd
  LEFT JOIN yayforms_responses yr
    ON LOWER(TRIM(cd.person_email)) = LOWER(TRIM(yr.lead_email))
)
SELECT
  DATE_TRUNC('month', COALESCE(lead_date, deal_created_at)) as mes,
  COUNT(*) as total_reunioes_realizadas
FROM sql_deals
WHERE is_sql = true
  AND reuniao_realizada = '47'  -- "Sim"
GROUP BY DATE_TRUNC('month', COALESCE(lead_date, deal_created_at))
ORDER BY mes;
```

**Regras:**
- ✅ Apenas deals com `SQL?` = "Sim"
- ✅ Campo `Reunião Realizada` = "47" (Sim)
- ✅ Data base: data do lead OU deal_created_at

---

### 🔢 n.v - Vendas

**Fonte de Dados:** `sales`

**Cálculo Atual (dataService.js linhas 183-189):**
```javascript
if (sales) {
  sales.forEach(s => {
    const mk = getMonthKey(s.data_fechamento);
    const wk = getWeekKey(s.data_fechamento);
    if (!mk) return;
    const m = initMonth(mk);

    updateMetrics(m, s, 1, 'n', 'v', wk);  // Conta 1 por venda
    // ...
  });
}
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', data_fechamento) as mes,
  COUNT(*) as total_vendas
FROM sales
WHERE data_fechamento IS NOT NULL
GROUP BY DATE_TRUNC('month', data_fechamento)
ORDER BY mes;
```

**Regra:**
- ✅ Conta TODOS os registros de `sales`
- ✅ Agrupa por mês de `data_fechamento`
- ❓ Não filtra por `status` (inclui Churn?)

---

## 3. Métricas Percentuais (p)

Todas calculadas na função `finalize()` (linhas 436-446)

### 📊 p.ctr - CTR (Click-Through Rate)

**Fórmula:**
```javascript
p.ctr = calcP(n.cli, n.imp);
// = (Cliques / Impressões) * 100
```

**Exemplo:**
- Impressões: 100.000
- Cliques: 2.000
- CTR: (2.000 / 100.000) * 100 = **2%**

---

### 📊 p.cr - Connect Rate

**Fórmula:**
```javascript
p.cr = calcP(n.vp, n.cli);
// = (View Page / Cliques) * 100
```

**Exemplo:**
- Cliques: 2.000
- View Page: 1.800
- CR: (1.800 / 2.000) * 100 = **90%**

---

### 📊 p.cc - Conversão Captura

**Fórmula:**
```javascript
p.cc = calcP(n.ld, n.vp);
// = (Leads / View Page) * 100
```

**Exemplo:**
- View Page: 1.800
- Leads: 900
- CC: (900 / 1.800) * 100 = **50%**

---

### 📊 p.qm - Qualified Marketing (Lead → MQL)

**Fórmula:**
```javascript
p.qm = calcP(n.mql, n.ld);
// = (MQL / Leads) * 100
```

**Exemplo:**
- Leads: 900
- MQL: 450
- QM: (450 / 900) * 100 = **50%**

---

### 📊 p.qs - Qualified Sales (MQL → SQL)

**Fórmula:**
```javascript
p.qs = calcP(n.sql, n.mql);
// = (SQL / MQL) * 100
```

**Exemplo:**
- MQL: 450
- SQL: 90
- QS: (90 / 450) * 100 = **20%**

---

### 📊 p.ag - Agendamento (SQL → Reunião Agendada)

**Fórmula:**
```javascript
p.ag = calcP(n.rAg, n.sql);
// = (Reuniões Agendadas / SQL) * 100
```

**Exemplo:**
- SQL: 90
- Reuniões Agendadas: 72
- AG: (72 / 90) * 100 = **80%**

---

### 📊 p.su - Show Up (Reunião Agendada → Realizada)

**Fórmula:**
```javascript
p.su = calcP(n.rRe, n.rAg);
// = (Reuniões Realizadas / Reuniões Agendadas) * 100
```

**Exemplo:**
- Reuniões Agendadas: 72
- Reuniões Realizadas: 54
- SU: (54 / 72) * 100 = **75%**

---

### 📊 p.fc - Fechamento Call (Reunião Realizada → Venda)

**Fórmula:**
```javascript
p.fc = calcP(n.v, n.rRe);
// = (Vendas / Reuniões Realizadas) * 100
```

**Exemplo:**
- Reuniões Realizadas: 54
- Vendas: 18
- FC: (18 / 54) * 100 = **33%**

---

### 📊 p.fs - Fechamento SQL (SQL → Venda)

**Fórmula:**
```javascript
p.fs = calcP(n.v, n.sql);
// = (Vendas / SQL) * 100
```

**Exemplo:**
- SQL: 90
- Vendas: 18
- FS: (18 / 90) * 100 = **20%**

---

## 4. Métricas de Custo por Etapa (f)

Todas calculadas na função `finalize()` (linhas 448-453)

### 💵 f.cpL - Custo por Lead

**Fórmula:**
```javascript
f.cpL = calcP(f.gAds, n.ld);
// = Gasto em Ads / Leads
```

---

### 💵 f.cpM - Custo por MQL

**Fórmula:**
```javascript
f.cpM = calcP(f.gAds, n.mql);
// = Gasto em Ads / MQL
```

---

### 💵 f.cpS - Custo por SQL

**Fórmula:**
```javascript
f.cpS = calcP(f.gAds, n.sql);
// = Gasto em Ads / SQL
```

---

### 💵 f.cpRA - Custo por Reunião Agendada

**Fórmula:**
```javascript
f.cpRA = calcP(f.gAds, n.rAg);
// = Gasto em Ads / Reuniões Agendadas
```

---

### 💵 f.cpRR - Custo por Reunião Realizada

**Fórmula:**
```javascript
f.cpRR = calcP(f.gAds, n.rRe);
// = Gasto em Ads / Reuniões Realizadas
```

---

### 💵 f.cpV - Custo por Venda

**Fórmula:**
```javascript
f.cpV = calcP(f.gAds, n.v);
// = Gasto em Ads / Vendas
```

---

## 5. Métricas de Delta/Velocidade (dt)

Calculadas a partir de `crm_stage_transitions` (linhas 398-431)

### ⏱️ dt.ms - MQL → SQL (dias)

**Fonte de Dados:** `crm_stage_transitions`

**Cálculo Atual (linhas 398-406):**
```javascript
const dealTransitions = transitionsByDeal[d.deal_id] || [];

// MQL → SQL: transição para stages SQL (validado via API)
const sqlTransition = dealTransitions.find(t =>
  STAGE_IDS.SQL.includes(t.to_stage_id) && t.time_in_previous_stage_sec
);

if (sqlTransition) {
  const dMs = Math.round(Number(sqlTransition.time_in_previous_stage_sec) / (60 * 60 * 24));
  sqlM._deltas.ms.push(dMs);
  // ... média calculada depois
}
```

**STAGE_IDS.SQL:**
```javascript
SQL: [19, 50]
// Stage 19: Pipeline 1 (Geral)
// Stage 50: Pipeline 9 (Inbound SDR)
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', cd.deal_created_at) as mes,
  AVG(ROUND(cst.time_in_previous_stage_sec / (60 * 60 * 24))) as delta_mql_sql_dias
FROM crm_deals cd
JOIN crm_stage_transitions cst ON cd.deal_id = cst.deal_id
WHERE cst.to_stage_id IN (19, 50)  -- Stages SQL
  AND cst.time_in_previous_stage_sec IS NOT NULL
  AND cd.custom_fields::jsonb->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'  -- is_sql
GROUP BY DATE_TRUNC('month', cd.deal_created_at)
ORDER BY mes;
```

**Finalização (linha 455):**
```javascript
dt.ms = m._deltas.ms.length > 0
  ? Math.round(m._deltas.ms.reduce((a,b) => a+b, 0) / m._deltas.ms.length)
  : 0;
```

---

### ⏱️ dt.sr - SQL → Reunião (dias)

**Cálculo Atual (linhas 408-416):**
```javascript
// SQL → Reunião: transição para stages de Reunião (validado via API)
const meetingTransition = dealTransitions.find(t =>
  STAGE_IDS.REUNIAO_AGENDADA.includes(t.to_stage_id) && t.time_in_previous_stage_sec
);

if (meetingTransition) {
  const dSr = Math.round(Number(meetingTransition.time_in_previous_stage_sec) / (60 * 60 * 24));
  sqlM._deltas.sr.push(dSr);
}
```

**STAGE_IDS.REUNIAO_AGENDADA:**
```javascript
REUNIAO_AGENDADA: [3, 45, 51, 27, 37]
// Stage 3: Pipeline 1 (Geral)
// Stage 45: Pipeline 8 (Inbound Closer)
// Stage 51: Pipeline 9 (Inbound SDR)
// Stage 27: Pipeline 5 (Indicação Closer)
// Stage 37: Pipeline 7 (Prospecção Ativa)
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', cd.deal_created_at) as mes,
  AVG(ROUND(cst.time_in_previous_stage_sec / (60 * 60 * 24))) as delta_sql_reuniao_dias
FROM crm_deals cd
JOIN crm_stage_transitions cst ON cd.deal_id = cst.deal_id
WHERE cst.to_stage_id IN (3, 45, 51, 27, 37)  -- Stages Reunião
  AND cst.time_in_previous_stage_sec IS NOT NULL
  AND cd.custom_fields::jsonb->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'  -- is_sql
GROUP BY DATE_TRUNC('month', cd.deal_created_at)
ORDER BY mes;
```

---

### ⏱️ dt.rv - Reunião → Venda (dias)

**Cálculo Atual (linhas 418-422):**
```javascript
// Reunião → Venda (Data Reunião agendada vs sales data_fechamento)
const saleDate = dealEmail ? saleDateByEmail[dealEmail] : null;

if (agendamentoDate && saleDate) {
  const dRv = daysDiff(agendamentoDate, saleDate);
  if (dRv !== null) {
    sqlM._deltas.rv.push(dRv);
  }
}
```

**Função daysDiff (linhas 388-394):**
```javascript
const daysDiff = (d1, d2) => {
  if (!d1 || !d2) return null;
  const a = new Date(d1), b = new Date(d2);
  if (isNaN(a) || isNaN(b)) return null;
  const diff = Math.abs(b - a) / (1000 * 60 * 60 * 24);
  return Math.round(diff);
};
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', s.data_fechamento) as mes,
  AVG(
    ABS(EXTRACT(EPOCH FROM (s.data_fechamento - (cd.custom_fields::jsonb->>'8eff24b00226da8dfb871caaf638b62af68bf16b')::date)) / (60*60*24))
  ) as delta_reuniao_venda_dias
FROM sales s
JOIN crm_deals cd ON LOWER(TRIM(s.email_pipedrive)) = LOWER(TRIM(cd.person_email))
WHERE cd.custom_fields::jsonb->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'  -- is_sql
  AND cd.custom_fields::jsonb->>'8eff24b00226da8dfb871caaf638b62af68bf16b' IS NOT NULL  -- data_reuniao
  AND s.data_fechamento IS NOT NULL
GROUP BY DATE_TRUNC('month', s.data_fechamento)
ORDER BY mes;
```

**Regras:**
- ✅ Matching por email (`person_email` ↔ `email_pipedrive`)
- ✅ Diferença em dias entre `data_reuniao` (custom field) e `data_fechamento`
- ⚠️ Depende de email matching (frágil)

---

### ⏱️ dt.lv - Lead → Venda (dias)

**Cálculo Atual (linhas 424-431):**
```javascript
// Lead criação → Venda (deal_created_at vs sales data_fechamento)
if (d.deal_created_at && saleDate) {
  const dLv = daysDiff(d.deal_created_at, saleDate);
  if (dLv !== null) {
    sqlM._deltas.lv.push(dLv);
  }
}
```

**Query SQL Equivalente:**
```sql
SELECT
  DATE_TRUNC('month', s.data_fechamento) as mes,
  AVG(
    ABS(EXTRACT(EPOCH FROM (s.data_fechamento - cd.deal_created_at)) / (60*60*24))
  ) as delta_lead_venda_dias
FROM sales s
JOIN crm_deals cd ON LOWER(TRIM(s.email_pipedrive)) = LOWER(TRIM(cd.person_email))
WHERE cd.custom_fields::jsonb->>'2e17191cfb8e6f4a58359adc42a08965a068e8bc' = '75'  -- is_sql
  AND cd.deal_created_at IS NOT NULL
  AND s.data_fechamento IS NOT NULL
GROUP BY DATE_TRUNC('month', s.data_fechamento)
ORDER BY mes;
```

---

## 6. Motivos de Perda

**Fonte de Dados:** `crm_deals` (campo `lost_reason`)

**Cálculo Atual (linhas 339-356):**
```javascript
// Motivos de perda (por etapa do funil)
if (d.status === 'lost' && d.lost_reason) {

  // Perdas na etapa MQL
  if (STAGE_IDS.MQL.includes(d.stage_id)) {
    m.perdas.mql.push(d.lost_reason);
  }

  // Perdas na etapa SQL
  else if (STAGE_IDS.SQL.includes(d.stage_id)) {
    m.perdas.sql.push(d.lost_reason);
  }

  // Perdas na etapa Proposta/Contrato
  else if (STAGE_IDS.PROPOSTA.includes(d.stage_id) || STAGE_IDS.CONTRATO_ENVIADO.includes(d.stage_id)) {
    m.perdas.proposta.push(d.lost_reason);
  }
}
```

**Sumarização (linhas 472-480):**
```javascript
const summarizePerdas = (arr) => {
  const grouped = {};
  arr.forEach(reason => {
    grouped[reason] = (grouped[reason] || 0) + 1;
  });
  return Object.entries(grouped)
    .sort((a,b) => b[1] - a[1])
    .map(([motivo, count]) => ({ motivo, count }));
};

m.perdas.mql = summarizePerdas(m.perdas.mql);
m.perdas.sql = summarizePerdas(m.perdas.sql);
m.perdas.proposta = summarizePerdas(m.perdas.proposta);
```

**Query SQL Equivalente:**
```sql
-- Perdas MQL
SELECT
  DATE_TRUNC('month', deal_created_at) as mes,
  lost_reason as motivo,
  COUNT(*) as quantidade
FROM crm_deals
WHERE status = 'lost'
  AND lost_reason IS NOT NULL
  AND stage_id IN (1, 49)  -- MQL stages
GROUP BY DATE_TRUNC('month', deal_created_at), lost_reason
ORDER BY mes, quantidade DESC;

-- Perdas SQL
SELECT
  DATE_TRUNC('month', deal_created_at) as mes,
  lost_reason as motivo,
  COUNT(*) as quantidade
FROM crm_deals
WHERE status = 'lost'
  AND lost_reason IS NOT NULL
  AND stage_id IN (19, 50)  -- SQL stages
GROUP BY DATE_TRUNC('month', deal_created_at), lost_reason
ORDER BY mes, quantidade DESC;

-- Perdas Proposta/Contrato
SELECT
  DATE_TRUNC('month', deal_created_at) as mes,
  lost_reason as motivo,
  COUNT(*) as quantidade
FROM crm_deals
WHERE status = 'lost'
  AND lost_reason IS NOT NULL
  AND stage_id IN (4, 46, 29, 39, 41, 47, 43, 40)  -- Proposta + Contrato stages
GROUP BY DATE_TRUNC('month', deal_created_at), lost_reason
ORDER BY mes, quantidade DESC;
```

---

## 🔍 Pontos de Atenção Identificados

### ⚠️ 1. Filtros de Status

Atualmente **NÃO** há filtro por `status` em várias métricas:

- **Receita/Vendas:** Inclui registros com status "Churn"?
- **Pipeline Total:** Inclui deals `status = 'lost'` ou `'won'`?

### ⚠️ 2. Email Matching (Frágil)

Várias métricas dependem de matching por email:
- SQL (lead date via email)
- Delta Reunião → Venda
- Delta Lead → Venda

**Problemas possíveis:**
- Emails com case diferente
- Emails com espaços
- Emails divergentes entre sistemas

### ⚠️ 3. Custom Fields com Hashes

Agora estão em constantes, mas ainda usam hashes:
```javascript
'2e17191cfb8e6f4a58359adc42a08965a068e8bc'  // SQL?
'8eff24b00226da8dfb871caaf638b62af68bf16b'  // Data Reunião
'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3'  // Reunião Realizada
```

### ⚠️ 4. Data Base Inconsistente

- **Leads/MQL:** Usa `submitted_at` de yayforms
- **SQL:** Usa `submitted_at` do lead (via email) OU `deal_created_at`
- **Reuniões:** Usa data do SQL (que já é híbrida)
- **Vendas:** Usa `data_fechamento`

### ⚠️ 5. Gasto em Ads

Atualmente salva em `f.gAds` mas deveria ser `g.gAds`:
```javascript
updateMetrics(m, mc, mc.spend, 'f', 'gAds', wk);  // ❌ tipo 'f'
// Deveria ser:
updateMetrics(m, mc, mc.spend, 'g', 'gAds', wk);  // ✅ tipo 'g'
```

---

## 📝 Próximos Passos

1. **Envie suas queries de validação** para cada métrica
2. **Identifique discrepâncias** entre suas queries e o código atual
3. **Ajustaremos o código** para ficar exatamente como você precisa
4. **Validaremos** com dados reais comparando antes/depois

---

**Pronto para receber suas queries! 🚀**
