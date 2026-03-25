---
stepsCompleted:
  - 'step-01-init'
  - 'step-02-discovery'
  - 'step-02b-vision'
  - 'step-02c-executive-summary'
  - 'step-03-success'
  - 'step-04-journeys'
  - 'step-05-domain'
  - 'step-06-innovation'
  - 'step-07-project-type'
inputDocuments:
  - '_bmad-output/project-context.md'
briefCount: 0
researchCount: 0
brainstormingCount: 0
projectDocsCount: 1
workflowType: 'prd'
projectType: 'brownfield'
classification:
  projectType: 'web_app'
  domain: 'martech_salestech_revops'
  complexity: 'medium'
  projectContext: 'brownfield'
domainRequirementsSkipped: true
innovationSkipped: true
---

# Product Requirements Document - AwSales

**Author:** Lucaskurt
**Date:** 2026-03-24

## Executive Summary

O **AwSales Dashboard** é uma aplicação web interna de Revenue Operations que resolve o problema crítico de decisões de Marketing e Comercial sendo tomadas no escuro, sem visibilidade clara de onde o funil está quebrando. Atualmente, a equipe da AwSales depende de planilhas colaborativas frágeis onde qualquer pessoa pode alterar dados manualmente, comprometendo a confiabilidade das informações e gerando decisões erradas que criam gaps no plano de ação.

Este dashboard unifica dados de múltiplas fontes — investimento em anúncios (Meta, Google, LinkedIn), leads do formulário de qualificação, e pipeline do CRM — em uma **fonte única da verdade blindada e automatizada** (atualizada a cada hora), permitindo que Heads e Gestores tomem decisões **Data-Driven** com confiança total na precisão dos dados.

**Público-alvo:** Heads de Marketing e Comercial da AwSales (usuários primários compartilhando visão unificada) que precisam acompanhar resultados unificados e identificar gargalos operacionais do funil completo.

**Problema resolvido:** Eliminação de decisões baseadas em dados frágeis/editáveis e criação de clareza operacional sobre o desempenho completo do funil Marketing → Comercial, com visibilidade de ponta a ponta.

**Métricas Críticas (V1):**
- Receita Gerada
- Gasto em Ads (Meta, Google, LinkedIn)
- Margem de Contribuição
- Valor do Pipeline (Faturamento Projetado + Receita Projetada)
- Vendas e Ticket Médio

### O Que Torna Este Produto Especial

1. **Precisão Absoluta com Governança de Dados** - Diferente de planilhas colaborativas editáveis, o AwSales Dashboard funciona como uma fonte única da verdade protegida. Dados são ingeridos automaticamente via n8n das plataformas de origem (ads, formulários, CRM) com atualização horária e não podem ser alterados manualmente, eliminando o risco de "alguém editar a planilha e quebrar a verdade".

2. **Visibilidade do Funil Completo de Ponta a Ponta** - O momento "AHA!" acontece quando Heads de Marketing e Comercial veem pela primeira vez o funil unificado: investimento em anúncios → leads gerados → qualificação → pipeline → receita fechada, tudo em uma única interface. Essa visão 360° revela imediatamente onde o funil está travando (geração, qualificação, ou conversão comercial).

3. **Unificação Real do Funil RevOps** - Conecta com atualização horária o investimento em anúncios (Meta/Google/LinkedIn) com leads qualificados e negócios no pipeline do CRM. A maioria das empresas tem esses dados separados em sistemas distintos ou planilhas manuais; o AwSales Dashboard os integra automaticamente com precisão para revelar a jornada completa do investimento ao fechamento.

4. **Métricas Financeiras Críticas em Um Lugar Só** - Elimina a necessidade de "presumir o que ocorreu" fornecendo as 6 métricas críticas de RevOps (Receita Gerada, Gasto em Ads, Margem de Contribuição, Valor do Pipeline, Vendas, Ticket Médio) em uma interface unificada. O dashboard se torna a única fonte necessária para tomada de decisão estratégica.

**Insight Central:** A operação da AwSales atingiu escala onde planilhas colaborativas se tornaram um risco operacional. Qualquer pessoa pode alterar um dado e comprometer a integridade da informação, levando a decisões erradas custosas. O AwSales Dashboard resolve isso criando uma camada de governança de dados automatizada (ingestão horária via n8n) que protege a verdade enquanto fornece visibilidade unificada do funil completo de ponta a ponta — da primeira impressão do anúncio até o real fechado.

## Classificação do Projeto

- **Tipo de Projeto:** Web App (Dashboard SPA React + Supabase)
- **Domínio:** MarTech/SalesTech/Revenue Operations
- **Nível de Complexidade:** Médio
  - Volume de dados: ~111MB, 57.064 registros, 16 tabelas no Supabase
  - Integrações automatizadas via n8n com APIs de Meta Ads, Google Ads, LinkedIn Ads
  - Atualização de dados: a cada hora (batch horário)
  - Fase atual: 6 métricas macro críticas (Receita, Gasto, Margem, Pipeline, Vendas, Ticket Médio)
  - Fase futura planejada: atribuição complexa multi-touch por anúncio/campanha
- **Contexto do Projeto:** Brownfield — Sistema existente já operacional com dados estruturados no Supabase. Esta funcionalidade adiciona o dashboard unificado de RevOps para Heads de Marketing e Comercial.

## Success Criteria

### User Success

**Momento "AHA!" alcançado quando:**
- Heads de Marketing e Comercial abrem o dashboard e em **30 segundos** identificam visualmente (através dos indicadores vermelho/verde) onde o funil está com problemas
- Conseguem comparar performance entre períodos (mês atual vs anterior) para identificar tendências imediatamente
- Visualizam o funil completo de ponta a ponta (Impressões → Vendas) em uma única página sem precisar navegar entre abas

**Critérios mensuráveis:**
- Usuários conseguem responder "qual é o maior gargalo do funil este mês?" em menos de 1 minuto
- 100% dos Heads de Marketing e Comercial adotam o dashboard como fonte única da verdade
- Usuários acessam o dashboard **diariamente** para monitoramento operacional e **semanalmente** para preparação de reuniões estratégicas

### Business Success

**Em 3 meses após lançamento:**
- **Redução de tempo de análise:** De ~2h semanais (análise manual em planilhas) para ~15 minutos (consulta do dashboard)
- **Velocidade de decisão:** Decisões críticas tomadas em tempo real baseadas em dados atualizados a cada hora
- **Eliminação de erros:** Zero decisões baseadas em dados incorretos/editados manualmente
- **Identificação proativa de gargalos:** Pelo menos 1 gargalo operacional crítico identificado e corrigido por mês através da visualização do dashboard

**ROI esperado:**
- Economia de ~7.5h/mês por usuário (2 Heads = 15h/mês economizadas)
- Melhoria na qualidade das decisões: decisões baseadas em dados confiáveis e atualizados, não em "achismos" ou dados defasados

### Technical Success

**Performance:**
- Dashboard carrega completamente em **máximo 60 segundos**
- Atualização de dados ocorre a cada hora via n8n → Supabase
- Interface responsiva funcionando perfeitamente em desktop E mobile

**Confiabilidade:**
- 100% de precisão: dados do dashboard batem exatamente com dados brutos do Supabase
- Zero downtime planejado (aplicação disponível 24/7)
- Indicadores visuais claros de última atualização (timestamp visível)

**Usabilidade:**
- Todas as 40+ métricas visíveis em uma única página com scroll
- Seções organizadas e colapsáveis (Principal, Premissas, Números, Financeiro, Deltas, Motivos de Perda)
- Comparação entre períodos (mês atual vs anterior, ou períodos customizados)
- Indicadores visuais (vermelho/verde) para deltas positivos/negativos
- Filtros de período: por ano, mês específico, multi-mês, ou semanas

### Measurable Outcomes

**Métricas de adoção:**
- 100% dos Heads (2 usuários primários) utilizam diariamente no primeiro mês
- Média de 5+ acessos por usuário por semana

