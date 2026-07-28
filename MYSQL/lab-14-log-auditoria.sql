/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-14-log-auditoria.sql
  Objetivo     : Configuracao e analise do log geral e slow query log
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

-- 1. Verificar configuracoes de log
SHOW VARIABLES LIKE 'general_log%';
SHOW VARIABLES LIKE 'slow_query_log%';

-- 2. Ativar log geral temporariamente
SET GLOBAL general_log = 1;
SET GLOBAL log_output = 'table';

-- 3. Visualizar log
SELECT *, CONVERT(argument USING utf8) as argumentSQL FROM mysql.general_log;

-- 4. Ativar slow query log
SET GLOBAL slow_query_log = 1;
SET GLOBAL long_query_time = 0.5;

-- CLEANUP
SET GLOBAL general_log = 0;
SET GLOBAL slow_query_log = 0;
TRUNCATE mysql.general_log;
TRUNCATE mysql.slow_log;
