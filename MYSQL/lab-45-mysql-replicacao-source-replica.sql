/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-45-mysql-replicacao-source-replica.sql
  Objetivo     : Configuração, Troubleshooting e Sincronização Source-Replica
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Replication
*******************************************************************************/

-- -----------------------------------------------------------------------------
-- FASE 1: CONFIGURAÇÃO NO SERVIDOR SOURCE (PRIMÁRIO)
-- -----------------------------------------------------------------------------

-- 1. Criação do usuário de replicação
CREATE USER 'usuario_teste'@'%' IDENTIFIED BY 'SenhaTeste123!';

-- 2. Concessão de privilégios para replicação
GRANT REPLICATION SLAVE ON *.* TO 'usuario_teste'@'%';
FLUSH PRIVILEGES;

-- 3. Verificação do status do binlog no Source para configuração inicial
-- Guarde o nome do arquivo (File) e a posição (Position)
SHOW MASTER STATUS; 

-- -----------------------------------------------------------------------------
-- FASE 2: CONFIGURAÇÃO NO SERVIDOR REPLICA (SECUNDÁRIO)
-- -----------------------------------------------------------------------------

-- 1. Parar a replicação caso esteja em andamento e resetar as configurações
STOP REPLICA;
RESET REPLICA ALL;

-- 2. Configurar o apontamento para o Source (MySQL 8.0.22+)
-- Substituir SOURCE_LOG_FILE e SOURCE_LOG_POS pelos valores obtidos no SHOW MASTER STATUS
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = 'localhost',
  SOURCE_USER = 'usuario_teste',
  SOURCE_PASSWORD = 'SenhaTeste123!',
  SOURCE_PORT = 3306,
  SOURCE_LOG_FILE = 'DBSRV-bin.000001',
  SOURCE_LOG_POS = 157,
  GET_SOURCE_PUBLIC_KEY = 1;

-- 3. Iniciar a replicação
START REPLICA;

-- 4. Verificar o status da replicação
-- Replica_IO_Running e Replica_SQL_Running devem estar como 'Yes'
SHOW REPLICA STATUS\G

-- -----------------------------------------------------------------------------
-- FASE 3: TESTE UNITÁRIO DE REPLICAÇÃO
-- -----------------------------------------------------------------------------

-- No Source (3306):
CREATE SCHEMA db_teste;
CREATE TABLE db_teste.tabela_replicacao (
  id INT NOT NULL AUTO_INCREMENT,
  descricao VARCHAR(50) NULL,
  PRIMARY KEY (id)
);
INSERT INTO db_teste.tabela_replicacao (descricao) VALUES ('Teste Unitario Replicacao');

-- Na Replica (3307):
-- Validar se o banco, a tabela e o registro foram criados
SELECT * FROM db_teste.tabela_replicacao;

-- -----------------------------------------------------------------------------
-- FASE 4: TROUBLESHOOTING E SINCRONIZAÇÃO (DESAFIO)
-- -----------------------------------------------------------------------------
-- Caso a replicação quebre ou perca o sincronismo, existem abordagens para
-- restaurar o estado consistente.

-- ABORDAGEM 1: DUMP LÓGICO COM LOCK
-- No Source:
-- RESET MASTER;
-- FLUSH TABLES WITH READ LOCK;
-- SHOW MASTER STATUS;
-- Em outro terminal, realizar o mysqldump e depois rodar UNLOCK TABLES;
-- Na Replica:
-- Subir o dump e reconfigurar com os novos valores de binlog e position usando CHANGE REPLICATION SOURCE TO.

-- ABORDAGEM 2: CÓPIA FÍSICA A FRIO DE DIRETÓRIOS
-- 1. Parar a Replica (STOP REPLICA)
-- 2. Fazer shutdown do Source (SHUTDOWN)
-- 3. Copiar o diretório de dados físico (data) do Source para a Replica.
-- 4. Deletar o arquivo auto.cnf na pasta de destino da Replica (para gerar novo UUID).
-- 5. Iniciar o Source e capturar o SHOW MASTER STATUS.
-- 6. Iniciar a Replica, resetar as configurações e apontar para a nova posição.
