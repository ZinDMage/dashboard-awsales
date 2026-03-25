# ✅ Resultados da Validação - Pipedrive API

**Data:** 2026-03-25 15:00
**Método:** Pipedrive API v1
**Status:** ✅ Validação Completa

---

## 📊 Resumo Executivo

✅ **VALIDAÇÃO 1:** Stage IDs mapeados (10 pipelines, 44 stages)
✅ **VALIDAÇÃO 2:** Custom Fields identificados e documentados
✅ **VALIDAÇÃO 3:** Definição de View Page confirmada (Meta Ads + Google Ads)

---

## 🔴 VALIDAÇÃO 1: Stage IDs do Pipedrive

### Pipelines Ativos

| Pipeline ID | Nome | Stages Ativos |
|-------------|------|---------------|
| 1 | 📍 Geral | 7 stages |
| 9 | 🔽 Inbound (SDR) | 4 stages |
| 8 | 🔽 Inbound (Closer) | 3 stages |
| 5 | 🙋‍♂️ Indicação (Closer) | 3 stages |
| 10 | 🙋‍♂️ Indicação (SDR) | 4 stages |
| 4 | 🎩 Eventos | 5 stages |
| 7 | 🔎 Prospecção Ativa | 6 stages |
| 6 | 🇺🇸 WD | 5 stages |
| 2 | 🦷 Clínicas | 6 stages |
| 3 | ♻️ Reciclagem | 5 stages |

### Mapeamento Completo: Stage IDs → Nomes

#### Pipeline 1: 📍 Geral (Principal)

| Stage ID | Nome | Order | Deal Probability |
|----------|------|-------|------------------|
| **1** | 👤 Lead (MQL) | 1 | 100% |
| 2 | 📞 Contatado | 2 | 100% |
| **19** | 👤 Lead Qualificado (SQL) | 3 | 100% |
| **3** | 🗓️ Reunião Ag. | 4 | 100% |
| **4** | 🧾 Proposta feita | 5 | 40% |
| **41** | Contrato Enviado | 6 | 100% |
| **6** | 🚫 Reagendamento Pendente | 0 | 100% |

#### Pipeline 9: 🔽 Inbound (SDR)

| Stage ID | Nome | Order | Deal Probability |
|----------|------|-------|------------------|
| **49** | 👤 Lead (MQL) | 1 | 100% |
| **50** | 👤 Lead Qualificado (SQL) | 2 | 100% |
| **51** | 🗓️ Reunião Ag. (Incerto) | 3 | 100% |
| **48** | 🚫 Reagendamento Pendente | 4 | 100% |

#### Pipeline 8: 🔽 Inbound (Closer)

| Stage ID | Nome | Order | Deal Probability |
|----------|------|-------|------------------|
| **45** | 🗓️ Reunião Ag. (Confirmada) | 1 | 100% |
| **46** | 🧾 Proposta feita | 2 | 100% |
| **47** | ✍️ Contrato Enviado | 3 | 100% |

#### Pipeline 7: 🔎 Prospecção Ativa

| Stage ID | Nome | Order | Deal Probability |
|----------|------|-------|------------------|
| 35 | 👤 SQL | 1 | 100% |
| 36 | 📞 Contatado | 2 | 100% |
| **37** | 🗓️ Reunião Agendada | 3 | 100% |
| 38 | 🚫 Reagendamento Pendente | 4 | 100% |
| **39** | 🧾 Proposta feita | 5 | 100% |
| 40 | 📤 Contrato Enviado | 6 | 100% |

#### Pipeline 5: 🙋‍♂️ Indicação (Closer)

| Stage ID | Nome | Order | Deal Probability |
|----------|------|-------|------------------|
| **27** | 🗓️ Reunião Ag. (Confirmada) | 1 | 100% |
| **29** | 🧾 Proposta feita | 2 | 100% |
| 43 | 📤 Contrato Enviado | 3 | 100% |

---

## 🎯 Comparação: dataService.js vs Pipedrive Real

### Definição no Código (dataService.js linhas 269-278)

```javascript
const STAGE_IDS = {
  MQL: [1, 3, 49],        // ⚠️ PROBLEMA: 3 não é MQL
  SQL: [4, 50],           // ⚠️ PROBLEMA: 4 não é SQL
  REUNIAO: [6, 7, 45],    // ⚠️ PROBLEMA: 6 e 7 não são estágios de reunião
  NEGOCIACAO: [46],       // ✅ OK
  PROPOSTA: [47]          // ✅ OK (mas é "Contrato Enviado", não "Proposta")
};
```

### Mapeamento CORRETO Baseado no Pipedrive

