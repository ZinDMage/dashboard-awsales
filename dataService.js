import { supabase } from './supabaseClient';

/**
 * Data Service for Dash AwSales
 * Handles aggregation of business metrics from Supabase tables.
 *
 * Supports two view modes:
 *   - "performance": metrics attributed to when the event happened
 *   - "criacao": metrics attributed to when the lead/deal was created (cohort view)
 */

// ── Regras de Qualificação MQL ─────────────────────────────────
const disqualifiedRanges = [
  'Zero até o momento',
  'Menos de R$100 mil',
  'Entre R$100 mil e R$500 mil',
  'Entre R$500 mil e R$1 milhão'
];

const qualifiedRanges = [
  'Entre R$1 milhão a R$5 milhões',
  'Entre R$5 milhões a R$10 milhões',
  'Entre R$10 milhões a R$25 milhões',
  'Entre R$25 milhões a R$50 milhões',
  'Acima de R$50 milhões',
  'Acima de R$10 milhões'
];

const disqualifiedTicketVolumes = [
  'Menos de 1.000 por mês',
  'Entre 1.000 e 3.000 por mês',
  'Entre 1.000 e 5.000 por mês',
  'Entre 3.000 e 5.000 por mês'
];

const disqualifiedEcommerceVolumes = [
  'Menos de 1.000 por mês',
  'Entre 1.000 e 3.000 por mês',
  'Entre 1.000 e 5.000 por mês',
  'Entre 3.000 e 5.000 por mês',
  'Entre 5.000 e 10.000 por mês'
];

const qualifiedEcommerceVolumes = [
  'Acima de 10.000 por mês',
  'Entre 10.000 e 50.000 por mês',
  'Entre 50.000 e 100.000 por mês',
  'Acima de 100.000 por mês'
];

const disqualifiedSegments = [
  '🩺 Clínica / consultório',
  '⚖️ Escritório de advocacia'
];

function classifyLead(fat, vol, seg, market = null) {
  if (!fat || disqualifiedRanges.includes(fat)) return 'Lead';
  if (!qualifiedRanges.includes(fat)) return 'Lead';
  if (seg && disqualifiedSegments.includes(seg)) return 'Lead';
  const isEcommerce = market === '🛒 Ecommerce';
  if (isEcommerce) {
    if (vol && disqualifiedEcommerceVolumes.includes(vol)) return 'Lead';
  } else {
    if (vol && disqualifiedTicketVolumes.includes(vol)) return 'Lead';
  }
  return 'MQL';
}

// ── Stage IDs do Pipedrive ─────────────────────────────────────
const STAGE_IDS = {
  MQL: [1, 49],
  SQL: [19, 50],
  REUNIAO_AGENDADA: [3, 45, 51, 27, 37],
  PROPOSTA: [4, 46, 29, 39],
  CONTRATO_ENVIADO: [41, 47, 43, 40],
  PIPELINE_TOTAL: [46]
};

// ── Custom Fields do Pipedrive ─────────────────────────────────
const CUSTOM_FIELDS = {
  SQL_FLAG: {
    key: '2e17191cfb8e6f4a58359adc42a08965a068e8bc',
    values: { SIM: '75', NAO: '76', A_REVISAR: '79' }
  },
  DATA_REUNIAO: {
    key: '8eff24b00226da8dfb871caaf638b62af68bf16b'
  },
  REUNIAO_REALIZADA: {
    key: 'baf2724fcbeec84a36e90f9dc3299431fe1b0dd3',
    values: { SIM: '47', NAO: '59' }
  },
  DATA_QUALIFICACAO: {
    key: '99ce1624c66efcf108dbf99f06fcbb7bd79570f7'
  }
};

// ── Mapeamento de Funis por Pipeline ID ────────────────────────
export const PIPELINE_FUNNELS = {
  inbound:   [1, 8, 9],
  indicacao: [2, 3, 5],
  eventos:   [4],
  wordwild:  [7],
  clinicas:  [],
};