**Métricas de impacto:**
- Tempo médio de análise semanal reduzido em 85% (de 2h para 15min)
- 100% das decisões estratégicas documentadas como "baseadas em dados do dashboard"
- Zero incidentes de "dados inconsistentes" reportados após 3 meses

## Product Scope

### MVP - Minimum Viable Product

**Funcionalidades ESSENCIAIS para primeira versão:**

✅ **Visualização completa das métricas:**
- 9 métricas principais (Receita, Gasto, ROI, Margem, Pipeline Total, Fat. Projetado, Receita Projetada, Vendas, Ticket Médio)
- 9 premissas de conversão (CTR, Connect Rate, Conv. Página Captura, Qualified Marketing, Qualified Sales, Agendamento, Show-up, Fechamentos Call, Fechamentos SQL)
- 9 números absolutos do funil (Impressões, Cliques, View Page, Lead, MQL, SQL, Reuniões Agendadas, Reuniões Realizadas, Vendas)
- 7 métricas financeiras de custo por etapa (CP Lead, CP MQL, CP SQL, CP Reunião Agendada, CP Reunião Realizada, CP Venda, Gastos em ADS)
- 4 deltas de velocidade do funil (Tempo médio MQL→SQL, SQL→Reunião, Reunião→Venda, Lead→Venda)
- 3 tabelas de motivo de perda (Perdas MQL, Perdas SQL, Perdas Proposta Realizada)

✅ **Comparação temporal:**
- Visualização lado a lado: período atual vs período anterior
- Indicadores visuais de delta percentual (cores vermelho/verde)
- Filtros: por ano, mês, multi-mês, semanas

✅ **Interface responsiva:**
- Layout funcional em desktop (prioridade)
- Layout adaptado para mobile

✅ **Atualização automatizada:**
- Dados atualizados a cada hora via pipeline n8n → Supabase
- Timestamp de última atualização visível

✅ **Organização visual:**
- Seções colapsáveis por categoria de métrica
- Cards com métricas destacadas
- Layout dark mode (conforme design atual)

**O que NÃO está no MVP:**
- ❌ Drill-down detalhado por anúncio/campanha específica
- ❌ Atribuição multi-touch por anúncio
- ❌ Exportação de relatórios (PDF/Excel)
- ❌ Alertas automáticos (notificações quando métrica atinge threshold)
- ❌ Permissões/roles diferenciados por usuário

### Growth Features (Post-MVP)

**Funcionalidades para versões futuras (após validação do MVP):**

📊 **Análise Detalhada:**
- Drill-down por campanha individual (Meta, Google, LinkedIn)
- Drill-down por anúncio específico dentro de cada campanha
- Análise de cohort (performance por semana/mês de aquisição)

🎯 **Atribuição Avançada:**
- Atribuição multi-touch (primeiro toque, último toque, linear, time-decay)
- Jornada do lead: quais touchpoints contribuíram para conversão
- ROI por criativo específico

🔔 **Automações e Alertas:**
- Alertas configuráveis (ex: "notificar quando CP SQL > R$ 2.000")
- Anomaly detection (identificação automática de outliers)
- Relatórios automáticos enviados por email (semanal/mensal)

📈 **Visualizações Adicionais:**
- Gráficos de tendência (line charts mostrando evolução temporal)
- Heatmaps de performance por dia da semana/hora do dia
- Previsões baseadas em tendências históricas

🔐 **Governança e Colaboração:**
- Permissões diferenciadas (Head vs Analista vs Viewer)
- Anotações/comentários em períodos específicos
- Histórico de decisões tomadas (audit log)

### Vision (Future)

**Visão de longo prazo (12+ meses):**

🤖 **Inteligência Artificial:**
- IA generativa para insights automáticos ("seu maior gargalo este mês é X porque Y")
- Recomendações de ação ("considere aumentar budget em LinkedIn, está com melhor CP SQL")
- Predição de resultados futuros baseada em histórico

🌐 **Expansão de Integrações:**
- Integração com outras plataformas (TikTok Ads, Twitter Ads, etc.)
- Integração com ferramentas financeiras (para cálculo automático de margem)
- API pública para integrar com outras ferramentas internas

📱 **Aplicativo Mobile Nativo:**
- App dedicado para iOS/Android
- Push notifications para alertas críticos
- Interface otimizada para acompanhamento mobile

🔄 **Real-time Streaming:**
- Atualização em tempo real (não apenas a cada hora)
- Live dashboard para acompanhamento em reuniões

## User Journeys

### Jornada 1: Renata - Head de Marketing (Usuário Primário)

**Persona:**
- **Nome:** Renata Silva, 34 anos, Head de Marketing na AwSales
- **Situação:** É segunda-feira, 8h30. Renata precisa preparar a reunião semanal de alinhamento às 10h, mas está passando quase 2 horas toda semana consolidando dados de Meta Ads, Google Ads e LinkedIn em planilhas diferentes. Pior: na semana passada, alguém editou sem querer uma célula da planilha compartilhada e o CPL do LinkedIn apareceu R$ 500 quando na verdade era R$ 1.500 — quase tomaram uma decisão errada de aumentar budget baseado em dados incorretos.
- **Obstáculo:** Dados fragmentados em múltiplas fontes, risco constante de erro humano nas planilhas, e tempo escasso para análise estratégica (passa mais tempo consolidando dados do que analisando).
- **Meta desesperadora:** Ter visibilidade clara e confiável do ROI de cada canal de ads em tempo real, para poder realocar budget de forma inteligente e provar ao CEO que o marketing está gerando resultado.

**Jornada Narrativa:**

**Cena de Abertura (Segunda, 8h30 - Antes do Dashboard):**
Renata abre 4 abas no navegador: Meta Business Suite, Google Ads, LinkedIn Campaign Manager, e a planilha compartilhada. Começa a copiar números manualmente. Percebe que os dados de sexta-feira ainda não foram atualizados por quem fez a última extração. Tensão crescente — a reunião é em 1h30 e ela nem começou a analisar os dados ainda.

**Ação Crescente (Segunda, 8h35 - Primeiro Acesso ao Dashboard):**
Renata recebe acesso ao novo AwSales Dashboard. Abre o link. Em **30 segundos**, vê a tela inicial com as métricas principais já consolidadas:
- **R$ 173.035 em Gasto de Ads** (agregado automático de Meta + Google + LinkedIn)
- **R$ 138.226 de Receita Gerada**
- **ROI 0.80x** (indicador vermelho mostrando que está abaixo da meta)
- **CP SQL: R$ 1.730** (Meta) vs **R$ 2.042** (atual) — **+41% vermelho**

Ela imediatamente vê o problema: o custo por SQL disparou este mês. Clica para expandir a seção "Números" e vê:
- LinkedIn: 47 SQLs (-11% vs mês anterior, vermelho)
- Meta: Performance caindo em qualificação

**Clímax (Segunda, 8h40 - Momento "AHA!"):**
Renata percebe que **não precisa mais consolidar dados manualmente**. O dashboard já mostra TUDO integrado, atualizado automaticamente a cada hora, e com comparação visual (vermelho/verde) que torna os gargalos óbvios. Em 5 minutos, ela já identificou que o problema não é geração de leads (número de leads subiu), mas qualificação — o % Qualified Marketing caiu de 10.23% para 9.13%.

Ela pensa: "Agora posso focar em RESOLVER o problema, não em descobrir qual é o problema."

**Resolução (Segunda, 9h50 - Nova Realidade):**
Na reunião das 10h, Renata entra com clareza total: "Nosso gargalo este mês é qualificação, não geração. Estamos gerando mais leads (+82%), mas a qualidade caiu. Vou ajustar as copy dos anúncios para atrair perfil mais qualificado e realocar 30% do budget do LinkedIn para Meta, que está com melhor CP SQL."

**Economia de tempo:** De 2h semanais para 10 minutos. **Decisão:** Baseada em dados precisos e atualizados. **Confiança:** 100% nos números, sem medo de erro manual.

---

### Jornada 2: Carlos - Head Comercial (Usuário Primário)