```javascript
const STAGE_IDS = {
  // MQL - Marketing Qualified Lead
  MQL: [1, 49],  // Pipeline 1 + Pipeline 9 (SDR)

  // SQL - Sales Qualified Lead
  SQL: [19, 50],  // Pipeline 1 (stage 19) + Pipeline 9 (stage 50)

  // Reunião Agendada
  REUNIAO_AGENDADA: [3, 45, 51, 27, 37],
  // - 3: Pipeline 1 (Geral) - Reunião Ag.
  // - 45: Pipeline 8 (Inbound Closer) - Reunião Ag. (Confirmada)
  // - 51: Pipeline 9 (Inbound SDR) - Reunião Ag. (Incerto)
  // - 27: Pipeline 5 (Indicação Closer) - Reunião Ag. (Confirmada)
  // - 37: Pipeline 7 (Prospecção Ativa) - Reunião Agendada

  // Proposta Feita / Negociação
  PROPOSTA: [4, 46, 29, 39],
  // - 4: Pipeline 1 (Geral) - Proposta feita
  // - 46: Pipeline 8 (Inbound Closer) - Proposta feita
  // - 29: Pipeline 5 (Indicação Closer) - Proposta feita
  // - 39: Pipeline 7 (Prospecção Ativa) - Proposta feita

  // Contrato Enviado
  CONTRATO_ENVIADO: [41, 47, 43, 40],
  // - 41: Pipeline 1 (Geral) - Contrato Enviado
  // - 47: Pipeline 8 (Inbound Closer) - Contrato Enviado
  // - 43: Pipeline 5 (Indicação Closer) - Contrato Enviado
  // - 40: Pipeline 7 (Prospecção Ativa) - Contrato Enviado

  // Reagendamento Pendente
  REAGENDAMENTO: [6, 48, 38, 57]
  // - 6: Pipeline 1 (Geral) - Reagendamento Pendente
  // - 48: Pipeline 9 (Inbound SDR) - Reagendamento Pendente
  // - 38: Pipeline 7 (Prospecção Ativa) - Reagendamento Pendente
  // - 57: Pipeline 4 (Eventos) - Reagendamento Pendente
};
```

### ❌ Discrepâncias Críticas Identificadas

#### 1. Stage ID 3 ≠ MQL
- **Código diz:** Stage 3 é MQL
- **Pipedrive real:** Stage 3 = "🗓️ Reunião Ag." (Pipeline 1)
- **Impacto:** Reuniões agendadas sendo contadas como MQL

#### 2. Stage ID 4 ≠ SQL
- **Código diz:** Stage 4 é SQL
- **Pipedrive real:** Stage 4 = "🧾 Proposta feita" (Pipeline 1)
- **Impacto:** Propostas sendo contadas como SQL

#### 3. Stage IDs 6 e 7 ≠ Reunião
- **Código diz:** Stage 6 e 7 são reuniões
- **Pipedrive real:**
  - Stage 6 = "🚫 Reagendamento Pendente" (Pipeline 1)
  - Stage 7 = Não existe (provavelmente ID antigo)
- **Impacto:** Reagendamentos sendo contados como reuniões

#### 4. Faltam pipelines alternativos
- Código só mapeia Pipeline 1 e 9
- Existem 10 pipelines ativos
- Deals dos outros pipelines podem não estar sendo contabilizados

---

## 🟡 VALIDAÇÃO 2: Custom Fields do Pipedrive

### Campo 1: SQL?

| Atributo | Valor |
|----------|-------|
| **ID** | 80 |
| **Key** | `2e17191cfb8e6f4a58359adc42a08965a068e8bc` |
| **Nome** | SQL? |
| **Tipo** | enum (Single Option) |
| **Valores** | • **75** = "Sim" ✅<br>• 76 = "Não"<br>• 79 = "A revisar" |

**Uso no código:**
```javascript
const isSQL = cj['2e17191cfb8e6f4a58359adc42a08965a068e8bc'] == '75';
// ✅ CORRETO: Verifica se valor = 75 (Sim)
```

### Campo 2: Data Reunião

| Atributo | Valor |
|----------|-------|
| **ID** | 46 |
| **Key** | `8eff24b00226da8dfb871caaf638b62af68bf16b` |
| **Nome** | Data Reunião |
| **Tipo** | date |
| **Formato** | YYYY-MM-DD |

**Uso no código:**
```javascript
const agendamentoDate = cj['8eff24b00226da8dfb871caaf638b62af68bf16b'];
// ✅ CORRETO: Captura data de agendamento
```

### Campo 3: Reunião Realizada

| Atributo | Valor |
|----------|-------|
| **ID** | 74 |
| **Key** | `baf2724fcbeec84a36e90f9dc3299431fe1b0dd3` |
| **Nome** | Reunião Realizada |
| **Tipo** | enum (Single Option) |
| **Valores** | • **47** = "Sim" ✅<br>• 59 = "Não" |

**Uso no código:**
```javascript
if (cj['baf2724fcbeec84a36e90f9dc3299431fe1b0dd3'] == '47') {
  // reunião realizada
}
// ✅ CORRETO: Verifica se valor = 47 (Sim)
```

### 📝 Constantes Recomendadas para Refatoração

