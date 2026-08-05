/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-30-performance-tuning.sql
  Objetivo     : Tuning de Buffer Pool, Redo Log, flush_method e I/O Capacity
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Optimization and Indexes
*******************************************************************************/

-- 1. InnoDB Buffer Pool
-- Visualizar configuração atual
SELECT @@innodb_buffer_pool_size;
SHOW GLOBAL VARIABLES LIKE 'innodb_buffer_pool_size';

-- Alterar a quente (Exemplo: 2GB)
SET GLOBAL innodb_buffer_pool_size = 2147483648;

-- Em my.ini / my.cnf:
-- [mysqld]
-- innodb_buffer_pool_size=2G

-- 2. InnoDB Redo Log
-- A partir do MySQL 8.0.30, innodb_log_file_size e innodb_log_files_in_group foram depreciados em favor do innodb_redo_log_capacity.
-- Para retrocompatibilidade ou versões anteriores a 8.0.30:
-- innodb_log_file_size=128M
-- innodb_log_files_in_group=3

-- Alterar o tamanho do buffer de log
-- SHOW GLOBAL VARIABLES LIKE 'innodb_log_buffer_size';
-- Em my.ini / my.cnf:
-- innodb_log_buffer_size=16M

-- Verificar esperas de log
SHOW GLOBAL STATUS LIKE 'innodb_log_waits';

-- Desativar o Redo Logging temporariamente (útil para grandes cargas de dados, NUNCA usar em produção)
ALTER INSTANCE DISABLE INNODB REDO_LOG;
ALTER INSTANCE ENABLE INNODB REDO_LOG;

-- 3. Transações e Sincronismo (my.ini / my.cnf)
-- Padrão ACID completo e seguro:
-- innodb_flush_log_at_trx_commit=1
-- sync_binlog=1

-- Para maior performance com risco de perda de 1 segundo de dados em caso de falha de SO/Energia:
-- innodb_flush_log_at_trx_commit=2
-- sync_binlog=0

-- 4. Flush Method (Ambientes Linux)
-- Reduz a necessidade de acesso ao disco para buscar dados, evitando duplo cache (SO + MySQL).
-- innodb_flush_method=O_DIRECT

-- 5. Otimização de I/O
-- Controla as operações de gravação (write) I/O no disco.
-- Exemplo para discos SSD:
SET PERSIST innodb_io_capacity = 4000;
SET PERSIST innodb_io_capacity_max = 8000;

-- 6. Table Open Cache
SHOW GLOBAL STATUS LIKE 'Opened_tables';
-- Se aumentar rapidamente, ajustar no my.ini:
-- table_open_cache=4000