**Persona:**
- **Nome:** Carlos Mendes, 38 anos, Head Comercial na AwSales
- **Situação:** Carlos gerencia a equipe de vendas e precisa bater meta mensal de R$ 150K. Está na última semana do mês e percebe que está atrasado, mas não tem visibilidade clara de ONDE está o gargalo: os leads não estão qualificando? As reuniões não estão sendo agendadas? O show-up está baixo? A conversão de call para venda caiu?
- **Obstáculo:** Dados comerciais estão no CRM, mas não conectados com o que está vindo do marketing. Ele não sabe se o problema é "qualidade dos leads que marketing está gerando" ou "performance da equipe comercial na conversão".
- **Meta desesperadora:** Identificar rapidamente onde o funil comercial está travando para tomar ação corretiva e salvar a meta do mês.

**Jornada Narrativa:**

**Cena de Abertura (Terça, 14h - Antes do Dashboard):**
Carlos recebe um Slack do CEO: "Carlos, vamos bater a meta esse mês?" Ele abre o CRM, vê que tem R$ 259K em pipeline, mas não sabe quanto disso vai realmente fechar. Abre uma planilha antiga tentando calcular taxa de conversão histórica. Frustração — os dados não batem com o CRM.

**Ação Crescente (Terça, 14h10 - Descoberta do Dashboard):**
Carlos acessa o AwSales Dashboard pela primeira vez. Vê imediatamente:
- **Pipeline Total: R$ 259.425** ✅
- **Faturamento Projetado do Pipe: R$ 51.885** (+982% verde — pipeline cresceu muito)
- **Mas... Vendas: 19** (-23% vermelho — conversão caiu)

Ele expande a seção "Premissas - Comercial" e vê o problema:
- **% Agendamento: 68%** (normal, verde)
- **% Show-up: 60.29%** (normal)
- **% Fechamentos SQL: 19%** (-18% vermelho) ⚠️

**Clímax (Terça, 14h15 - Momento "AHA!"):**
Carlos vê que o problema NÃO é quantidade de reuniões ou show-up. O gargalo é **conversão de SQL para venda**. Ele expande "Deltas - Velocidade do Funil" e confirma:
- **Tempo médio reunião realizada até venda: 5.5 dias** (vs 10 dias mês anterior, +90% verde)

Insight: "Quando vendemos, vendemos rápido. Mas estamos fechando menos SQLs. O problema é qualificação ou discurso de vendas?"

Ele cruza com "Tabelas - Motivo de Perda - Perdas SQL" e vê:
- **67% das perdas: "Não é o ICP"**
- **33%: "Lead Fake"**

**Agora ele tem clareza total:** Marketing está gerando volume, mas qualidade caiu. Precisa alinhar com Renata para ajustar critérios de qualificação.

**Resolução (Terça, 15h - Ação Corretiva):**
Carlos agenda reunião urgente com Renata (Head de Marketing). Mostra o dashboard para ela: "Olha aqui, 67% das perdas de SQL são 'não é ICP'. Precisamos revisar os critérios de qualificação MQL→SQL urgentemente."

Juntos, eles ajustam o formulário de qualificação e o scoring de leads. Carlos também treina a equipe para fazer melhor discovery nas calls.

**Resultado:** Em 1 semana, % Fechamentos SQL sobe de 19% para 24%. Meta salva.

---

### Jornada 3: Marina - Analista de Marketing (Usuário Secundário)

**Persona:**
- **Nome:** Marina Costa, 27 anos, Analista de Marketing
- **Situação:** Marina apoia Renata (Head de Marketing) executando campanhas, criando anúncios e otimizando criativos. Precisa monitorar diariamente se as campanhas estão performando bem, mas não tem acesso fácil aos dados consolidados — sempre precisa pedir para Renata ou esperar o relatório semanal.
- **Obstáculo:** Dependência da Head para ter visão dos números. Não consegue ser proativa porque só vê os dados quando já é tarde demais.
- **Meta:** Ter autonomia para monitorar performance das campanhas em tempo real e fazer ajustes rápidos (pausar anúncios ruins, escalar anúncios bons) sem depender de aprovação/relatório.

**Jornada Narrativa:**

**Cena de Abertura (Quarta, 10h - Antes do Dashboard):**
Marina lança uma nova campanha no Meta Ads na segunda. É quarta e ela ainda não sabe se a campanha está performando bem. Envia mensagem para Renata: "Rê, consegue me passar o CPL da campanha nova?" Renata responde: "Daqui a pouco te passo, estou em reunião."

Marina fica bloqueada. A campanha pode estar queimando budget em anúncios ruins e ela não sabe.

**Ação Crescente (Quarta, 11h - Acesso ao Dashboard):**
Renata dá acesso ao dashboard para Marina também. Marina acessa e vê:
- **CP Lead hoje: R$ 100** (vs R$ 72 mês passado, +39% vermelho) ⚠️

Ela clica em "Números" e vê:
- **# Lead hoje: 1.730** (vs 1.065 mês anterior, +62% verde)

**Clímax (Quarta, 11h05 - Autonomia):**
Marina percebe: "Estamos gerando MAIS leads, mas o custo subiu. Talvez seja a nova campanha." Ela abre o Meta Ads Manager e cruza os dados. Confirma: a nova campanha tem CPL de R$ 150 (muito acima da média).

Ela imediatamente pausa os 2 anúncios com pior performance e escala o anúncio com melhor CPL.

**Resolução (Quarta, 17h - Proatividade):**
No final do dia, Marina atualiza Renata: "Identifiquei que a nova campanha estava com CPL alto. Já pausei os anúncios ruins e escalei o melhor. CPL voltou para R$ 85."

Renata responde: "Ótimo, Marina! Adoro ter você sendo proativa assim."

**Transformação:** Marina passou de "executora dependente" para "analista autônoma e proativa". Dashboard democratizou o acesso aos dados.

---

### Jornada 4: Pedro - Analista Comercial/SDR Manager (Usuário Secundário)

**Persona:**
- **Nome:** Pedro Alves, 31 anos, SDR Manager
- **Situação:** Pedro gerencia o time de SDRs (qualificadores) que recebem os leads de marketing e qualificam para SQL. Precisa garantir que os SDRs estão qualificando rápido e com qualidade, mas não tem visão consolidada de velocidade e taxa de conversão MQL→SQL.
- **Obstáculo:** Não sabe se a queda em SQLs é porque os leads de marketing estão piores OU porque os SDRs estão qualificando mal.
- **Meta:** Identificar se o problema está no input (qualidade dos MQLs) ou no processo (performance dos SDRs), para poder treinar/cobrar a equipe ou escalar com marketing.

**Jornada Narrativa:**

**Cena de Abertura (Quinta, 9h - Antes do Dashboard):**
Pedro vê que o número de SQLs caiu 11% este mês. Ele não sabe por quê. Abre o CRM e tenta fazer queries manuais. Quanto tempo os SDRs estão levando para qualificar? A taxa de conversão MQL→SQL caiu?

Frustração — o CRM não mostra isso de forma clara.

**Ação Crescente (Quinta, 9h15 - Descobre o Dashboard):**
Carlos (Head Comercial) compartilha o dashboard com Pedro. Ele acessa e vai direto para:
- **Deltas - Velocidade do Funil:**
  - **Tempo médio MQL até SQL: 2 dias** (vs 4 dias mês anterior, +100% verde!) ✅

Pedro pensa: "Os SDRs estão qualificando MAIS RÁPIDO. Então o problema não é velocidade."

Ele olha para:
- **Premissas - % Qualified Marketing: 9.13%** (vs 10.23% mês anterior, -21% vermelho) ⚠️

**Clímax (Quinta, 9h20 - Clareza Total):**
Pedro entende: "O problema NÃO é meu time de SDRs. Eles estão qualificando mais rápido e mantendo boa taxa de conversão MQL→SQL (63.29%, verde). O problema é que marketing está gerando mais VOLUME mas menos QUALIDADE de MQLs."

