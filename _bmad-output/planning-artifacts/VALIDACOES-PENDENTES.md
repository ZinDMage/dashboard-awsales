# ✅ Validações Pendentes - AwSales Dashboard

**Data:** 2026-03-25
**Status:** Aguardando validação com stakeholders
**Prioridade:** Alta (bloqueia finalização completa do PRD)

---

## 📋 Resumo Executivo

Após análise completa do código-fonte ([dataService.js](../Dash%20AwSales/dataService.js)) e do banco de dados ([ddl_dashboard_awsales.sql](../Dash%20AwSales/ddl_supabase/ddl_dashboard_awsales.sql)), identificamos **3 validações críticas** que precisam de input de negócio/Pipedrive Admin para finalizar a documentação técnica.

**Impacto:** Estas validações não impedem o funcionamento do sistema atual, mas são necessárias para:
- ✅ Documentação técnica completa e precisa
- ✅ Manutenibilidade do código (evitar "números mágicos")
- ✅ Onboarding de novos desenvolvedores
- ✅ Auditoria de métricas de negócio

---

## 🔴 VALIDAÇÃO 1: Stage IDs do Pipedrive

### Contexto

O arquivo `dataService.js` (linhas 269-278) usa stage IDs hardcoded para categorizar deals:

```javascript
const STAGE_IDS = {
  MQL: [1, 3, 49],
  SQL: [4, 50],
  REUNIAO: [6, 7, 45],
  NEGOCIACAO: [46],
  PROPOSTA: [47]
};
```

### Pergunta

**Estes stage IDs estão corretos e atualizados?**

### Como Validar

1. Acesse o Pipedrive como administrador
2. Navegue para: **Settings → Pipelines → [Nome do Pipeline de Vendas]**
3. Anote os **stage_id** e **stage_name** de cada etapa

### Template de Resposta

Por favor, preencha a tabela abaixo com os dados reais do Pipedrive:

| Stage ID | Stage Name (Pipedrive) | Categoria AwSales |
|----------|------------------------|-------------------|
| 1        | ?                      | MQL               |
| 3        | ?                      | MQL               |
| 49       | ?                      | MQL               |
| 4        | ?                      | SQL               |
| 50       | ?                      | SQL               |
| 6        | ?                      | REUNIAO           |
| 7        | ?                      | REUNIAO           |
| 45       | ?                      | REUNIAO           |
| 46       | ?                      | NEGOCIACAO        |
| 47       | ?                      | PROPOSTA          |

**Adicione outras etapas se existirem:**

| Stage ID | Stage Name (Pipedrive) | Categoria AwSales |
|----------|------------------------|-------------------|
| ?        | ?                      | ?                 |

### Questões Adicionais

1. **Pipeline único ou múltiplos?**
   - [ ] Temos apenas 1 pipeline de vendas
   - [X] Temos múltiplos pipelines (especificar quantos: ___)

2. **Stage IDs mudam frequentemente?**
   - [X] Sim, reorganizamos o funil com frequência utilizando automações de acordo com o preechimento dos campos customizados
   - [ ] Não, é estável

3. **Existem etapas que não estão mapeadas no código?**
   - [ ] Não, todas estão mapeadas
   - [ ] Sim, faltam as seguintes: ___

---

## 🟡 VALIDAÇÃO 2: Custom Fields do Pipedrive

### Contexto

O arquivo `dataService.js` (linhas 283-304) acessa custom fields usando **hashes** em vez de nomes descritivos:

```javascript
const cj = parseCustomFields(d.custom_fields);

// Custom field 1: SQL flag
const isSQL = cj['2e17191cfb8e6f4a58359adc42a08965a068e8bc'] == '75';

// Custom field 2: Data agendamento
const agendamentoDate = cj['8eff24b00226da8dfb871caaf638b62af68bf16b'];

// Custom field 3: Reunião realizada
if (cj['baf2724fcbeec84a36e90f9dc3299431fe1b0dd3'] == '47') {
  // reunião realizada
}
```

### Pergunta

**Quais são os nomes reais desses custom fields no Pipedrive?**

### Como Validar

1. Acesse o Pipedrive como administrador
2. Navegue para: **Settings → Data fields → Deal custom fields**
3. Procure por campos que tenham os hashes mencionados (geralmente visível na URL ao editar o campo)
4. Alternativamente, identifique os campos pela lógica:
   - Um campo que marca "SQL" com valor "75"
   - Um campo de data para "Agendamento de reunião"
   - Um campo que marca "Reunião realizada" com valor "47"

### Template de Resposta

Por favor, preencha a tabela abaixo:

| Hash (Key) | Nome do Campo (Pipedrive) | Tipo | Valores Possíveis | Descrição |
|------------|---------------------------|------|-------------------|-----------|
| `2e17191cfb8e6f4a58359adc42a08965a068e8bc` | ? | ? | '75' = ? | Marca SQL? |
| `8eff24b00226da8dfb871caaf638b62af68bf16b` | ? | Date/Text? | Data no formato ? | Data de agendamento? |
| `baf2724fcbeec84a36e90f9dc3299431fe1b0dd3` | ? | ? | '47' = ? | Reunião realizada? |

**Exemplo de resposta:**

