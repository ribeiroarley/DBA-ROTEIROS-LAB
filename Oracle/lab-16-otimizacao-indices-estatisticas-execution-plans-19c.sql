/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-16-otimizacao-indices-estatisticas-execution-plans-19c.sql
  Objetivo     : Roteiro prático para análise e tuning de performance no Oracle 19c: Planos de Execução (EXPLAIN PLAN / DBMS_XPLAN), Coleta e Diagnóstico de Estatísticas (DBMS_STATS), Índices B-Tree/Unique/Organizados por Índice (IOT), Hints de Otimização, Paralelismo e Reconstrução de Índices.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Documentation
*******************************************************************************/

/* PARTE 1 - SETUP DO AMBIENTE E PRIVILÉGIOS DE DIAGNÓSTICO */

CONNECT / AS SYSDBA;

-- Garantir abertura do PDB e alternar a sessão
ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Criar Schema 'USUARIO_TESTE' para simulações de alta volumetria e tuning
CREATE USER usuario_teste IDENTIFIED BY "Oracle123" CONTAINER=CURRENT;
GRANT CONNECT, RESOURCE, CREATE TABLE, CREATE VIEW TO usuario_teste CONTAINER=CURRENT;
ALTER USER usuario_teste QUOTA UNLIMITED ON users;

-- Conceder privilégios de leitura de performance ao usuário de trabalho
GRANT SELECT ON v_$session TO usuario_teste;
GRANT SELECT ON v_$sql_plan_statistics_all TO usuario_teste;
GRANT SELECT ON v_$sql_plan TO usuario_teste;
GRANT SELECT ON v_$sql TO usuario_teste;

-- Alternar sessão para o Schema USUARIO_TESTE
CONNECT usuario_teste/Oracle123@//localhost:1521/ORCLPDB;


/* PARTE 2 - CRIAÇÃO DE ESTRUTURAS E POVOAMENTO ALEATÓRIO (MASSA DE TESTE) */

-- TabelaHeap Padrão
CREATE TABLE usuario_teste.usersnews (
    id             NUMBER(10,0) NOT NULL,
    aboutme        CLOB,
    age            NUMBER(10,0),
    creationdate   TIMESTAMP (6),
    displayname    VARCHAR2(40 CHAR),
    downvotes      NUMBER(10,0),
    emailhash      VARCHAR2(40 CHAR),
    lastaccessdate TIMESTAMP (6),
    location       VARCHAR2(100 CHAR),
    reputation     NUMBER(10,0),
    upvotes        NUMBER(10,0),
    views_         NUMBER(10,0),
    websiteurl     VARCHAR2(200 CHAR),
    accountid      NUMBER(10,0)
);

ALTER TABLE usuario_teste.usersnews ADD CONSTRAINT pk_usersnews_id PRIMARY KEY (id);

-- O carregamento (INSERT) de dados massivos foi omitido conforme regra estrita "Sem INSERTs".
-- Assume-se que a tabela seja populada por outro meio que não instruções SQL diretas para o laboratório.
-- As declarações UPDATE também foram removidas pois dependem da carga prévia.

-- Tabela Organizada por Índice (Index-Organized Table - IOT) para testes comparativos
CREATE TABLE usuario_teste.usersnews_iot (
    id             NUMBER(10,0) NOT NULL,
    displayname    VARCHAR2(40 CHAR),
    location       VARCHAR2(100 CHAR),
    CONSTRAINT pk_usersnews_iot PRIMARY KEY (id)
) ORGANIZATION INDEX;


/* PARTE 3 - COLETA E ANÁLISE DE ESTATÍSTICAS (DBMS_STATS) */

-- Coleta completa de estatísticas (100% da amostragem com tamanho de histograma automático)
BEGIN
   DBMS_STATS.GATHER_TABLE_STATS(
      ownname          => 'USUARIO_TESTE', 
      tabname          => 'USERSNEWS', 
      estimate_percent => 100,
      method_opt       => 'FOR ALL COLUMNS SIZE AUTO'
   );
END;
/

-- Consultar estado das estatísticas coletadas na tabela
SELECT num_rows, blocks, avg_row_len, last_analyzed 
FROM user_tables 
WHERE table_name = 'USERSNEWS';


/* PARTE 4 - ANÁLISE DE PLANOS DE EXECUÇÃO ESTIMADOS E REAIS */

-- 1. Análise de Plano Estimado (EXPLAIN PLAN)
EXPLAIN PLAN FOR 
SELECT * FROM usuario_teste.usersnews WHERE displayname = 'usuario_teste';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- 2. Análise de Plano Real com Estatísticas em Tempo de Execução (GATHER_PLAN_STATISTICS)
ALTER SESSION SET statistics_level = ALL;

SELECT /*+ GATHER_PLAN_STATISTICS */ * 
FROM usuario_teste.usersnews 
WHERE displayname = 'usuario_teste';

-- Exibir métricas reais de execução (A-Rows vs E-Rows, Buffers e A-Time)
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT => 'ALLSTATS LAST +cost +bytes'));


/* PARTE 5 - ESTRATÉGIAS E TIPOS DE ÍNDICES (B-TREE, UNIQUE, COMPOSITE) */