Ele cruza com "Tabelas - Perdas MQL" e confirma:
- **53% das perdas MQL: "Não é o ICP"**

**Resolução (Quinta, 10h - Defesa do Time + Alinhamento):**
Pedro agenda reunião com Renata e Carlos. Mostra o dashboard: "Pessoal, meu time está performando bem. O problema é qualidade dos MQLs que estão vindo. Precisamos ajustar o scoring de lead no formulário."

Resultado: Em vez de ser cobrado injustamente, Pedro usa dados para defender seu time E propor solução construtiva.

**Transformação:** Pedro passou de "gerente na defensiva" para "gestor estratégico baseado em dados".

---

### Jornada 5: Roberto - CEO/C-Level (Usuário Executivo)

**Persona:**
- **Nome:** Roberto Fernandes, 45 anos, CEO da AwSales
- **Situação:** Roberto investe R$ 150K+/mês em marketing e precisa saber se esse investimento está gerando retorno. Não tem tempo para analisar dezenas de métricas — precisa de uma visão macro e clara: "Estamos crescendo? O ROI está saudável? Onde está o gargalo?"
- **Obstáculo:** Renata e Carlos trazem relatórios diferentes, às vezes conflitantes. Difícil ter visão unificada de RevOps (Marketing + Comercial integrados).
- **Meta:** Ter visão executiva clara em 2 minutos: ROI, margem, pipeline, e principais gargalos operacionais.

**Jornada Narrativa:**

**Cena de Abertura (Sexta, 7h - Antes do Dashboard):**
Roberto toma café enquanto abre o email. Vê relatório de Renata (marketing) e Carlos (comercial). Os números não batem: Renata diz que gerou 158 MQLs, Carlos diz que recebeu 142 MQLs. Quem está certo?

Ele agenda reunião: "Precisamos alinhar os números."

**Ação Crescente (Sexta, 8h - Primeiro Acesso ao Dashboard):**
Roberto acessa o AwSales Dashboard pela primeira vez. Vê imediatamente a seção "Principal":
- **R$ 138.226 Receita Gerada** (-37% vermelho) ⚠️
- **R$ 173.035 Gasto em Ads** (+24% vermelho) ⚠️
- **ROI: 0.80x** (-50% vermelho) ⚠️⚠️⚠️
- **R$ 114.727 Margem de Contribuição** (-37% vermelho)

Roberto franze a testa. Situação ruim. Mas agora ele vê o problema claramente: **gastamos mais, vendemos menos, ROI caiu**.

Ele scrolla para "Premissas" e identifica o gargalo:
- **% Qualified Marketing: 9.13%** (caiu)
- **% Fechamentos SQL: 19%** (caiu)

**Clímax (Sexta, 8h05 - Decisão Estratégica):**
Roberto vê tudo integrado em uma fonte única. Não precisa mais de reunião de alinhamento de números. Os dados são claros, unificados e confiáveis.

Ele anota decisões:
1. Revisar qualidade dos leads (qualificação de marketing caindo)
2. Treinar equipe comercial (conversão SQL→Venda caindo)
3. Cortar budget de canais com CP SQL alto até performance normalizar

**Resolução (Sexta, 9h - Reunião de Liderança):**
Roberto chama Renata e Carlos. Abre o dashboard na TV da sala de reunião: "Pessoal, temos clareza total agora. Nossos 2 gargalos são: qualificação de leads e conversão comercial. Aqui está o plano..."

Renata e Carlos alinham imediatamente — todos olhando os MESMOS dados, na MESMA tela. Zero conflito de números.

**Transformação:** Roberto passou de "CEO frustrado com relatórios conflitantes" para "líder estratégico tomando decisões baseadas em fonte única da verdade".

---

### Journey Requirements Summary

Essas 5 jornadas de usuário revelam os seguintes requisitos funcionais essenciais:

**Capacidades Essenciais:**

1. **Visualização Consolidada de Métricas**
   - Todas as 40+ métricas em uma página (Principal, Premissas, Números, Financeiro, Deltas, Perdas)
   - Agregação automática de múltiplas fontes (Meta + Google + LinkedIn)

2. **Comparação Temporal com Indicadores Visuais**
   - Período atual vs período anterior
   - Indicadores vermelho/verde para deltas
   - Percentuais de variação claros

3. **Filtros de Período**
   - Por ano, mês, multi-mês, semanas
   - Possibilidade de comparar períodos customizados

4. **Seções Organizadas e Colapsáveis**
   - Navegação intuitiva entre categorias de métricas
   - Cards destacados para métricas principais

5. **Velocidade de Funil (Deltas)**
   - Tempo médio entre etapas do funil
   - Identificação de gargalos de velocidade

6. **Análise Qualitativa (Motivos de Perda)**
   - Tabelas de perda por etapa do CRM
   - Identificação de padrões de perda

7. **Acesso Multi-Usuário**
   - Heads (visão completa para decisão estratégica)
   - Analistas (visão para execução tática e proatividade)
   - C-Level (visão macro executiva)

8. **Atualização Automatizada**
   - Dados atualizados a cada hora
   - Timestamp de última atualização visível

9. **Interface Responsiva**
   - Desktop (prioridade)
   - Mobile (para consultas rápidas)

10. **Governança de Dados**
    - Dados não-editáveis manualmente
    - Fonte única da verdade protegida

## Web App Specific Requirements

### Project-Type Overview

O AwSales Dashboard é uma **Single Page Application (SPA)** desenvolvida em React 19.2.4 + Vite 8.0.2, conectada ao Supabase como backend. A aplicação é um dashboard interno autenticado, focado em fornecer visibilidade unificada de dados de RevOps para usuários autorizados da equipe AwSales.

**Características principais:**
- SPA interativa com navegação fluida sem recarregamento de página
- Dashboard de visualização de dados (não transacional)
- Uso interno (não público)
- Atualização de dados via batch horário

### Technical Architecture Considerations

#### Arquitetura Frontend

**Stack Tecnológico:**
- **React 19.2.4** - Framework JavaScript para UI interativa
- **Vite 8.0.2** - Build tool e dev server (porta 3000)
- **JavaScript (ESM)** - Sem TypeScript, apenas JS/JSX puro
- **CSS Variables** - Tema dark mode com variáveis CSS customizáveis

**Padrões de Implementação:**
- Componentes funcionais apenas (sem class components)
- Hooks para gerenciamento de estado (useState, useEffect, useMemo, useCallback)
- React.StrictMode habilitado
- Vite HMR (Hot Module Replacement) para desenvolvimento

#### Arquitetura Backend & Dados

**Supabase:**
- PostgreSQL como database
- Supabase Auth para autenticação
- APIs RESTful auto-geradas
- Real-time subscriptions (se necessário no futuro)

**Pipeline de Dados:**
- **n8n** - Workflows automatizados que extraem dados das APIs (Meta Ads, Google Ads, LinkedIn Ads, CRM)
- **Batch horário** - Atualização de dados a cada hora
- **Supabase Database** - Armazenamento centralizado (~111MB, 57K registros, 16 tabelas)

### Browser Support Matrix

**Navegadores Suportados:**
- Chrome/Chromium (versão atual e anterior)
- Firefox (versão atual e anterior)
- Safari (versão atual e anterior)
- Edge (versão atual e anterior)

**Requisitos Técnicos:**
- Suporte a ES6+ (arrow functions, destructuring, async/await)
- CSS Variables (para tema dark mode)
- Fetch API (para chamadas HTTP)

**Não suportado:**
- Internet Explorer (descontinuado)
- Navegadores antigos sem suporte a ES6

### Performance Targets

**Carga Inicial:**
- **Tempo máximo:** 60 segundos para carregar dashboard completo com todas as métricas
- **Métrica:** Time to Interactive (TTI) < 60s
- **Estratégia:** Lazy loading de seções não-críticas se necessário

**Interatividade:**
- **Transições:** Imediatas (< 300ms) para navegação entre seções
- **Filtros:** Resposta instantânea (< 300ms) ao aplicar filtros de período
- **Expansão/colapso de seções:** Animação fluida (< 200ms)

