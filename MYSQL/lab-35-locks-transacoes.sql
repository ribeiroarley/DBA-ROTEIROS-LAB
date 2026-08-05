/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-35-locks-transacoes.sql
  Objetivo     : Laboratório de Transações, Níveis de Isolamento, Table/Row Locks e Deadlocks
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / InnoDB Locking and Transaction Model
*******************************************************************************/

-- -----------------------------------------------------------------------------
-- PREPARAÇÃO DO AMBIENTE
-- -----------------------------------------------------------------------------
DROP DATABASE IF EXISTS teste;
CREATE DATABASE teste;
USE teste;

CREATE TABLE produto (
  produto_id INT NOT NULL,
  produto_nome VARCHAR(100) NOT NULL,
  produto_tipo VARCHAR(50) NULL,
  preco DECIMAL(10,2) NULL,
  quantidade INT NULL,
  PRIMARY KEY (produto_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Inserindo dados realistas, apenas com caracteres alfanumericos
INSERT INTO produto (produto_id, produto_nome, produto_tipo, preco, quantidade) VALUES 
(1, 'Notebook Pro 15', 'Eletronico', 4500.00, 10),
(2, 'Monitor Ultrawide', 'Eletronico', 1200.00, 20),
(3, 'Teclado Mecanico', 'Acessorio', 350.00, 30),
(4, 'Mouse Sem Fio', 'Acessorio', 150.00, 50),
(5, 'Cadeira Ergonomica', 'Movel', 800.00, 15);

-- -----------------------------------------------------------------------------
-- TESTE DE NIVEIS DE ISOLAMENTO
-- -----------------------------------------------------------------------------
-- Visualizar o nivel de isolamento atual da sessao e global
SHOW SESSION VARIABLES LIKE '%transaction_isolation%';
SHOW GLOBAL VARIABLES LIKE '%transaction_isolation%';

-- Alterando o nivel de isolamento da sessao atual para READ COMMITTED
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Confirmando a alteracao
SHOW SESSION VARIABLES LIKE '%transaction_isolation%';

-- Teste de transacao READ ONLY
SET SESSION TRANSACTION READ ONLY;
-- INSERT INTO produto (produto_id, produto_nome, produto_tipo, preco, quantidade) VALUES (6, 'Teste', 'Outros', 10.00, 5);
-- Error Code: 1792. Cannot execute statement in a READ ONLY transaction.

-- Voltando para modo leitura e escrita
SET SESSION TRANSACTION READ WRITE;

-- -----------------------------------------------------------------------------
-- TESTE DE TABLE LOCK
-- -----------------------------------------------------------------------------
-- O comando LOCK TABLES bloqueia a tabela inteira, impedindo outras sessoes de 
-- lerem (se for WRITE) ou gravarem (se for READ ou WRITE).

-- Desativar o autocommit para controle manual da transacao
SET autocommit = 0;

-- Adquirindo bloqueio exclusivo (WRITE) na tabela inteira
LOCK TABLES produto WRITE;

-- Visualizando o bloqueio no Performance Schema (MySQL 8.x)
SELECT OBJECT_TYPE, OBJECT_SCHEMA, OBJECT_NAME, LOCK_TYPE, LOCK_DURATION, LOCK_STATUS 
FROM performance_schema.metadata_locks 
WHERE OBJECT_NAME = 'produto';

-- Operacao DML enquanto a tabela esta bloqueada
UPDATE produto SET quantidade = quantidade - 1 WHERE produto_id = 1;

-- Efetuando o commit e liberando a tabela
COMMIT;
UNLOCK TABLES;

-- Retornando o autocommit para o padrao
SET autocommit = 1;

-- -----------------------------------------------------------------------------
-- TESTE DE ROW LOCK
-- -----------------------------------------------------------------------------
-- O InnoDB utiliza ROW LOCK por padrao nas operacoes DML.
SET autocommit = 0;

START TRANSACTION;

-- Adquire um bloqueio exclusivo apenas na linha correspondente ao produto_id = 1
UPDATE produto SET quantidade = quantidade + 10 WHERE produto_id = 1;

-- Forcando um Row Lock em leituras usando FOR UPDATE
SELECT * FROM produto WHERE produto_id = 2 FOR UPDATE;

-- Visualizando os data locks (MySQL 8.x)
SELECT ENGINE_TRANSACTION_ID, OBJECT_NAME, INDEX_NAME, LOCK_TYPE, LOCK_MODE, LOCK_STATUS, LOCK_DATA 
FROM performance_schema.data_locks 
WHERE OBJECT_NAME = 'produto';

-- Em outra sessao, um UPDATE no produto_id = 1 ficaria em status WAITING
-- Um UPDATE no produto_id = 3 seria executado normalmente

COMMIT;
SET autocommit = 1;

-- -----------------------------------------------------------------------------
-- SIMULACAO DE DEADLOCK
-- -----------------------------------------------------------------------------
-- Um Deadlock ocorre quando duas ou mais transacoes ficam aguardando
-- mutuamente a liberacao de locks.

-- SESSAO 1:
-- SET autocommit = 0;
-- START TRANSACTION;
-- UPDATE produto SET quantidade = quantidade + 100 WHERE produto_id = 1;

-- SESSAO 2:
-- SET autocommit = 0;
-- START TRANSACTION;
-- UPDATE produto SET preco = preco + 100 WHERE produto_id = 2;

-- SESSAO 1:
-- UPDATE produto SET preco = preco + 10 WHERE produto_id = 2; 
-- (Fica em WAITING, pois produto_id = 2 esta com lock na SESSAO 2)

-- SESSAO 2:
-- UPDATE produto SET quantidade = quantidade + 100 WHERE produto_id = 1;
-- (Ocorre o DEADLOCK - O MySQL detecta e cancela automaticamente uma das transacoes)

-- Verificando logs de Deadlock
-- SHOW ENGINE INNODB STATUS;
-- (Procurar pela secao LATEST DETECTED DEADLOCK)
