/**
 * Teste da função classifyLead com a nova regra E-commerce
 *
 * Para testar, execute no console do navegador:
 * 1. Abra o dashboard
 * 2. Cole este código no console
 * 3. Execute os testes
 */

// Arrays de configuração (devem ser idênticos aos do dataService.js)
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

const disqualifiedSegments = [
  '🩺 Clínica / consultório',
  '⚖️ Escritório de advocacia'
];

// Função de teste
function classifyLead(fat, vol, seg, market = null) {
  // Regra 1: Faturamento desqualificado = Lead
  if (!fat || disqualifiedRanges.includes(fat)) return 'Lead';

  // Regra 2: Segmento desqualificado = Lead
  if (seg && disqualifiedSegments.includes(seg)) return 'Lead';

  // Regra 3: Volume com regra especial para E-commerce
  if (market === '🛒 Ecommerce') {
    // E-commerce: precisa > 10.000 tickets/mês
    if (vol && disqualifiedEcommerceVolumes.includes(vol)) return 'Lead';
  } else {
    // Outros mercados: regra padrão
    if (vol && disqualifiedTicketVolumes.includes(vol)) return 'Lead';
  }

  // Regra 4: Se passou em tudo e tem faturamento qualificado = MQL
  if (qualifiedRanges.includes(fat)) return 'MQL';

  return 'Lead';
}

// ========================================
// CASOS DE TESTE
// ========================================

const testCases = [
  // Testes básicos sem E-commerce
  {
    name: "Lead qualificado padrão",
    input: {
      fat: 'Entre R$1 milhão a R$5 milhões',
      vol: 'Entre 5.000 e 10.000 por mês',
      seg: 'Varejo',
      market: 'Varejo'
    },
    expected: 'MQL'
  },
  {
    name: "Lead desqualificado por faturamento",
    input: {
      fat: 'Menos de R$100 mil',
      vol: 'Acima de 10.000 por mês',
      seg: 'Varejo',
      market: 'Varejo'
    },
    expected: 'Lead'
  },
  {
    name: "Lead desqualificado por segmento (clínica)",
    input: {
      fat: 'Entre R$1 milhão a R$5 milhões',
      vol: 'Acima de 10.000 por mês',
      seg: '🩺 Clínica / consultório',
      market: 'Saúde'
    },
    expected: 'Lead'
  },
  {
    name: "Lead desqualificado por volume baixo (não E-commerce)",
    input: {
      fat: 'Entre R$1 milhão a R$5 milhões',
      vol: 'Entre 1.000 e 3.000 por mês',
      seg: 'Varejo',
      market: 'Varejo'
    },
    expected: 'Lead'
  },

  // Testes específicos para E-commerce
  {
    name: "E-commerce com volume > 10k = MQL",
    input: {
      fat: 'Entre R$5 milhões a R$10 milhões',
      vol: 'Acima de 10.000 por mês',
      seg: 'Varejo',
      market: '🛒 Ecommerce'
    },
    expected: 'MQL'
  },
  {
    name: "E-commerce com volume 5k-10k = Lead (NOVA REGRA)",
    input: {
      fat: 'Entre R$5 milhões a R$10 milhões',
      vol: 'Entre 5.000 e 10.000 por mês',
      seg: 'Varejo',
      market: '🛒 Ecommerce'
    },
    expected: 'Lead'
  },
  {
    name: "E-commerce com volume < 5k = Lead",
    input: {
      fat: 'Entre R$5 milhões a R$10 milhões',
      vol: 'Entre 1.000 e 3.000 por mês',
      seg: 'Varejo',
      market: '🛒 Ecommerce'
    },
    expected: 'Lead'
  },
  {
    name: "E-commerce com 50k-100k tickets = MQL",
    input: {
      fat: 'Acima de R$10 milhões',
      vol: 'Entre 50.000 e 100.000 por mês',
      seg: 'Varejo',
      market: '🛒 Ecommerce'
    },
    expected: 'MQL'
  },
  {
    name: "E-commerce sem volume informado = MQL",
    input: {
      fat: 'Entre R$10 milhões a R$25 milhões',
      vol: null,
      seg: 'Varejo',
      market: '🛒 Ecommerce'
    },
    expected: 'MQL'
  },

  // Comparação: Não E-commerce vs E-commerce com mesmo volume
  {
    name: "Não E-commerce com 5k-10k = MQL",
    input: {
      fat: 'Entre R$1 milhão a R$5 milhões',
      vol: 'Entre 5.000 e 10.000 por mês',
      seg: 'Serviços',
      market: 'Serviços'
    },
    expected: 'MQL'
  },
  {
    name: "E-commerce com 5k-10k = Lead (diferença da regra)",
    input: {
      fat: 'Entre R$1 milhão a R$5 milhões',
      vol: 'Entre 5.000 e 10.000 por mês',
      seg: 'Varejo',
      market: '🛒 Ecommerce'
    },
    expected: 'Lead'
  }
];

// ========================================
// EXECUTAR TESTES
// ========================================

function runTests() {
  console.log('🧪 Iniciando testes da função classifyLead com regra E-commerce\n');
  console.log('=' .repeat(60));

  let passed = 0;
  let failed = 0;

  testCases.forEach((test, index) => {
    const { fat, vol, seg, market } = test.input;
    const result = classifyLead(fat, vol, seg, market);
    const isCorrect = result === test.expected;

    if (isCorrect) {
      passed++;
      console.log(`✅ Test ${index + 1}: ${test.name}`);
      console.log(`   Input: market="${market}", vol="${vol}"`);
      console.log(`   Result: ${result} (esperado: ${test.expected})\n`);
    } else {
      failed++;
      console.log(`❌ Test ${index + 1}: ${test.name}`);
      console.log(`   Input: market="${market}", vol="${vol}"`);
      console.log(`   Result: ${result} (esperado: ${test.expected})`);
      console.log(`   FALHOU!\n`);
    }
  });

  console.log('=' .repeat(60));
  console.log(`\n📊 Resultado Final: ${passed} passou, ${failed} falhou`);
  console.log(`Taxa de sucesso: ${((passed / testCases.length) * 100).toFixed(1)}%\n`);

  if (failed === 0) {
    console.log('🎉 Todos os testes passaram! A regra E-commerce está funcionando corretamente.');
  } else {
    console.log('⚠️ Alguns testes falharam. Revise a implementação.');
  }
}

// Executar testes
runTests();

// ========================================
// TESTE COM DADOS REAIS
// ========================================

console.log('\n' + '=' .repeat(60));
console.log('📊 Exemplos com dados reais:\n');

const realExamples = [
  {
    fat: 'Entre R$5 milhões a R$10 milhões',
    vol: 'Entre 5.000 e 10.000 por mês',
    seg: 'Varejo',
    market: '🛒 Ecommerce'
  },
  {
    fat: 'Entre R$5 milhões a R$10 milhões',
    vol: 'Entre 5.000 e 10.000 por mês',
    seg: 'Varejo',
    market: 'Varejo Físico'
  },
  {
    fat: 'Entre R$5 milhões a R$10 milhões',
    vol: 'Acima de 10.000 por mês',
    seg: 'Varejo',
    market: '🛒 Ecommerce'
  }
];

realExamples.forEach(ex => {
  const result = classifyLead(ex.fat, ex.vol, ex.seg, ex.market);
  console.log(`Market: ${ex.market}`);
  console.log(`Volume: ${ex.vol}`);
  console.log(`Resultado: ${result}`);
  console.log('---');
});