**Atualização de Dados:**
- **Frequência:** A cada hora (batch via n8n)
- **Indicador:** Timestamp visível de última atualização
- **Não requer:** WebSockets ou polling em tempo real

**Otimizações:**
- Memoização de cálculos pesados (useMemo)
- Callbacks memoizados (useCallback) para evitar re-renders
- Queries otimizadas ao Supabase

### Responsive Design Strategy

**Desktop (Prioridade):**
- Layout otimizado para telas >= 1280px
- Todas as métricas visíveis em uma página com scroll
- Cards organizados em grid responsivo

**Mobile (Suporte Básico):**
- Layout adaptado para telas < 768px
- Seções empilhadas verticalmente
- Cards ajustados para largura mobile
- Funcionalidade completa mantida

**Viewport:**
- Meta viewport com escala 0.8 (conforme project-context.md)
- Design responsivo usando media queries

### Security Requirements

**Autenticação:**
- **Supabase Auth** para login/logout
- Apenas usuários autenticados podem acessar o dashboard
- Credenciais obrigatórias (email + senha)

**Autorização:**
- **Modelo simples:** Usuário autenticado = acesso total aos dados
- Sem permissões granulares (todos os usuários autorizados veem os mesmos dados)

**Proteção de Dados:**
- **Supabase RLS (Row Level Security):** Recomendado configurar políticas de acesso
- **API Keys:**
  - Anon key no frontend (seguro para exposição pública)
  - Service role key apenas no backend (n8n), nunca no frontend
- **Sem whitelist de IPs:** Acesso permitido de qualquer local com credenciais válidas

**Considerações Futuras:**
- **Rate Limiting:** Não implementado no MVP, pode ser adicionado se houver abuso
- **Audit Log:** Não implementado no MVP, considerar para rastreabilidade futura
- **2FA (Two-Factor Authentication):** Não implementado no MVP

### Accessibility Level

**Nível de Acessibilidade:**
- **Básico** - Uso interno, sem requisitos WCAG rigorosos
- Contraste de cores adequado (dark mode já implementado)
- Navegação por teclado funcional
- Labels descritivos em formulários

**Não Requerido no MVP:**
- Conformidade WCAG AA ou AAA
- Leitores de tela otimizados
- Modo alto contraste adicional

### Implementation Considerations

**Estrutura de Código:**
- Componentes em `Dash AwSales/` directory
- Services em arquivos separados (ex: `dataService.js`)
- Supabase client configurado em `supabaseClient.js`
- Um componente principal por arquivo

**Gerenciamento de Estado:**
- Estado local com useState para UI
- Session state gerenciado no App.jsx
- Prop drilling para passar dados (sem Context API no MVP)

**Integração com Supabase:**
- Queries assíncronas com try-catch
- Loading states explícitos
- Tratamento de erros com mensagens user-friendly

**Build & Deploy:**
- Build com `npm run build` ou `vite build`
- Output em `dist/` directory
- Preview com `npm run preview`

**Considerações de Desenvolvimento:**
- Todos os textos de UI em **Português (pt-BR)**
- Comentários de código em Português
- Formatação de números e datas em padrão brasileiro
- Moeda em R$ com `toLocaleString('pt-BR')`

## Data Model Requirements

> **✅ Seção 100% Validada em 2026-03-25**
>
> - ✅ DDL validado contra banco de dados real
> - ✅ Stage IDs confirmados via Pipedrive API
> - ✅ Custom Fields documentados via Pipedrive API
> - ✅ Definição de "View Page" confirmada (Meta Ads + Google Ads)
>
> **⚠️ ATENÇÃO:** Discrepância crítica identificada entre código (`dataService.js`) e Pipedrive real.
> Ver [RESULTADOS-VALIDACAO.md](RESULTADOS-VALIDACAO.md) e [DISCREPANCIAS-CRITICAS.md](DISCREPANCIAS-CRITICAS.md) para detalhes.

### Database Schema

O AwSales Dashboard utiliza um banco de dados PostgreSQL no Supabase com **16 tabelas principais** contendo aproximadamente **111MB de dados** e **57.064 registros**.

**Arquitetura de Dados:**
- **Banco:** PostgreSQL 15+ no Supabase
- **ETL:** n8n workflows com batch horário + webhooks real-time
- **Agregação:** Frontend (dataService.js) - queries individuais + agregação em JavaScript
- **Autenticação:** Supabase Auth + RLS (Row Level Security) habilitado em todas as tabelas

#### Tabelas Principais

**1. `sales` - Vendas Fechadas**
- **Propósito:** Armazena todas as vendas concretizadas com informação de receita gerada
- **Campos principais:**
  - `id` (bigint) - Identificador único
  - `receita_gerada` (numeric) - Valor da receita em R$
  - `data_fechamento` (timestamp) - Data do fechamento da venda
  - `status` (text) - Status da venda ("Won", "Churn")
  - `email_pipedrive` (text) - Email do cliente no CRM Pipedrive
  - `email_stripe` (text) - Email do cliente na plataforma de pagamento
- **Regras de negócio:**
  - Receita Total = SUM(`receita_gerada`) WHERE `data_fechamento` no período
  - Vendas = COUNT(*) WHERE `data_fechamento` no período
  - Ticket Médio = Receita Total / Vendas
  - Churn = SUM(`receita_gerada`) WHERE `status` = "Churn"
  - Margem de Contribuição = Receita - (Receita * 0.17) - Churn

**2. `meta_ads_costs` - Custos de Anúncios Meta (Facebook/Instagram)**
- **Propósito:** Custos diários de campanhas no Meta Ads
- **Campos principais:**
  - `spend` (numeric) - Valor gasto em R$
  - `impressions` (bigint) - Número de impressões
  - `date_start` (date) - Data do registro
- **Agregação:** Gasto em Ads = SUM(`spend`) por período

**3. `google_ads_costs` - Custos de Anúncios Google**
- **Propósito:** Custos diários de campanhas no Google Ads
- **Campos principais:**
  - `spend` (numeric) - Valor gasto em R$
  - `impressions` (bigint) - Número de impressões
  - `clicks` (bigint) - Número de cliques
  - `conversions` (bigint) - Número de conversões (view page)
  - `date` (date) - Data do registro
- **Agregação:** Gasto em Ads = SUM(`spend`), Cliques = SUM(`clicks`), View Page = SUM(`conversions`)

**4. `meta_ads_actions` - Ações de Anúncios Meta**
- **Propósito:** Ações de usuários nos anúncios Meta (cliques, view page)
- **Campos principais:**
  - `action_type` (text) - Tipo de ação ("unique_outbound_outbound_click", "landing_page_view")
  - `value` (bigint) - Quantidade de ações
  - `date_start` (date) - Data do registro
- **Regras de negócio:**
  - Cliques = SUM(`value`) WHERE `action_type` = "unique_outbound_outbound_click"
  - View Page (Meta Ads) = SUM(`value`) WHERE `action_type` = "landing_page_view"
  > ✅ **VALIDADO em 2026-03-25:** Definição oficial confirmada
  > - **View Page = Meta Ads `landing_page_view` + Google Ads `conversions`**
  > - Representa pessoas que **chegaram na landing page** após clicar no anúncio
  > - Captura tráfego pago de múltiplas fontes (Meta + Google)
  > - Alinhado com funil de marketing digital padrão

**5. `yayforms_responses` - Respostas do Formulário de Qualificação**
- **Propósito:** Leads capturados através do formulário de qualificação
- **Campos principais:**
  - `submitted_at` (timestamp) - Data/hora de submissão
  - `lead_email` (text) - Email do lead
  - `lead_revenue_range` (text) - Faixa de faturamento anual
  - `lead_monthly_volume` (text) - Volume mensal de tickets
  - `lead_segment` (text) - Segmento de mercado