| Hash (Key) | Nome do Campo (Pipedrive) | Tipo | Valores Possíveis | Descrição |
|------------|---------------------------|------|-------------------|-----------|
| `2e17191c...` | Status de Qualificação | Single Option | '75' = SQL Qualificado | Marca o lead como SQL |
| `8eff24b0...` | Data de Agendamento | Date | DD/MM/YYYY | Data da reunião agendada |
| `baf2724f...` | Status da Reunião | Single Option | '47' = Reunião Realizada | Status após reunião |

### Impacto

Com esses nomes, poderemos refatorar o código de:

```javascript
// ❌ Difícil de entender
const isSQL = cj['2e17191cfb8e6f4a58359adc42a08965a068e8bc'] == '75';
```

Para:

```javascript
// ✅ Fácil de entender
const CUSTOM_FIELDS = {
  STATUS_QUALIFICACAO: '2e17191cfb8e6f4a58359adc42a08965a068e8bc'
};
const isSQL = cj[CUSTOM_FIELDS.STATUS_QUALIFICACAO] == '75';
```

---

## 🟠 VALIDAÇÃO 3: Definição de "View Page"

### Contexto

O sistema atualmente calcula "View Page" usando **Meta Ads `landing_page_view` + Google Ads `conversions`** ([dataService.js:212](../Dash%20AwSales/dataService.js#L212)).

Porém, existe uma tabela `yayforms_responses` com campo `started_at` que também poderia representar "visualizações de página" (pessoas que iniciaram o formulário).

### Pergunta

**Qual é a definição de negócio correta para a métrica "View Page"?**

### Opções

#### Opção A: Meta Ads + Google Ads (Atual)
- **Definição:** Pessoas que clicaram no anúncio e **chegaram na landing page**
- **Fonte de dados:**
  - Meta Ads: `landing_page_view`
  - Google Ads: `conversions`
- **Prós:**
  - Captura tráfego de múltiplas fontes de ads
  - Independente do formulário (mede página de destino)
- **Contras:**
  - Não inclui tráfego orgânico ou direto
  - Depende de tracking correto das plataformas de ads

#### Opção B: YayForms Started (Alternativa)
- **Definição:** Pessoas que **iniciaram o preenchimento** do formulário
- **Fonte de dados:** `yayforms_responses.started_at`
- **Prós:**
  - Captura todas as fontes (ads, orgânico, direto, etc.)
  - Dado confiável e direto (não depende de pixels)
- **Contras:**
  - Não mede quem viu a página mas não iniciou o formulário
  - Pode subestimar o tráfego real

#### Opção C: Ambos (Nova Métrica)
- Manter "View Page" = Meta Ads + Google Ads
- Criar nova métrica "Formulários Iniciados" = YayForms started_at
- Calcular ambas separadamente

### Template de Resposta

**Escolha uma opção:**

- [ ] **Opção A** - Manter atual (Meta Ads + Google Ads)
- [ ] **Opção B** - Mudar para YayForms started_at
- [ ] **Opção C** - Criar ambas as métricas separadamente
- [ ] **Outra** - Especificar: ___

**Justificativa (opcional):**

___

### Impacto nas Métricas

Esta definição afeta diretamente:

1. **Connect Rate** = View Page / Cliques
2. **Conversão Página Captura** = Leads / View Page

**Exemplo com dados hipotéticos:**

| Cenário | Cliques | View Page (A) | View Page (B) | Connect Rate (A) | Connect Rate (B) |
|---------|---------|---------------|---------------|------------------|------------------|
| Atual   | 1000    | 800           | 650           | 80%              | 65%              |

---

## 📅 Próximos Passos

### Fase 1: Coleta de Informações (2-3 dias)

**Responsável:** Product Owner / Head de Marketing + Pipedrive Admin

1. [ ] Acessar Pipedrive e coletar informações das Validações 1 e 2
2. [ ] Reunir com stakeholders para decidir Validação 3
3. [ ] Preencher templates de resposta acima

### Fase 2: Atualização de Documentação (1 dia)

**Responsável:** Desenvolvedor

1. [ ] Atualizar [prd.md](prd.md) com informações validadas
2. [ ] Atualizar [DISCREPANCIAS-CRITICAS.md](DISCREPANCIAS-CRITICAS.md) marcando validações como resolvidas
3. [ ] Criar constantes nomeadas no código para custom fields

### Fase 3: Refatoração (Opcional, 2-3 dias)

**Responsável:** Desenvolvedor

1. [ ] Refatorar `dataService.js` para usar constantes em vez de hashes
2. [ ] Adicionar comentários explicativos sobre stage IDs
3. [ ] Atualizar lógica de View Page se necessário
4. [ ] Criar testes unitários para regras de qualificação

---

## 📊 Status Atual

| Validação | Prioridade | Status | Bloqueador? |
|-----------|-----------|--------|-------------|
| 1. Stage IDs | 🔴 Alta | ⏳ Pendente | Não |
| 2. Custom Fields | 🟡 Média | ⏳ Pendente | Não |
| 3. View Page | 🟠 Alta | ⏳ Pendente | Não |

**Tempo estimado para resolução completa:** 5-7 dias úteis

---

## 📞 Contato

Para preencher este documento, entre em contato com:

- **Técnico:** [Desenvolvedor responsável]
- **Negócio:** [Product Owner / Head de Marketing]
- **Pipedrive Admin:** [Administrador do CRM]

---

**Última atualização:** 2026-03-25 14:45
**Próxima revisão:** Após recebimento das respostas
