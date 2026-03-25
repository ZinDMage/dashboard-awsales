# 📋 Guia de Remoção de Duplicatas - YayForms

## 🎯 Objetivo
Remover respostas duplicadas da tabela `yayforms_responses`, mantendo apenas a **mais recente** para cada email ou telefone.

## ⚠️ IMPORTANTE - ANTES DE COMEÇAR

### Regras de Negócio:
1. **Mantemos sempre a resposta MAIS RECENTE** (última submitted_at)
2. **Duplicatas por EMAIL**: Remove respostas antigas do mesmo email
3. **Duplicatas por TELEFONE**: Remove respostas antigas do mesmo telefone
4. **Backup obrigatório** antes de qualquer DELETE

## 📊 Processo de Auditoria e Limpeza

### FASE 1: AUDITORIA (Arquivo: AUDITORIA-DUPLICATAS-YAYFORMS.sql)

#### 1.1 Análise Inicial
Execute as **Seções 1 e 2** para identificar:
- Total de emails duplicados
- Total de telefones duplicados
- Quantidade de registros para deletar
- Top 10 emails com mais duplicatas

#### 1.2 Validação de Casos Especiais
Execute a **Seção 5.1** para identificar:
- Leads que mudaram de faturamento
- Leads que mudaram de segmento
- Leads que mudaram de volume

**⚠️ ATENÇÃO**: Se houver muitos casos com informações diferentes, considere revisar a estratégia.

#### 1.3 Impacto nas Métricas
Execute a **Seção 4** para ver:
- Quantos MQLs serão afetados por mês
- Percentual de redução esperado

### FASE 2: EXECUÇÃO (Arquivo: SCRIPT-REMOCAO-DUPLICATAS.sql)

#### Passo 1: BACKUP (OBRIGATÓRIO!)
```sql
-- Criar backup completo
CREATE TABLE yayforms_responses_backup_20260325 AS
SELECT * FROM yayforms_responses;

-- Verificar backup
SELECT COUNT(*) FROM yayforms_responses_backup_20260325;
```

#### Passo 2: Análise Pré-Limpeza
```sql
-- Execute Seção 2.1 e 2.2 do SCRIPT-REMOCAO-DUPLICATAS.sql
-- Para ver resumo do que será deletado
```

#### Passo 3: Remover Duplicatas

**OPÇÃO A - Por EMAIL (Recomendado primeiro):**
```sql
BEGIN;

WITH duplicatas_para_deletar AS (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY lead_email ORDER BY submitted_at DESC) as rn
    FROM yayforms_responses
    WHERE lead_email IS NOT NULL AND lead_email != ''
  ) ranked
  WHERE rn > 1
)
DELETE FROM yayforms_responses
WHERE id IN (SELECT id FROM duplicatas_para_deletar);

COMMIT;
```

**OPÇÃO B - Por TELEFONE (Executar depois):**
```sql
BEGIN;

WITH duplicatas_para_deletar AS (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY lead_phone ORDER BY submitted_at DESC) as rn
    FROM yayforms_responses
    WHERE lead_phone IS NOT NULL AND lead_phone != ''
  ) ranked
  WHERE rn > 1
)
DELETE FROM yayforms_responses
WHERE id IN (SELECT id FROM duplicatas_para_deletar);

COMMIT;
```

#### Passo 4: Validação
Execute a **Seção 4** do script para:
- Verificar se ainda existem duplicatas
- Comparar antes e depois
- Ver nova contagem de MQLs

### FASE 3: PÓS-LIMPEZA

#### Checklist de Validação:
- [ ] Não existem mais duplicatas por email
- [ ] Não existem mais duplicatas por telefone
- [ ] Total de registros está correto
- [ ] MQLs por mês fazem sentido
- [ ] Dashboard está funcionando corretamente

## 📈 Impacto Esperado

### Métricas Afetadas:
1. **Total de Leads**: ⬇️ Redução (remove duplicatas)
2. **MQLs**: ⬇️ Possível redução (se duplicatas eram MQLs)
3. **Taxa de Conversão**: ⬆️ Possível melhora (denominador menor)
4. **CPL (Custo por Lead)**: ⬆️ Aumento (menos leads no denominador)

### Exemplo de Impacto:
```
Antes: 1000 respostas, 130 MQLs
       100 duplicatas (20 eram MQLs)

Depois: 900 respostas, 110 MQLs
        Taxa MQL: 13% → 12.2%
```

## 🔄 Rollback (Se Necessário)

Se algo der errado:
```sql
-- Limpar tabela atual
TRUNCATE TABLE yayforms_responses;

-- Restaurar do backup
INSERT INTO yayforms_responses
SELECT * FROM yayforms_responses_backup_20260325;

-- Verificar
SELECT COUNT(*) FROM yayforms_responses;
```

## 📝 Recomendações

### Para Prevenir Futuras Duplicatas:
1. **Adicionar constraint única** no banco:
```sql
ALTER TABLE yayforms_responses
ADD CONSTRAINT unique_email UNIQUE (lead_email);
```

2. **Validação no formulário**: Verificar duplicatas antes de inserir

3. **Processo periódico**: Executar limpeza mensalmente

### Manter Backup:
- Manter backup por **pelo menos 30 dias**
- Só deletar após confirmar que tudo está OK
- Documentar data e resultado da limpeza

## 🚀 Comando Rápido

Para executar tudo de uma vez (USE COM CUIDADO):
```sql
-- 1. Backup
CREATE TABLE yayforms_responses_backup_20260325 AS SELECT * FROM yayforms_responses;

-- 2. Remove duplicatas por email
WITH dup AS (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY lead_email ORDER BY submitted_at DESC) as rn
    FROM yayforms_responses
    WHERE lead_email IS NOT NULL AND lead_email != ''
  ) r WHERE rn > 1
)
DELETE FROM yayforms_responses WHERE id IN (SELECT id FROM dup);

-- 3. Remove duplicatas por telefone
WITH dup AS (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY lead_phone ORDER BY submitted_at DESC) as rn
    FROM yayforms_responses
    WHERE lead_phone IS NOT NULL AND lead_phone != ''
  ) r WHERE rn > 1
)
DELETE FROM yayforms_responses WHERE id IN (SELECT id FROM dup);

-- 4. Verificar
SELECT 'Limpeza concluída' as status,
       COUNT(*) as total_restante,
       COUNT(DISTINCT lead_email) as emails_unicos,
       COUNT(DISTINCT lead_phone) as telefones_unicos
FROM yayforms_responses;
```

## 📅 Log de Execução

| Data | Registros Antes | Duplicatas Removidas | Registros Depois | Executado Por |
|------|-----------------|---------------------|------------------|---------------|
| 2026-03-25 | _preencher_ | _preencher_ | _preencher_ | _preencher_ |

## 🆘 Suporte

Em caso de problemas:
1. NÃO execute COMMIT se algo parecer errado
2. Use ROLLBACK para desfazer transação
3. Consulte o backup antes de qualquer ação drástica
4. Documente qualquer anomalia encontrada