- **Regras de qualificação MQL:**
  - **Desqualificado (Lead)** se:
    - `lead_revenue_range` IN ("Zero até o momento", "Menos de R$100 mil", "Entre R$100 mil e R$500 mil", "Entre R$500 mil e R$1 milhão")
    - OU `lead_segment` IN ("🩺 Clínica / consultório", "⚖️ Escritório de advocacia")
    - OU `lead_monthly_volume` IN ("Menos de 1.000 por mês", "Entre 1.000 e 3.000 por mês", "Entre 1.000 e 5.000 por mês")
  - **Qualificado (MQL)** se:
    - `lead_revenue_range` IN ("Entre R$1 milhão a R$5 milhões", "Entre R$5 milhões a R$10 milhões", "Entre R$10 milhões a R$25 milhões", "Entre R$25 milhões a R$50 milhões", "Acima de R$50 milhões", "Acima de R$10 milhões")
- **Agregação:**
  - # Lead = COUNT(*)
  - # MQL = COUNT(*) com regras de qualificação aplicadas

**6. `crm_deals` - Negócios do CRM (Pipedrive)**
- **Propósito:** Pipeline de vendas com todas as etapas do funil comercial
- **Campos principais:**
  - `deal_id` (bigint) - ID do deal no Pipedrive
  - `deal_created_at` (timestamp) - Data de criação do deal
  - `stage_id` (bigint) - ID da etapa atual
  - `pipeline_id` (bigint) - ID do pipeline
  - `status` (text) - Status do deal ("open", "won", "lost")
  - `value` (numeric) - Valor do deal em R$
  - `custom_fields` (jsonb/text) - Campos personalizados (pode vir como JSON ou string)
  - `person_email` (text) - Email do contato
  - `won_time` (timestamp) - Data de fechamento (se ganho)
  - `lost_reason` (text) - Motivo da perda (se perdido)
- **Stage IDs (Etapas do Funil):**
  > ✅ **VALIDADO via Pipedrive API em 2026-03-25** - Ver [RESULTADOS-VALIDACAO.md](RESULTADOS-VALIDACAO.md)
  >
  > ⚠️ **DISCREPÂNCIA CRÍTICA IDENTIFICADA:** O código atual (`dataService.js`) usa stage IDs **INCORRETOS**:
  > - ❌ Stage 3 não é MQL (é "Reunião Ag.")
  > - ❌ Stage 4 não é SQL (é "Proposta feita")
  > - ❌ Stage 6 não é Reunião (é "Reagendamento Pendente")
  > - ❌ Stage 7 não existe
  >
  > **Mapeamento CORRETO (validado no Pipedrive):**
  - **MQL (Marketing Qualified Lead):**
    - Stage 1 (Pipeline 1 - Geral): "👤 Lead (MQL)"
    - Stage 49 (Pipeline 9 - Inbound SDR): "👤 Lead (MQL)"
  - **SQL (Sales Qualified Lead):**
    - Stage 19 (Pipeline 1 - Geral): "👤 Lead Qualificado (SQL)"
    - Stage 50 (Pipeline 9 - Inbound SDR): "👤 Lead Qualificado (SQL)"
  - **Reunião Agendada:**
    - Stage 3 (Pipeline 1 - Geral): "🗓️ Reunião Ag."
    - Stage 45 (Pipeline 8 - Inbound Closer): "🗓️ Reunião Ag. (Confirmada)"
    - Stage 51 (Pipeline 9 - Inbound SDR): "🗓️ Reunião Ag. (Incerto)"
    - Stage 27 (Pipeline 5 - Indicação Closer): "🗓️ Reunião Ag. (Confirmada)"
    - Stage 37 (Pipeline 7 - Prospecção Ativa): "🗓️ Reunião Agendada"
  - **Proposta Feita / Negociação:**
    - Stage 4 (Pipeline 1 - Geral): "🧾 Proposta feita"
    - Stage 46 (Pipeline 8 - Inbound Closer): "🧾 Proposta feita"
    - Stage 29 (Pipeline 5 - Indicação Closer): "🧾 Proposta feita"
    - Stage 39 (Pipeline 7 - Prospecção Ativa): "🧾 Proposta feita"
  - **Contrato Enviado:**
    - Stage 47 (Pipeline 8 - Inbound Closer): "✍️ Contrato Enviado"
    - Stage 41 (Pipeline 1 - Geral): "Contrato Enviado"
- **Custom Fields (dentro do campo `custom_fields`):**
  > ✅ **VALIDADO via Pipedrive API em 2026-03-25** - Ver [RESULTADOS-VALIDACAO.md](RESULTADOS-VALIDACAO.md)

  **1. SQL? (Field ID: 80)**
  - Hash: `2e17191cfb8e6f4a58359adc42a08965a068e8bc`
  - Tipo: enum (Single Option)
  - Valores possíveis:
    - **"75"** = "Sim" ✅ (usado no código)
    - "76" = "Não"
    - "79" = "A revisar"
  - Uso: `isSQL = customFields[hash] == '75'`

  **2. Data Reunião (Field ID: 46)**
  - Hash: `8eff24b00226da8dfb871caaf638b62af68bf16b`
  - Tipo: date (formato YYYY-MM-DD)
  - Uso: `agendamentoDate = customFields[hash]`

  **3. Reunião Realizada (Field ID: 74)**
  - Hash: `baf2724fcbeec84a36e90f9dc3299431fe1b0dd3`
  - Tipo: enum (Single Option)
  - Valores possíveis:
    - **"47"** = "Sim" ✅ (usado no código)
    - "59" = "Não"
  - Uso: `reuniaoRealizada = customFields[hash] == '47'`
- **Regras de negócio:**
  - Pipeline Total = SUM(`value`) WHERE `stage_id` = 46
  - Faturamento Projetado = Pipeline Total * 0.20
  - Receita Projetada = Receita Gerada + Faturamento Projetado
  - # SQL = COUNT(*) WHERE custom_field SQL = '75'
  - # Reuniões Agendadas = COUNT(*) WHERE campo agendamento não-vazio
  - # Reuniões Realizadas = COUNT(*) WHERE custom_field reunião realizada = '47'
- **Motivos de Perda (por etapa):**
  - Perdas MQL: `status` = "lost" AND `stage_id` IN (1, 3, 49)
  - Perdas SQL: `status` = "lost" AND `stage_id` IN (4, 50)
  - Perdas Proposta: `status` = "lost" AND `stage_id` = 47
- **⚠️ Limitação Conhecida:**
  - Tabela `sales` não tem FK para `crm_deals`
  - Correlação usa email matching (`sales.email_pipedrive` = `crm_deals.person_email`)
  - Pode haver divergências se emails não coincidirem

**7. `crm_stage_transitions` - Transições Entre Etapas do CRM**
- **Propósito:** Rastreamento de tempo de permanência em cada etapa do funil
- **Campos principais:**
  - `deal_id` (bigint) - ID do deal
  - `to_stage_id` (bigint) - Etapa para qual transitou
  - `time_in_previous_stage_sec` (bigint) - Tempo na etapa anterior (em segundos)
- **Uso para Deltas de Velocidade:**
  - **MQL → SQL:** Transição para stage_id IN (4, 50)
  - **SQL → Reunião:** Transição para stage_id IN (6, 7, 45)
- **Cálculo:** `time_in_previous_stage_sec` / (60 * 60 * 24) = dias

**8-16. Outras Tabelas (Meta Ads, Google Ads, LinkedIn Ads detalhadas)**
- Tabelas adicionais com granularidade de campanha/anúncio para drill-downs futuros
- Não utilizadas no MVP (preparação para Growth Features)

### Data Aggregation Logic

**Agregação Temporal:**
- Dashboard agrupa dados por **mês** e por **semana** (4 semanas por mês)
- Função `getMonthKey(dateStr)` extrai ano-mês (formato: "2026-mar")
- Função `getWeekKey(dateStr)` extrai semana do mês (s1, s2, s3, s4)

**Cálculos Derivados:**

