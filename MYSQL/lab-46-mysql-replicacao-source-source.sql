/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-46-mysql-replicacao-source-source.sql
  Objetivo     : Configuração de Replicação Bidirecional (Source-Source)
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Replication
*******************************************************************************/

-- -----------------------------------------------------------------------------
-- PRÉ-REQUISITOS (my.cnf / my.ini)
-- -----------------------------------------------------------------------------
-- Para evitar conflitos de chaves primárias na topologia Source-Source, 
-- configure os offsets de auto-incremento de forma distinta em cada servidor.

/*
# No Servidor Source 1 (Ex: 192.168.1.160)
[mysqld]
server-id=1
auto_increment_increment=10
auto_increment_offset=1
# A sequência de IDs gerados será: 1, 11, 21, 31...

# No Servidor Source 2 (Ex: 192.168.1.180)
[mysqld]
server-id=2
auto_increment_increment=10
auto_increment_offset=2
# A sequência de IDs gerados será: 2, 12, 22, 32...
*/

-- -----------------------------------------------------------------------------
-- CONFIGURAÇÃO DE SEGURANÇA E USUÁRIOS
-- -----------------------------------------------------------------------------
-- Executar em AMBOS os servidores:

CREATE USER 'usuario_teste'@'%' IDENTIFIED BY 'SenhaTeste123!';
GRANT REPLICATION SLAVE ON *.* TO 'usuario_teste'@'%';
FLUSH PRIVILEGES;

-- -----------------------------------------------------------------------------
-- CONFIGURANDO SOURCE 2 COMO REPLICA DO SOURCE 1
-- -----------------------------------------------------------------------------
-- 1. No Source 1, obtenha os dados do binlog:
SHOW MASTER STATUS;
-- Guarde o File e Position.

-- 2. No Source 2, aponte para o Source 1:
STOP REPLICA;
RESET REPLICA ALL;

CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = '192.168.1.160',
  SOURCE_USER = 'usuario_teste',
  SOURCE_PASSWORD = 'SenhaTeste123!',
  SOURCE_PORT = 3306,
  SOURCE_LOG_FILE = 'binlog.000001',
  SOURCE_LOG_POS = 157,
  GET_SOURCE_PUBLIC_KEY = 1;

START REPLICA;
SHOW REPLICA STATUS\G

-- -----------------------------------------------------------------------------
-- CONFIGURANDO SOURCE 1 COMO REPLICA DO SOURCE 2
-- -----------------------------------------------------------------------------
-- 1. No Source 2, obtenha os dados do binlog:
SHOW MASTER STATUS;
-- Guarde o File e Position.

-- 2. No Source 1, aponte para o Source 2:
STOP REPLICA;
RESET REPLICA ALL;

CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = '192.168.1.180',
  SOURCE_USER = 'usuario_teste',
  SOURCE_PASSWORD = 'SenhaTeste123!',
  SOURCE_PORT = 3306,
  SOURCE_LOG_FILE = 'binlog.000002',
  SOURCE_LOG_POS = 157,
  GET_SOURCE_PUBLIC_KEY = 1;

START REPLICA;
SHOW REPLICA STATUS\G

-- -----------------------------------------------------------------------------
-- TESTE UNITÁRIO DE VALIDAÇÃO (BIDIRECIONAL)
-- -----------------------------------------------------------------------------

-- No Source 1:
CREATE SCHEMA db_teste;
USE db_teste;
CREATE TABLE tabela_bidirecional (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50)
);
INSERT INTO tabela_bidirecional (nome) VALUES ('Teste Source 1');

-- No Source 2:
-- Validar que o banco, a tabela e o registro do Source 1 chegaram:
USE db_teste;
SELECT * FROM tabela_bidirecional;
-- O ID retornado deve corresponder ao offset do Source 1 (Ex: 1).

-- Inserir novo registro no Source 2:
INSERT INTO tabela_bidirecional (nome) VALUES ('Teste Source 2');

-- No Source 1:
-- Validar que o registro do Source 2 foi recebido corretamente sem colisões.
SELECT * FROM tabela_bidirecional;
-- O ID inserido pelo Source 2 deve respeitar o offset do Source 2 (Ex: 2).
