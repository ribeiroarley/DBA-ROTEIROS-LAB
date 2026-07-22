/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-15-parametros-instancia-memoria-performance-19c.sql
  Objetivo     : Roteiro prático para gestão de Parâmetros de Inicialização (PFILE e SPFILE),
                 Arquitetura de Memória (AMM vs ASMM), Ajuste do Log Buffer, Diagnóstico
                 de Eventos de Espera (Wait Events) e Execução Paralela (Parallelism)
                 no Oracle Database 19c Multitenant (CDB/PDB).
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Database Administrator's Guide / Database Performance Tuning Guide
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: GESTÃO E MANIPULAÇÃO DE PFILE E SPFILE
--------------------------------------------------------------------------------

-- Conectar como SYSDBA no Container Root (CDB$ROOT)
CONNECT / AS SYSDBA;

-- Consultar o arquivo de parâmetros em uso pela instância atual
SHOW PARAMETER spfile;

-- Consultar todos os parâmetros de inicialização e seus valores padrão
SELECT name, value, default_value 
FROM v$parameter 
ORDER BY name;

-- Criar um PFILE em formato texto a partir do SPFILE ativo
CREATE PFILE = 'C:\app\administrator\product\19.0.0\dbhome_1\database\initORCL_bkp.ora' 
FROM SPFILE;

/*
  -- Exemplo de alteração de parâmetro estático e dinâmico:
  -- Dinâmico (Escopo MEMORY, SPFILE ou BOTH):
  ALTER SYSTEM SET open_cursors = 300 SCOPE=BOTH;

  -- Estático (Requer reinicialização do banco de dados):
  ALTER SYSTEM SET processes = 500 SCOPE=SPFILE;
*/


--------------------------------------------------------------------------------
-- PARTE 2: GERENCIAMENTO DE MEMÓRIA (AMM vs ASMM)
--------------------------------------------------------------------------------

-- Consultar alocação atual de memória (AMM e ASMM) em MBytes
SELECT name, ROUND(value / 1024 / 1024, 2) AS value_mb
FROM v$parameter
WHERE name IN (
    'memory_max_target',
    'memory_target',
    'sga_max_size',
    'sga_target',
    'pga_aggregate_limit',
    'pga_aggregate_target'
)
ORDER BY name;

-- Configuração do modo ASMM (Automatic Shared Memory Management)
-- 1. Zerar parâmetros do AMM para ativar o ASMM
ALTER SYSTEM SET memory_max_target = 0 SCOPE=SPFILE;
ALTER SYSTEM SET memory_target = 0 SCOPE=SPFILE;

-- 2. Definir limites explícitos de SGA e PGA
ALTER SYSTEM SET sga_max_size = 8G SCOPE=SPFILE;
ALTER SYSTEM SET sga_target = 7G SCOPE=SPFILE;
ALTER SYSTEM SET pga_aggregate_limit = 4096M SCOPE=SPFILE;
ALTER SYSTEM SET pga_aggregate_target = 2000M SCOPE=SPFILE;

/*
  -- Procedimento de reinicialização para aplicar alterações no SPFILE:
  SHUTDOWN IMMEDIATE;
  STARTUP;
*/

/*
  -- PROCEDIMENTO DE RECOVERY EM CASO DE ERRO DE CONFIGURAÇÃO DE MEMÓRIA (ex: ORA-00093):
  -- Iniciar o banco utilizando o PFILE de contingência previamente gerado:
  STARTUP PFILE='C:\app\administrator\product\19.0.0\dbhome_1\database\initORCL_bkp.ora';
  
  -- Recriar o SPFILE corrigido a partir do PFILE:
  CREATE SPFILE FROM PFILE='C:\app\administrator\product\19.0.0\dbhome_1\database\initORCL_bkp.ora';
  
  SHUTDOWN IMMEDIATE;
  STARTUP;
*/


--------------------------------------------------------------------------------
-- PARTE 3: OTIMIZAÇÃO DE REDO LOG BUFFER E WAIT EVENTS DE I/O
--------------------------------------------------------------------------------