```javascript
// ROI = Receita Gerada / Gasto em Ads
roi = receita / gastoAds

// Margem de Contribuição = Receita - (17% imposto) - Churn
margemContribuicao = receita - (receita * 0.17) - churn

// Ticket Médio = Receita / Vendas
ticketMedio = receita / vendas

// Premissas de Conversão
CTR = cliques / impressoes
ConnectRate = viewPage / cliques
ConversaoPaginaCaptura = leads / viewPage
QualifiedMarketing = mql / leads
QualifiedSales = sql / mql
Agendamento = reunioesAgendadas / sql
ShowUp = reunioesRealizadas / reunioesAgendadas
FechamentoCall = vendas / reunioesRealizadas
FechamentoSQL = vendas / sql

// Custos por Etapa
cpLead = gastoAds / leads
cpMQL = gastoAds / mql
cpSQL = gastoAds / sql
cpReuniaoAgendada = gastoAds / reunioesAgendadas
cpReuniaoRealizada = gastoAds / reunioesRealizadas
cpVenda = gastoAds / vendas
```

**Deltas de Velocidade (Tempo Médio):**
- **MQL → SQL:** Média de `time_in_previous_stage_sec` das transições para stage_id 4 ou 50
- **SQL → Reunião:** Média de `time_in_previous_stage_sec` das transições para stage_id 6, 7 ou 45
- **Reunião → Venda:** Diferença em dias entre data de agendamento e `data_fechamento` em `sales`
- **Lead → Venda:** Diferença em dias entre `deal_created_at` e `data_fechamento` em `sales`

**Motivos de Perda (Top 3):**
- Agrupa `lost_reason` por etapa (MQL, SQL, Proposta)
- Calcula percentual de cada motivo sobre total de perdas
- Retorna top 3 motivos ordenados por frequência

### Data Relationships

**Email como Chave de Correlação:**
- `yayforms_responses.lead_email` → `crm_deals.person_email` → `sales.email_pipedrive` ou `sales.email_stripe`
- Permite rastrear jornada completa do lead até venda
- Usado para calcular deltas de tempo entre etapas

**Deal ID como Chave:**
- `crm_deals.deal_id` → `crm_stage_transitions.deal_id`
- Permite rastrear histórico de transições de cada negócio

**Data como Filtro Temporal:**
- Todas as tabelas têm campo de data (timestamp ou date)
- Agregação por período (mês/semana) usa esse campo
- Comparações temporais (período atual vs anterior) calculadas no frontend

### Data Quality Considerations

**Dados Faltantes:**
- Campos opcionais devem ter tratamento de `null` ou valores vazios
- Default para números: `0`
- Default para arrays: `[]`
- Custom fields podem vir como string JSON ou objeto (necessário parsing)

**Consistência de Emails:**
- Emails devem ser normalizados (lowercase, trim) antes de comparação
- Múltiplos emails por venda (`email_pipedrive` vs `email_stripe`) requerem fallback

**Formato de Datas:**
- Diferentes tabelas podem ter formatos diferentes (timestamp vs date)
- Função `new Date()` deve validar parsing
- Timezone UTC usado para consistência

**Validação de Stage IDs:**
- Stage IDs específicos mapeiam para etapas do funil
- Mudanças no Pipedrive podem invalidar mapeamentos (risco operacional)

## API/Integration Requirements

### Supabase API

**Autenticação:**
- **Supabase Auth** via email + senha
- Session JWT gerenciada automaticamente pelo `@supabase/supabase-js`
- Anon key exposta no frontend (segura para uso público)

**Queries Principais:**

```javascript
// 1. Fetch all sales
supabase.from('sales').select('id, receita_gerada, data_fechamento, status, email_pipedrive, email_stripe')

// 2. Fetch Meta Ads costs
supabase.from('meta_ads_costs').select('spend, impressions, date_start')

// 3. Fetch Google Ads costs
supabase.from('google_ads_costs').select('spend, impressions, clicks, conversions, date')

// 4. Fetch Meta Ads actions
supabase.from('meta_ads_actions').select('action_type, value, date_start')

// 5. Fetch leads
supabase.from('yayforms_responses').select('submitted_at, lead_email, lead_revenue_range, lead_monthly_volume, lead_segment')

// 6. Fetch CRM deals
supabase.from('crm_deals').select('deal_created_at, stage_id, status, value, custom_fields, person_email, won_time, deal_id, lost_reason')

// 7. Fetch stage transitions
supabase.from('crm_stage_transitions').select('deal_id, to_stage_id, time_in_previous_stage_sec')
```

**Paginação:**
- Queries com `.range(from, to)` para lidar com grande volume de dados
- Batch size: 1000 registros por requisição
- Loop até `data.length < batch_size`

**Error Handling:**
- Try-catch em todas as queries assíncronas
- Log de erros com `console.error`
- Mensagens user-friendly no frontend
- Loading states durante fetch

### External APIs (via n8n)

O dashboard **não** faz chamadas diretas às APIs externas. Todas as integrações são gerenciadas pelo **n8n** (plataforma de automação de workflows) que:

**1. Meta Ads API**
- **Frequência:** Batch horário (a cada hora)
- **Dados extraídos:**
  - Custos diários (`spend`, `impressions`)
  - Ações de usuários (`clicks`, `landing_page_view`)
- **Destino:** Supabase tabelas `meta_ads_costs` e `meta_ads_actions`

**2. Google Ads API**
- **Frequência:** Batch horário
- **Dados extraídos:**
  - Custos diários (`spend`, `impressions`, `clicks`, `conversions`)
- **Destino:** Supabase tabela `google_ads_costs`

**3. LinkedIn Ads API**
- **Frequência:** Batch horário
- **Dados extraídos:** Similar ao Meta/Google (custos e ações)
- **Destino:** Tabelas específicas do LinkedIn (não detalhadas no MVP)

**4. YayForms API (Formulário de Qualificação)**
- **Frequência:** Webhook em tempo real + batch horário (backup)
- **Dados extraídos:** Respostas do formulário com email, faturamento, volume, segmento
- **Destino:** Supabase tabela `yayforms_responses`

**5. Pipedrive CRM API**
- **Frequência:** Webhook em tempo real + batch horário (backup)
- **Dados extraídos:**
  - Deals com campos personalizados
  - Transições entre stages
- **Destino:** Supabase tabelas `crm_deals` e `crm_stage_transitions`

**6. Stripe API (Pagamentos)**
- **Frequência:** Webhook em tempo real
- **Dados extraídos:** Vendas concretizadas com valores
- **Destino:** Supabase tabela `sales`

**Responsabilidades do n8n:**
- Autenticação com APIs externas (API keys, OAuth)
- Transformação de dados (mapeamento de campos)
- Deduplicação de registros
- Tratamento de rate limits
- Retry logic em caso de falhas
- Monitoramento e alertas de pipeline

**Responsabilidades do Dashboard:**
- **Apenas leitura** do Supabase
- Agregação e cálculo de métricas derivadas
- Visualização e comparação temporal

### Data Refresh Strategy

**Frequência de Atualização:**
- **n8n → Supabase:** A cada hora (batch job)
- **Dashboard → Supabase:** On-demand (quando usuário acessa ou recarrega)
- **Não requerido:** Polling, WebSockets ou real-time subscriptions

**Indicador de Atualização:**
- Timestamp de "última atualização" deve ser visível no dashboard
- Calculado como timestamp de execução do último batch n8n
- Armazenado em tabela de controle ou inferido do registro mais recente

**Cache Strategy:**
- Dados agregados calculados no frontend (não persistidos)
- Re-cálculo a cada carregamento da página
- Futuro: cache no backend (Supabase Functions) se performance degradar

### Rate Limits & Quotas

**Supabase:**
- Free tier: 500MB storage, 2GB bandwidth/mês
- Projeto atual: 111MB (~22% do limite)
- **Risco:** Crescimento de dados pode exceder free tier
- **Mitigação:** Monitorar uso mensal, migrar para plano pago se necessário

**APIs Externas (gerenciadas pelo n8n):**
- Meta Ads: Rate limits específicos por app
- Google Ads: 15.000 requisições/dia (padrão)
- Pipedrive: Rate limits por plano contratado
- **Responsabilidade:** n8n deve implementar retry e backoff

