import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

const supabaseUrl = 'https://rbkkliyjrbkcxzctppwj.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJia2tsaXlqcmJrY3h6Y3RwcHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAxNTI4NDQsImV4cCI6MjA1NTcyODg0NH0.EiBs6VdBZqU56C5v3JFIEDA7RolV6g';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Lista de tabelas conhecidas do dataService.js
const tables = [
  'sales',
  'meta_ads_costs',
  'google_ads_costs',
  'meta_ads_actions',
  'yayforms_responses',
  'crm_deals',
  'crm_stage_transitions'
];

async function extractDDL() {
  console.log('Extraindo DDL das tabelas do Supabase...\n');

  const outputDir = './ddl_supabase';
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  for (const tableName of tables) {
    console.log(`Processando tabela: ${tableName}`);

    try {
      // Buscar schema da tabela via information_schema
      const { data, error } = await supabase.rpc('exec_sql', {
        query: `
          SELECT
            column_name,
            data_type,
            character_maximum_length,
            numeric_precision,
            numeric_scale,
            is_nullable,
            column_default
          FROM information_schema.columns
          WHERE table_schema = 'public'
            AND table_name = '${tableName}'
          ORDER BY ordinal_position;
        `
      });

      if (error) {
        console.error(`  ❌ Erro ao buscar schema de ${tableName}:`, error.message);

        // Fallback: buscar dados de amostra para inferir schema
        console.log(`  Tentando inferir schema de ${tableName} via dados...`);
        const { data: sampleData, error: sampleError } = await supabase
          .from(tableName)
          .select('*')
          .limit(1);

        if (sampleError) {
          console.error(`  ❌ Erro ao buscar dados de ${tableName}:`, sampleError.message);
          continue;
        }

        if (sampleData && sampleData.length > 0) {
          const sample = sampleData[0];
          let ddl = `-- DDL inferido de dados de amostra\n`;
          ddl += `CREATE TABLE public.${tableName} (\n`;

          const columns = Object.keys(sample).map(col => {
            const value = sample[col];
            let type = 'text';

            if (typeof value === 'number') {
              type = Number.isInteger(value) ? 'bigint' : 'numeric';
            } else if (typeof value === 'boolean') {
              type = 'boolean';
            } else if (value instanceof Date || (typeof value === 'string' && !isNaN(Date.parse(value)))) {
              type = 'timestamp with time zone';
            }

            return `  ${col} ${type}`;
          });

          ddl += columns.join(',\n');
          ddl += `\n);\n`;

          const filePath = path.join(outputDir, `${tableName}.sql`);
          fs.writeFileSync(filePath, ddl);
          console.log(`  ✅ DDL inferido salvo em: ${filePath}`);
        }
        continue;
      }

      // Gerar DDL a partir do schema
      let ddl = `CREATE TABLE public.${tableName} (\n`;
      const columns = data.map(col => {
        let def = `  ${col.column_name} ${col.data_type}`;

        if (col.character_maximum_length) {
          def += `(${col.character_maximum_length})`;
        } else if (col.numeric_precision && col.numeric_scale) {
          def += `(${col.numeric_precision},${col.numeric_scale})`;
        }

        def += col.is_nullable === 'NO' ? ' NOT NULL' : ' NULL';

        if (col.column_default) {
          def += ` DEFAULT ${col.column_default}`;
        }

        return def;
      });

      ddl += columns.join(',\n');
      ddl += `\n);\n`;

      const filePath = path.join(outputDir, `${tableName}.sql`);
      fs.writeFileSync(filePath, ddl);
      console.log(`  ✅ DDL salvo em: ${filePath}`);

    } catch (err) {
      console.error(`  ❌ Erro ao processar ${tableName}:`, err.message);
    }
  }

  console.log('\n✅ Extração de DDL concluída!');
  console.log(`📁 Arquivos salvos em: ${path.resolve(outputDir)}`);
}

extractDDL().catch(console.error);