-- Consultar tamanho atual do Log Buffer
SHOW PARAMETER log_buffer;

-- Alterar tamanho do LOG_BUFFER (Requer salvamento no SPFILE e restart)
ALTER SYSTEM SET log_buffer = 128M SCOPE=SPFILE;

-- Consultar eventos de espera de buffer e gravação no Redo Log
SELECT event, total_waits, time_waited, ROUND(time_waited / NULLIF(total_waits, 0), 2) AS avg_wait_ms
FROM v$system_event
WHERE event LIKE '%log file%' OR event LIKE '%buffer%'
ORDER BY total_waits DESC;

-- Identificar sessões impactadas por latência de gravação de logs (log file sync)
SELECT sid, serial#, username, event, state, seconds_in_wait
FROM v$session
WHERE event = 'log file sync';

-- Métricas globais de contenção de Redo
SELECT name, value
FROM v$sysstat
WHERE name IN ('redo log space requests', 'redo buffer allocation retries', 'redo log space wait time');


--------------------------------------------------------------------------------
-- PARTE 4: CONFIGURAÇÃO DE EXECUÇÃO PARALELA (PARALLELISM)
--------------------------------------------------------------------------------

-- Consultar política atual de grau de paralelismo
SELECT name, value FROM v$parameter WHERE name = 'parallel_degree_policy';

-- Alterar política de paralelismo no nível do sistema
-- Opções: MANUAL (Padrão), LIMITED, AUTO
ALTER SYSTEM SET parallel_degree_policy = 'LIMITED' SCOPE=BOTH;
ALTER SYSTEM SET parallel_degree_policy = 'MANUAL' SCOPE=BOTH;

-- Habilitar paralelismo forçado apenas para a sessão atual
ALTER SESSION FORCE PARALLEL QUERY;
ALTER SESSION FORCE PARALLEL DML;

-- Desabilitar paralelismo da sessão e retornar ao controle do otimizador
ALTER SESSION DISABLE PARALLEL QUERY;
ALTER SESSION DISABLE PARALLEL DML;


--------------------------------------------------------------------------------
-- PARTE 5: PARALELISMO EM NÍVEL DE OBJETOS (TABELAS E ÍNDICES)
--------------------------------------------------------------------------------

-- Alternar para o PDB de trabalho
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Criar ambiente de teste no PDB
CREATE USER arleyribeiro IDENTIFIED BY "arley123" CONTAINER=CURRENT;
GRANT CONNECT, RESOURCE TO arleyribeiro CONTAINER=CURRENT;
ALTER USER arleyribeiro QUOTA UNLIMITED ON users;

CREATE TABLE arleyribeiro.tb_perf_test (
    id   NUMBER PRIMARY KEY,
    nome VARCHAR2(50),
    data DATE
);

CREATE INDEX arleyribeiro.idx_tb_perf_nome ON arleyribeiro.tb_perf_test(nome);

-- Configurar grau de paralelismo explícito para Tabela e Índice
ALTER TABLE arleyribeiro.tb_perf_test PARALLEL (DEGREE 4);
ALTER INDEX arleyribeiro.idx_tb_perf_nome PARALLEL (DEGREE 4);

-- Consultar grau de paralelismo atribuído aos objetos
SELECT table_name, degree FROM dba_tables WHERE owner = 'ARLEYRIBEIRO' AND table_name = 'TB_PERF_TEST';
SELECT index_name, degree FROM dba_indexes WHERE owner = 'ARLEYRIBEIRO' AND index_name = 'IDX_TB_PERF_NOME';

-- Remover paralelismo dos objetos (Retornar ao padrão NOPARALLEL / DEGREE 1)
ALTER TABLE arleyribeiro.tb_perf_test NOPARALLEL;
ALTER INDEX arleyribeiro.idx_tb_perf_nome NOPARALLEL;


--------------------------------------------------------------------------------
-- PARTE 6: LIMPEZA DOS OBJETOS DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

DROP USER arleyribeiro CASCADE;