```javascript
// Custom Fields do Pipedrive
const CUSTOM_FIELDS = {
  SQL_FLAG: {
    key: '2e17191cfb8e6f4a58359adc42a08965a068e8bc',
    name: 'SQL?',
    values: {
      SIM: '75',
      NAO: '76',
      A_REVISAR: '79'
    }
  },
  DATA_REUNIAO: {
    key: '8eff24b00226da8dfb871caaf638b62af68bf16b',
    name: 'Data Reunião',
    type: 'date'
  },
  REUNIAO_REALIZADA: {
    key: 'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3',
    name: 'Reunião Realizada',
    values: {
      SIM: '47',
      NAO: '59'
    }
  }
};

// Uso refatorado
const isSQL = cj[CUSTOM_FIELDS.SQL_FLAG.key] == CUSTOM_FIELDS.SQL_FLAG.values.SIM;
const agendamentoDate = cj[CUSTOM_FIELDS.DATA_REUNIAO.key];
const reuniaoRealizada = cj[CUSTOM_FIELDS.REUNIAO_REALIZADA.key] == CUSTOM_FIELDS.REUNIAO_REALIZADA.values.SIM;
```

---

## 🟠 VALIDAÇÃO 3: Definição de "View Page"

### Decisão Confirmada

**View Page = Meta Ads `landing_page_view` + Google Ads `conversions`**

### Implementação Atual (dataService.js linha 212)

```javascript
// Meta Ads - View Page
if (act.action_type === 'landing_page_view')
  updateMetrics(m, act, act.value, 'n', 'vp', wk);

// Google Ads - View Page (linha 230)
updateMetrics(m, gad, gad.conversions, 'n', 'vp', wk);
```

**Status:** ✅ Implementação está correta conforme decisão

### Justificativa

- Captura tráfego pago de múltiplas fontes (Meta + Google)
- Mede pessoas que **chegaram na landing page** após clicar no anúncio
- Alinhado com funil de marketing digital padrão
- Permite calcular Connect Rate = View Page / Cliques

### Métricas Impactadas

1. **View Page** (métrica direta)
2. **Connect Rate** = View Page / Cliques
3. **Conversão Página Captura** = Leads / View Page

---

## 📋 Ações Recomendadas

### 🔥 Crítico (Corrigir Imediatamente)

- [ ] **Corrigir mapeamento de Stage IDs no dataService.js**
  - Remover stage 3 de MQL (é Reunião)
  - Remover stage 4 de SQL (é Proposta)
  - Remover stages 6 e 7 de REUNIAO
  - Adicionar stage 19 em SQL
  - Adicionar stages de outros pipelines (5, 7, 8)

### 🟠 Alto (Melhoria de código)

- [ ] **Criar constantes para Custom Fields**
  - Substituir hashes por constantes nomeadas
  - Adicionar comentários explicativos

- [ ] **Documentar no PRD**
  - Atualizar seção Data Model Requirements
  - Adicionar tabela de mapeamento stage_id → stage_name

### 🟡 Médio (Análise adicional)

- [ ] **Validar impacto da correção de Stage IDs**
  - Rodar queries antes/depois para comparar números
  - Verificar se métricas históricas precisam ser recalculadas

- [ ] **Considerar multi-pipeline support**
  - Avaliar se deals de outros pipelines devem ser incluídos
  - Definir regras de negócio para cada pipeline

---

## 📊 Impacto Estimado da Correção

### Antes (Código Atual - INCORRETO)

```javascript
MQL: [1, 3, 49]     // Inclui stage 3 (Reunião) ❌
SQL: [4, 50]        // Inclui stage 4 (Proposta) ❌
```

### Depois (Código Corrigido)

```javascript
MQL: [1, 49]        // Apenas MQL reais ✅
SQL: [19, 50]       // Apenas SQL reais ✅
```

### Possível Impacto nas Métricas

| Métrica | Impacto Esperado |
|---------|------------------|
| # MQL | ⬇️ Redução (remover reuniões agendadas) |
| # SQL | ⬇️ Redução (remover propostas) |
| # Reuniões Agendadas | ⬆️ Aumento (corrigir contabilização) |
| Taxa MQL → SQL | ⬆️ Aumento (numerador e denominador reduzem) |
| Taxa SQL → Reunião | ⬆️ Aumento (melhor precisão) |

**Recomendação:** Rodar análise histórica para quantificar o impacto real antes de atualizar produção.

---

## 🔗 Próximos Passos

1. ✅ Validações concluídas
2. ⏳ Atualizar [prd.md](prd.md) com dados validados
3. ⏳ Atualizar [DISCREPANCIAS-CRITICAS.md](DISCREPANCIAS-CRITICAS.md)
4. ⏳ Criar branch de correção: `fix/pipedrive-stage-ids`
5. ⏳ Refatorar [dataService.js](../../Dash%20AwSales/dataService.js)
6. ⏳ Testar em ambiente de desenvolvimento
7. ⏳ Validar métricas antes/depois
8. ⏳ Deploy em produção

---

**Responsável pela Validação:** Claude (IA)
**Responsável pela Implementação:** [Desenvolvedor]
**Aprovação de Negócio:** [Product Owner]
**Última Atualização:** 2026-03-25 15:00