const parseCustomFields = (cf) => {
  if (!cf) return {};
  if (typeof cf === 'string') {
    try { return JSON.parse(cf); } catch { return {}; }
  }
  return cf;
};

export const fetchMonthlyMetrics = async () => {
  try {
    const fetchAll = async (table, selectStr) => {
      let all = [];
      let from = 0;
      let size = 1000;
      while (true) {
        const { data, error } = await supabase.from(table).select(selectStr).range(from, from + size - 1);
        if (error) { console.error(`Supabase Error on ${table}:`, error); break; }
        if (!data || data.length === 0) break;
        all = all.concat(data);
        if (data.length < size) break;
        from += size;
      }
      return { data: all };
    };

    const results = await Promise.all([
      fetchAll('sales', 'id, receita_gerada, data_fechamento, status, email_pipedrive, email_stripe'),
      fetchAll('meta_ads_costs', 'spend, impressions, date_start'),
      fetchAll('google_ads_costs', 'spend, impressions, clicks, conversions, date'),
      fetchAll('meta_ads_actions', 'action_type, value, date_start'),
      fetchAll('yayforms_responses', 'submitted_at, lead_email, lead_revenue_range, lead_monthly_volume, lead_segment, lead_market'),
      fetchAll('crm_deals', 'deal_created_at, stage_id, pipeline_id, status, value, custom_fields, person_email, won_time, deal_id, lost_reason'),
      fetchAll('crm_stage_transitions', 'deal_id, to_stage_id, time_in_previous_stage_sec')
    ]);

    const [
      { data: salesRaw },
      { data: metaAds },
      { data: googleAds },
      { data: metaActions },
      { data: leads },
      { data: dealsRaw },
      { data: stageTransitions }
    ] = results;

    // ── Pre-compute shared lookup maps (used by both modes) ─────

    const dealDateByEmail = {};
    if (dealsRaw) {
      dealsRaw.forEach(d => {
        if (d.person_email && d.deal_created_at) {
          const emailKey = d.person_email.toLowerCase().trim();
          if (!dealDateByEmail[emailKey]) dealDateByEmail[emailKey] = d.deal_created_at;
        }
      });
    }

    const saleDateByEmail = {};
    if (salesRaw) {
      salesRaw.forEach(s => {
        const ep = s.email_pipedrive?.toLowerCase().trim();
        const es = s.email_stripe?.toLowerCase().trim();
        if (ep && s.data_fechamento) saleDateByEmail[ep] = s.data_fechamento;
        if (es && s.data_fechamento) saleDateByEmail[es] = s.data_fechamento;
      });
    }

    const transitionsByDeal = {};
    if (stageTransitions) {
      stageTransitions.forEach(t => {
        if (!transitionsByDeal[t.deal_id]) transitionsByDeal[t.deal_id] = [];
        transitionsByDeal[t.deal_id].push(t);
      });
    }

    const leadDateByEmail = {};
    if (leads) {
      leads.forEach(l => {
        if (l.lead_email) {
          const emailKey = l.lead_email.toLowerCase().trim();
          if (!leadDateByEmail[emailKey]) leadDateByEmail[emailKey] = l.submitted_at;
        }
      });
    }

    // ── Process metrics for a given view mode ───────────────────
    const processMode = (mode) => {
      const metricsByMonth = {};
      const metricsByMonthByFunnel = Object.fromEntries(
        Object.keys(PIPELINE_FUNNELS).map(k => [k, {}])
      );

      const getMonthKey = (dateStr) => {
        if (!dateStr) return null;
        const d = new Date(dateStr);
        if (isNaN(d.getTime())) return null;
        const months = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];
        return `${d.getUTCFullYear()}-${months[d.getUTCMonth()]}`;
      };

      const getWeekKey = (dateStr) => {
        if (!dateStr) return null;
        const day = new Date(dateStr).getUTCDate();
        if (day <= 7) return "s1";
        if (day <= 14) return "s2";
        if (day <= 21) return "s3";
        return "s4";
      };

      const initMetrics = () => ({
        g: { rec: 0, gAds: 0, roi: 0, mc: 0, pipe: 0, fatP: 0, recP: 0, vendas: 0, tmf: 0 },
        n: { imp: 0, cli: 0, vp: 0, ld: 0, mql: 0, sql: 0, rAg: 0, rRe: 0, v: 0 },
        p: { ctr: 0, cr: 0, cc: 0, qm: 0, qs: 0, ag: 0, su: 0, fc: 0, fs: 0 },
        f: { gAds: 0, cpL: 0, cpM: 0, cpS: 0, cpRA: 0, cpRR: 0, cpV: 0 },
        dt: { ms: 0, sr: 0, rv: 0, lv: 0 },
        perdas: { mql: [], sql: [], proposta: [] },
        _churnTemp: 0,
        _deltas: { ms: [], sr: [], rv: [], lv: [] }
      });

      const initMonthInMap = (map, key) => {
        if (!map[key]) {
          map[key] = {
            ...initMetrics(),
            wk: { s1: initMetrics(), s2: initMetrics(), s3: initMetrics(), s4: initMetrics() }
          };
        }
        return map[key];
      };

      const getFunnelKey = (pipelineId) =>
        Object.keys(PIPELINE_FUNNELS).find(k => PIPELINE_FUNNELS[k].includes(pipelineId)) ?? null;

      const initMonth = (key) => initMonthInMap(metricsByMonth, key);

      const updateMetrics = (m, row, val, type, field, wkKey) => {
        const v = Number(val || 0);
        m[type][field] += v;
        if (wkKey && m.wk[wkKey]) m.wk[wkKey][type][field] += v;
      };

      // ── Process salesRaw (mode-aware) ──────────────────────────
      if (salesRaw) {
        salesRaw.forEach(s => {
          const emailPipe = s.email_pipedrive?.toLowerCase().trim();
          const emailStripe = s.email_stripe?.toLowerCase().trim();

          // Date for g.rec, g.vendas (revenue cards)
          let recDate;
          if (mode === 'criacao') {
            // Criação: só conta vendas com tracking no CRM (sem fallback)
            recDate = (emailPipe && dealDateByEmail[emailPipe])
              || (emailStripe && dealDateByEmail[emailStripe]);
          } else {
            recDate = s.data_fechamento;
          }

          const mk = getMonthKey(recDate);
          const wk = getWeekKey(recDate);
          if (!mk) return;
          const m = initMonth(mk);
          const mi = initMonthInMap(metricsByMonthByFunnel['inbound'], mk);

          updateMetrics(m, s, s.receita_gerada, 'g', 'rec', wk);
          updateMetrics(m, s, 1, 'g', 'vendas', wk);
          updateMetrics(mi, s, s.receita_gerada, 'g', 'rec', wk);
          updateMetrics(mi, s, 1, 'g', 'vendas', wk);

          // Date for n.v (# Vendas in Números)
          let nvDate;
          if (mode === 'criacao') {
            nvDate = (emailPipe && dealDateByEmail[emailPipe])
              || (emailStripe && dealDateByEmail[emailStripe]);
          } else {
            nvDate = s.data_fechamento;
          }

          if (nvDate) {
            const nMk = getMonthKey(nvDate);
            const nWk = getWeekKey(nvDate);
            if (nMk) {
              const nM = initMonth(nMk);
              const nMi = initMonthInMap(metricsByMonthByFunnel['inbound'], nMk);
              updateMetrics(nM, s, 1, 'n', 'v', nWk);
              updateMetrics(nMi, s, 1, 'n', 'v', nWk);
            }
          }

          // Churn follows same date as g.rec for mc consistency
          if (s.status === 'Churn') {
            m._churnTemp += Number(s.receita_gerada || 0);
            if (wk) m.wk[wk]._churnTemp += Number(s.receita_gerada || 0);
            mi._churnTemp += Number(s.receita_gerada || 0);
            if (wk) mi.wk[wk]._churnTemp += Number(s.receita_gerada || 0);
          }
        });
      }

      // ── Process Meta Ads (same for both modes) ─────────────────
      if (metaAds) {
        metaAds.forEach(row => {
          const mk = getMonthKey(row.date_start);
          const wk = getWeekKey(row.date_start);
          if (!mk) return;
          const m = initMonth(mk);
          const mi = initMonthInMap(metricsByMonthByFunnel['inbound'], mk);
          updateMetrics(m, row, row.spend, 'g', 'gAds', wk);
          updateMetrics(m, row, row.impressions, 'n', 'imp', wk);
          updateMetrics(mi, row, row.spend, 'g', 'gAds', wk);
          updateMetrics(mi, row, row.impressions, 'n', 'imp', wk);
        });
      }

      // ── Process Google Ads (same for both modes) ───────────────
      if (googleAds) {
        googleAds.forEach(row => {
          const mk = getMonthKey(row.date);
          const wk = getWeekKey(row.date);
          if (!mk) return;
          const m = initMonth(mk);
          const mi = initMonthInMap(metricsByMonthByFunnel['inbound'], mk);
          updateMetrics(m, row, row.spend, 'g', 'gAds', wk);
          updateMetrics(m, row, row.impressions, 'n', 'imp', wk);
          updateMetrics(m, row, row.clicks, 'n', 'cli', wk);
          updateMetrics(m, row, row.conversions, 'n', 'vp', wk);
          updateMetrics(mi, row, row.spend, 'g', 'gAds', wk);
          updateMetrics(mi, row, row.impressions, 'n', 'imp', wk);
          updateMetrics(mi, row, row.clicks, 'n', 'cli', wk);
          updateMetrics(mi, row, row.conversions, 'n', 'vp', wk);
        });
      }

      // ── Process Meta Actions (same for both modes) ─────────────
      if (metaActions) {
        metaActions.forEach(act => {
          const mk = getMonthKey(act.date_start);
          const wk = getWeekKey(act.date_start);
          if (!mk) return;
          const m = initMonth(mk);
          const mi = initMonthInMap(metricsByMonthByFunnel['inbound'], mk);
          if (act.action_type === 'unique_outbound_outbound_click') {
            updateMetrics(m, act, act.value, 'n', 'cli', wk);
            updateMetrics(mi, act, act.value, 'n', 'cli', wk);
          }
          if (act.action_type === 'landing_page_view') {
            updateMetrics(m, act, act.value, 'n', 'vp', wk);
            updateMetrics(mi, act, act.value, 'n', 'vp', wk);
          }
        });
      }

      // ── Process Leads / YayForms (same for both modes) ─────────
      if (leads) {
        leads.forEach(l => {
          const mk = getMonthKey(l.submitted_at);
          const wk = getWeekKey(l.submitted_at);
          if (!mk) return;
          const m = initMonth(mk);
          const mi = initMonthInMap(metricsByMonthByFunnel['inbound'], mk);
          updateMetrics(m, l, 1, 'n', 'ld', wk);
          updateMetrics(mi, l, 1, 'n', 'ld', wk);

          const classification = classifyLead(
            l.lead_revenue_range,
            l.lead_monthly_volume,
            l.lead_segment,
            l.lead_market
          );
          if (classification === 'MQL') {
            updateMetrics(m, l, 1, 'n', 'mql', wk);
            updateMetrics(mi, l, 1, 'n', 'mql', wk);
          }
        });
      }

      // ── Process CRM Deals (mode-aware for SQL/reunião dates) ───
      if (dealsRaw) {
        dealsRaw.forEach(d => {
          const baseMk = getMonthKey(d.deal_created_at);
          const baseWk = getWeekKey(d.deal_created_at);
          if (!baseMk) return;
          const m = initMonth(baseMk);
          const fk = getFunnelKey(d.pipeline_id);
          const mf = fk ? initMonthInMap(metricsByMonthByFunnel[fk], baseMk) : null;

          // Pipeline Total: always by deal_created_at
          if (STAGE_IDS.PIPELINE_TOTAL.includes(d.stage_id)) {
            updateMetrics(m, d, d.value, 'g', 'pipe', baseWk);
            if (mf) updateMetrics(mf, d, d.value, 'g', 'pipe', baseWk);
          }

          // Motivos de perda: always by deal_created_at
          if (d.status === 'lost' && d.lost_reason) {
            if (STAGE_IDS.MQL.includes(d.stage_id)) {
              m.perdas.mql.push(d.lost_reason);
              if (baseWk && m.wk[baseWk]) m.wk[baseWk].perdas.mql.push(d.lost_reason);
              if (mf) { mf.perdas.mql.push(d.lost_reason); if (baseWk && mf.wk[baseWk]) mf.wk[baseWk].perdas.mql.push(d.lost_reason); }
            }
            else if (STAGE_IDS.SQL.includes(d.stage_id)) {
              m.perdas.sql.push(d.lost_reason);
              if (baseWk && m.wk[baseWk]) m.wk[baseWk].perdas.sql.push(d.lost_reason);
              if (mf) { mf.perdas.sql.push(d.lost_reason); if (baseWk && mf.wk[baseWk]) mf.wk[baseWk].perdas.sql.push(d.lost_reason); }
            }
            else if (STAGE_IDS.PROPOSTA.includes(d.stage_id) || STAGE_IDS.CONTRATO_ENVIADO.includes(d.stage_id)) {
              m.perdas.proposta.push(d.lost_reason);
              if (baseWk && m.wk[baseWk]) m.wk[baseWk].perdas.proposta.push(d.lost_reason);
              if (mf) { mf.perdas.proposta.push(d.lost_reason); if (baseWk && mf.wk[baseWk]) mf.wk[baseWk].perdas.proposta.push(d.lost_reason); }
            }
          }

          const cj = parseCustomFields(d.custom_fields);
          const isSQL = cj[CUSTOM_FIELDS.SQL_FLAG.key] == CUSTOM_FIELDS.SQL_FLAG.values.SIM;

          if (isSQL) {
            // ── SQL date (mode-aware) ──
            let sqlMk, sqlWk;
            if (mode === 'performance') {
              const dataQual = cj[CUSTOM_FIELDS.DATA_QUALIFICACAO.key];
              sqlMk = (dataQual && getMonthKey(dataQual)) || baseMk;
              sqlWk = (dataQual && getWeekKey(dataQual)) || baseWk;
            } else {
              sqlMk = baseMk;
              sqlWk = baseWk;
            }

            const sqlM = initMonth(sqlMk);
            const sqlMf = fk ? initMonthInMap(metricsByMonthByFunnel[fk], sqlMk) : null;

            updateMetrics(sqlM, d, 1, 'n', 'sql', sqlWk);
            if (sqlMf) updateMetrics(sqlMf, d, 1, 'n', 'sql', sqlWk);

            // ── Reunião agendada (mode-aware) ──
            const agendamentoDate = cj[CUSTOM_FIELDS.DATA_REUNIAO.key];
            if (agendamentoDate && agendamentoDate !== '') {
              let rAgMk, rAgWk;
              if (mode === 'performance') {
                rAgMk = getMonthKey(agendamentoDate) || sqlMk;
                rAgWk = getWeekKey(agendamentoDate) || sqlWk;
              } else {
                rAgMk = baseMk;
                rAgWk = baseWk;
              }
              const rAgM = initMonth(rAgMk);
              const rAgMf = fk ? initMonthInMap(metricsByMonthByFunnel[fk], rAgMk) : null;
              updateMetrics(rAgM, d, 1, 'n', 'rAg', rAgWk);
              if (rAgMf) updateMetrics(rAgMf, d, 1, 'n', 'rAg', rAgWk);
            }

            // ── Reunião realizada (mode-aware) ──
            const reuniaoRealizada = cj[CUSTOM_FIELDS.REUNIAO_REALIZADA.key] == CUSTOM_FIELDS.REUNIAO_REALIZADA.values.SIM;
            if (reuniaoRealizada) {
              let rReMk, rReWk;
              if (mode === 'performance') {
                rReMk = (agendamentoDate && getMonthKey(agendamentoDate)) || sqlMk;
                rReWk = (agendamentoDate && getWeekKey(agendamentoDate)) || sqlWk;
              } else {
                rReMk = baseMk;
                rReWk = baseWk;
              }
              const rReM = initMonth(rReMk);
              const rReMf = fk ? initMonthInMap(metricsByMonthByFunnel[fk], rReMk) : null;
              updateMetrics(rReM, d, 1, 'n', 'rRe', rReWk);
              if (rReMf) updateMetrics(rReMf, d, 1, 'n', 'rRe', rReWk);
            }

            // ── Delta Calculations (always by deal_created_at) ──
            const daysDiff = (d1, d2) => {
              if (!d1 || !d2) return null;
              const a = new Date(d1), b = new Date(d2);
              if (isNaN(a) || isNaN(b)) return null;
              return Math.round(Math.abs(b - a) / (1000 * 60 * 60 * 24));
            };

            const deltaM = initMonth(baseMk);
            const deltaMf = fk ? initMonthInMap(metricsByMonthByFunnel[fk], baseMk) : null;
            const dealTransitions = transitionsByDeal[d.deal_id] || [];
            const dealEmail = d.person_email?.toLowerCase().trim();
            const saleDate = dealEmail ? saleDateByEmail[dealEmail] : null;

            // 1. MQL → SQL
            const dataQualificacao = cj[CUSTOM_FIELDS.DATA_QUALIFICACAO.key];
            if (dataQualificacao && d.deal_created_at) {
              const dMs = daysDiff(d.deal_created_at, dataQualificacao);
              if (dMs !== null) {
                deltaM._deltas.ms.push(dMs);
                if (baseWk && deltaM.wk[baseWk]) deltaM.wk[baseWk]._deltas.ms.push(dMs);
                if (deltaMf) { deltaMf._deltas.ms.push(dMs); if (baseWk && deltaMf.wk[baseWk]) deltaMf.wk[baseWk]._deltas.ms.push(dMs); }
              }
            }

            const sqlTransition = dealTransitions.find(t =>
              STAGE_IDS.SQL.includes(t.to_stage_id) && t.time_in_previous_stage_sec
            );

            // 2. SQL → Reunião Agendada
            const meetingTransition = dealTransitions.find(t =>
              STAGE_IDS.REUNIAO_AGENDADA.includes(t.to_stage_id) && t.time_in_previous_stage_sec
            );
            if (meetingTransition) {
              const dSr = Math.round(Number(meetingTransition.time_in_previous_stage_sec) / (60 * 60 * 24));
              deltaM._deltas.sr.push(dSr);
              if (baseWk && deltaM.wk[baseWk]) deltaM.wk[baseWk]._deltas.sr.push(dSr);
              if (deltaMf) { deltaMf._deltas.sr.push(dSr); if (baseWk && deltaMf.wk[baseWk]) deltaMf.wk[baseWk]._deltas.sr.push(dSr); }
            }

            // 3. Proposta Feita → Venda
            const propostaTransition = dealTransitions.find(t =>
              STAGE_IDS.PROPOSTA.includes(t.to_stage_id) && t.time_in_previous_stage_sec
            );
            if (propostaTransition && saleDate && d.deal_created_at) {
              const secToSQL      = sqlTransition     ? Number(sqlTransition.time_in_previous_stage_sec)      : 0;
              const secToMeeting  = meetingTransition ? Number(meetingTransition.time_in_previous_stage_sec)  : 0;
              const secToProposta = Number(propostaTransition.time_in_previous_stage_sec);
              const totalSecToProposta = secToSQL + secToMeeting + secToProposta;
              const propostaEntryDate = new Date(new Date(d.deal_created_at).getTime() + totalSecToProposta * 1000);
              const dRv = daysDiff(propostaEntryDate, saleDate);
              if (dRv !== null) {
                deltaM._deltas.rv.push(dRv);
                if (baseWk && deltaM.wk[baseWk]) deltaM.wk[baseWk]._deltas.rv.push(dRv);
                if (deltaMf) { deltaMf._deltas.rv.push(dRv); if (baseWk && deltaMf.wk[baseWk]) deltaMf.wk[baseWk]._deltas.rv.push(dRv); }
              }
            }

            // 4. Criação do lead → Venda
            if (d.deal_created_at && saleDate) {
              const dLv = daysDiff(d.deal_created_at, saleDate);
              if (dLv !== null) {
                deltaM._deltas.lv.push(dLv);
                if (baseWk && deltaM.wk[baseWk]) deltaM.wk[baseWk]._deltas.lv.push(dLv);
                if (deltaMf) { deltaMf._deltas.lv.push(dLv); if (baseWk && deltaMf.wk[baseWk]) deltaMf.wk[baseWk]._deltas.lv.push(dLv); }
              }
            }
          }
        });
      }

      // ── Finalize ───────────────────────────────────────────────
      const finalize = (m) => {
        const { g, n, p, f } = m;
        g.roi = g.gAds > 0 ? g.rec / g.gAds : 0;
        g.mc = g.rec - (g.rec * 0.095) - m._churnTemp;
        g.fatP = g.pipe * 0.2;
        g.recP = g.rec + g.fatP;
        g.tmf = g.vendas > 0 ? g.rec / g.vendas : 0;
        f.gAds = g.gAds;

        const calcP = (num, den) => den > 0 ? num / den : 0;
        p.ctr = calcP(n.cli, n.imp);
        p.cr = calcP(n.vp, n.cli);
        p.cc = calcP(n.ld, n.vp);
        p.qm = calcP(n.mql, n.ld);
        p.qs = calcP(n.sql, n.mql);
        p.ag = calcP(n.rAg, n.sql);
        p.su = calcP(n.rRe, n.rAg);
        p.fc = calcP(n.v, n.rRe);
        p.fs = calcP(n.v, n.sql);

        f.cpL = calcP(f.gAds, n.ld);
        f.cpM = calcP(f.gAds, n.mql);
        f.cpS = calcP(f.gAds, n.sql);
        f.cpRA = calcP(f.gAds, n.rAg);
        f.cpRR = calcP(f.gAds, n.rRe);
        f.cpV = calcP(f.gAds, n.v);

        const avg = arr => arr.length > 0 ? Math.round(arr.reduce((a, b) => a + b, 0) / arr.length) : 0;
        if (m._deltas) {
          m.dt.ms = avg(m._deltas.ms);
          m.dt.sr = avg(m._deltas.sr);
          m.dt.rv = avg(m._deltas.rv);
          m.dt.lv = avg(m._deltas.lv);
        }

        const summarizePerdas = (arr) => {
          if (!arr || arr.length === 0) return [];
          const counts = {};
          arr.forEach(r => { counts[r] = (counts[r] || 0) + 1; });
          const total = arr.length;
          return Object.entries(counts)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 3)
            .map(([r, c]) => ({ m: r, p: Math.round((c / total) * 100) }));
        };

        if (m.perdas) {
          m.perdas.mql = summarizePerdas(m.perdas.mql);
          m.perdas.sql = summarizePerdas(m.perdas.sql);
          m.perdas.proposta = summarizePerdas(m.perdas.proposta);
        }
      };

      const finalizeMap = (map) => {
        Object.keys(map).forEach(mk => {
          const m = map[mk];
          finalize(m);
          Object.keys(m.wk).forEach(wkKey => finalize(m.wk[wkKey]));
        });
      };
      finalizeMap(metricsByMonth);
      Object.values(metricsByMonthByFunnel).forEach(finalizeMap);

      return { all: metricsByMonth, funnels: metricsByMonthByFunnel };
    };

    return {
      performance: processMode('performance'),
      criacao: processMode('criacao')
    };
  } catch (err) {
    console.error("Critical error in data service:", err);
    throw err;
  }
};

export const fetchLossReasons = async () => {
  const { data, error } = await supabase
    .from('crm_deals')
    .select('lost_reason')
    .not('lost_reason', 'is', null);

  if (error) throw error;
  return data;
};