### Security & Authentication

**Supabase RLS (Row Level Security):**
- Recomendado: Policies de acesso limitando leitura a usuários autenticados
- Implementação futura: Policies por tabela

**API Keys:**
- **Anon key:** Segura para exposição no frontend (limitada por RLS)
- **Service role key:** Apenas no n8n (acesso total, não expor no frontend)

**n8n Credentials:**
- API keys das plataformas externas armazenadas de forma segura no n8n
- Não expor credentials no código do dashboard

## Open Questions

### Technical Decisions

**1. Autenticação Multi-Usuário**
- **Questão:** Como gerenciar usuários no Supabase Auth?
  - Criar contas manualmente pelo admin do Supabase?
  - Implementar tela de signup (com aprovação manual)?
  - Usar OAuth (Google, Microsoft) para simplificar login?
- **Recomendação:** Criar contas manualmente por enquanto (apenas 2-5 usuários primários)
- **Decisão futura:** Avaliar OAuth se base de usuários crescer

**2. Histórico de Dados**
- **Questão:** Quanto tempo de histórico manter no Supabase?
  - Manter todos os dados desde o início (crescimento ilimitado)?
  - Arquivar dados antigos após X meses?
- **Risco:** Dados históricos ocupam storage e podem tornar queries lentas
- **Recomendação MVP:** Manter todo histórico (volume ainda gerenciável)
- **Decisão futura:** Implementar arquivamento se storage ultrapassar 500MB

**3. Backup e Disaster Recovery**
- **Questão:** Como garantir backup dos dados do Supabase?
  - Supabase tem backup automático?
  - Necessário backup manual adicional?
- **Ação:** Verificar política de backup do plano Supabase atual
- **Recomendação:** Configurar backup semanal manual se plano free não incluir

**4. Performance com Crescimento de Dados**
- **Questão:** Dashboard carrega todas as tabelas em memória para agregação. Isso escala?
  - Atual: ~57K registros, carregamento em <60s
  - Futuro: 500K+ registros?
- **Risco:** Queries podem ficar lentas, browser pode travar
- **Mitigação futura:** Mover agregação para backend (Supabase Functions ou Views)
- **Decisão MVP:** Aceitar arquitetura atual, monitorar performance

**5. Timezone e Horário de Atualização**
- **Questão:** Dados agregados por data — qual timezone usar?
  - UTC (padrão do Supabase)?
  - America/Sao_Paulo (local dos usuários)?
- **Impacto:** Dados do final do dia podem cair no dia seguinte se timezone diferir
- **Recomendação:** Padronizar UTC em toda stack (n8n, Supabase, Dashboard)
- **Ação:** Validar que n8n está usando UTC ao inserir dados

### Business Logic Clarifications

**6. Regras de Qualificação MQL**
- **Questão:** As regras de qualificação estão hardcoded no dataService.js. Quem pode alterar?
  - Apenas dev via código?
  - Head de Marketing deveria ter autonomia para ajustar?
- **Risco:** Mudanças frequentes nos critérios exigem deploy
- **Decisão futura:** Considerar UI de configuração de regras (post-MVP)

**7. Cálculo de Margem de Contribuição**
- **Questão:** Margem = Receita - (17% impostos) - Churn
  - 17% é fixo ou varia por produto/cliente?
  - Churn é subtraído corretamente? (receita que foi gerada mas depois perdida)
- **Validação:** Confirmar com time financeiro se fórmula está correta
- **Ação:** Documentar premissas financeiras no dashboard (tooltip explicativo)

**8. Pipeline "Etapa em Negociação"**
- **Questão:** Pipeline Total considera apenas stage_id = 46. Correto?
  - Etapas anteriores (SQL, Reunião) deveriam entrar no pipeline?
  - Qual a definição de "pipeline" para AwSales?
- **Validação:** Alinhar com Head Comercial sobre definição de pipeline
- **Risco:** Métrica calculada errada gera decisões erradas

**9. Motivos de Perda - Padronização**
- **Questão:** Motivos de perda vêm como texto livre do Pipedrive
  - Pode haver typos, variações ("Não é ICP" vs "não é o icp")
  - Como garantir consistência?
- **Recomendação:** Normalizar motivos de perda (lowercase, trim) antes de agregação
- **Decisão futura:** Criar lista fixa de motivos no Pipedrive (dropdown)

**10. Deltas de Velocidade - Missing Data**
- **Questão:** Deltas calculados apenas se houver transições registradas em `crm_stage_transitions`
  - O que acontece se transição não foi capturada?
  - Delta fica zerado ou é ignorado?
- **Validação:** Verificar cobertura de `crm_stage_transitions` (% de deals com transições)
- **Mitigação:** Alertar se % de deals sem transições for alto (>20%)

### Product & UX

**11. Comparação de Períodos Customizados**
- **Questão:** MVP permite comparar "mês atual vs mês anterior". E se usuário quiser:
  - Comparar Q1 2026 vs Q1 2025?
  - Comparar semana específica de diferentes meses?
- **Decisão MVP:** Comparação fixa (período atual vs anterior imediato)
- **Growth Feature:** Implementar seletor de períodos customizados

**12. Drill-Down nas Métricas**
- **Questão:** Usuário vê "CP SQL: R$ 2.042 (+41% vermelho)". O que ele faz depois?
  - Quer drill-down para ver quais campanhas/anúncios têm CP SQL alto?
  - Quer ver lista de SQLs individuais?
- **MVP:** Apenas visualização agregada (sem drill-down)
- **Growth Feature:** Drill-down por campanha/anúncio

**13. Exportação de Dados**
- **Questão:** Usuários querem exportar dados para Excel/PDF?
  - Para compartilhar com CEO/investidores?
  - Para análises adicionais fora do dashboard?
- **MVP:** Sem exportação (usar screenshot se necessário)
- **Growth Feature:** Botão "Exportar para Excel" e "Gerar PDF"

**14. Alertas Proativos**
- **Questão:** Dashboard é "pull" (usuário acessa para ver). E se métrica crítica degradar?
  - Notificar automaticamente quando ROI < 1.0?
  - Email/Slack quando CP SQL ultrapassa threshold?
- **MVP:** Sem alertas (monitoramento manual)
- **Growth Feature:** Sistema de alertas configuráveis

**15. Mobile Experience**
- **Questão:** Qual % de uso será mobile?
  - Heads acessam do celular ou apenas desktop?
  - Mobile é "consulta rápida" ou "análise completa"?
- **MVP:** Suporte mobile básico (responsivo, mas prioridade desktop)
- **Validação:** Medir uso mobile nos primeiros 30 dias
- **Decisão futura:** Investir em mobile nativo se uso mobile > 30%

### Risks & Mitigations

**16. Dependência do n8n**
- **Risco:** Dashboard depende 100% do n8n para atualização de dados
  - Se n8n falhar, dados ficam defasados
  - Dashboard não tem fallback direto às APIs
- **Mitigação:** Monitorar health do n8n, alertas de falha
- **Backup:** Documentar como rodar queries manuais se n8n cair

**17. Mudanças nas APIs Externas**
- **Risco:** Meta, Google, LinkedIn podem mudar estrutura das APIs
  - Campos renomeados, deprecados, ou novos campos adicionados
  - n8n workflows podem quebrar
- **Mitigação:** n8n deve ter testes automatizados e versionamento
- **Responsabilidade:** Time de dados (não dashboard) deve manter integrações

**18. Divergência de Dados vs Fontes Originais**
- **Risco:** Dashboard mostra "R$ 173K gasto em Ads", mas Meta Ads Manager mostra "R$ 175K"
  - Usuários perdem confiança na "fonte única da verdade"
- **Causa:** Delays na sincronização, conversão de moeda, timezone
- **Mitigação:** Documentar "última atualização", adicionar tooltip explicando possível delay de até 1h
- **Validação:** Comparar manualmente dashboard vs fontes originais semanalmente nos primeiros 3 meses