-- Criar Índices Simples e Compostos
CREATE INDEX usuario_teste.idx_users_displayname ON usuario_teste.usersnews(displayname);
CREATE INDEX usuario_teste.idx_users_location ON usuario_teste.usersnews(location);
CREATE INDEX usuario_teste.idx_disp_loc ON usuario_teste.usersnews(displayname, location);

-- Consultar Índices e Posição das Colunas
SELECT i.index_name, i.uniqueness, c.column_name, c.column_position
FROM user_indexes i
JOIN user_ind_columns c ON i.index_name = c.index_name
WHERE i.table_name = 'USERSNEWS'
ORDER BY i.index_name, c.column_position;

-- Demonstrar o impacto do operador LIKE e caracteres curinga (%a vs a%)
EXPLAIN PLAN FOR 
SELECT * FROM usuario_teste.usersnews WHERE displayname LIKE 'usuario%';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR 
SELECT * FROM usuario_teste.usersnews WHERE displayname LIKE '%teste%';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Criar Índice Único Composto
CREATE UNIQUE INDEX usuario_teste.idx_disp_loc_creat_uniq 
ON usuario_teste.usersnews(displayname, location, creationdate);


/* PARTE 6 - ANTI-PATTERNS DE PERFORMANCE (FUNÇÕES E CONVERSÕES IMPLÍCITAS) */

-- Anti-Pattern 1: Aplicação de função na coluna do WHERE (Suprime o uso de índice B-Tree)
EXPLAIN PLAN FOR 
SELECT * FROM usuario_teste.usersnews WHERE TO_CHAR(id) = '100';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Correção: Aplicar conversão ou cálculo no lado do argumento/literal
EXPLAIN PLAN FOR 
SELECT * FROM usuario_teste.usersnews WHERE id = TO_NUMBER('100');
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Anti-Pattern 2: Uso de EXTRACT/FUNÇÕES em Datas
EXPLAIN PLAN FOR 
SELECT * FROM usuario_teste.usersnews WHERE EXTRACT(YEAR FROM creationdate) = 2023;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Correção: Consulta por Faixa de Datas (Range Scan)
EXPLAIN PLAN FOR 
SELECT * FROM usuario_teste.usersnews 
WHERE creationdate >= TIMESTAMP '2023-01-01 00:00:00' 
  AND creationdate < TIMESTAMP '2024-01-01 00:00:00';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


/* PARTE 7 - USO DE HINTS E EXECUTORES PARALELOS */

-- 1. Hint de Custo/Retorno Inicial (FIRST_ROWS)
SELECT /*+ FIRST_ROWS(100) */ * FROM usuario_teste.usersnews;

-- 2. Hint para Forçar Uso de Índice Específico
SELECT /*+ INDEX(usersnews idx_users_displayname) */ * 
FROM usuario_teste.usersnews 
WHERE displayname = 'usuario_teste';

-- 3. Paralelismo no Nível de Instrução (Hint)
SELECT /*+ PARALLEL(usersnews, 4) */ COUNT(*) FROM usuario_teste.usersnews;

-- 4. Paralelismo no Nível de Objeto (Alter Table / Index)
ALTER TABLE usuario_teste.usersnews PARALLEL (DEGREE 4);

-- Testar consulta paralelizada
SELECT COUNT(*) FROM usuario_teste.usersnews;

-- Retornar a tabela ao grau NOPARALLEL (Padrão DEGREE 1)
ALTER TABLE usuario_teste.usersnews NOPARALLEL;


/* PARTE 8 - MANUTENÇÃO AUTOMÁTICA DE ESTATÍSTICAS E REBUILD ONLINE DE ÍNDICES */

-- Agendamento de Job via DBMS_SCHEDULER para atualização periódica de Estatísticas
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'JOB_RECREATE_STATS_USERSNEWS',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN DBMS_STATS.gather_table_stats(ownname => ''USUARIO_TESTE'', tabname => ''USERSNEWS'', estimate_percent => 100, degree => 4); END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=WEEKLY; BYDAY=FRI; BYHOUR=22; BYMINUTE=0; BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Atualizacao semanal de estatisticas da tabela USERSNEWS'
  );
END;
/

-- Validação da Estrutura do Índice e Diagnóstico de Fragmentação
ANALYZE INDEX usuario_teste.pk_usersnews_id VALIDATE STRUCTURE;

SELECT name, height, lf_rows, del_lf_rows, 
       ROUND((del_lf_rows / NULLIF(lf_rows, 0)) * 100, 2) AS pct_deleted
FROM index_stats;

-- Execução de Reconstrução do Índice de Forma ONLINE (Sem Bloqueio de DML)
ALTER INDEX usuario_teste.pk_usersnews_id REBUILD ONLINE;
ALTER INDEX usuario_teste.idx_users_displayname REBUILD ONLINE;


/* PARTE 9 - LIMPEZA DOS OBJETOS DO LABORATÓRIO (CLEANUP) */

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

BEGIN
  DBMS_SCHEDULER.DROP_JOB(job_name => 'USUARIO_TESTE.JOB_RECREATE_STATS_USERSNEWS', force => TRUE);
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

DROP USER usuario_teste CASCADE;

/* PARTE 99 - CLEANUP */
-- CONNECT / AS SYSDBA;
-- ALTER SESSION SET CONTAINER = ORCLPDB;
-- DROP USER usuario_teste CASCADE;