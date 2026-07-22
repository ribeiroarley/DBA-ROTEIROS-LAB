/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-11-triggers-e-auditoria-mysql8.sql
  Objetivo     : Roteiro prático para criação, execução, validação e auditoria
                 utilizando Triggers (AFTER INSERT, AFTER DELETE, BEFORE INSERT),
                 tabelas de log/auditoria, pseudotabelas NEW e OLD, funções de
                 contexto de usuário/tempo no MySQL 8.x.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Triggers & Using Triggers
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SELEÇÃO DO SCHEMA E CRIAÇÃO DA TABELA DE AUDITORIA (INNODB)
--------------------------------------------------------------------------------

USE arley_cliente2;

-- Remover tabela de auditoria se existente
DROP TABLE IF EXISTS produto_auditoria;

-- Criar tabela de auditoria com Engine InnoDB e padrões modernos do MySQL 8.x
CREATE TABLE produto_auditoria (
  id INT NOT NULL AUTO_INCREMENT,
  productid INT NOT NULL,
  productname VARCHAR(50) NOT NULL,
  supplierid INT NOT NULL,
  unitprice DECIMAL(12,2) NOT NULL,
  package VARCHAR(30) NOT NULL,
  isdiscontinued TINYINT(1) NOT NULL,
  updatedat DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  db_user VARCHAR(100) NOT NULL,
  operation CHAR(3) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_operation CHECK (operation IN ('INS', 'DEL'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


--------------------------------------------------------------------------------
-- PARTE 2: CRIAÇÃO DE TRIGGERS DE AUDITORIA (AFTER INSERT E AFTER DELETE)
--------------------------------------------------------------------------------

-- Remover Triggers caso existam
DROP TRIGGER IF EXISTS trg_produto_auditoria_ins;
DROP TRIGGER IF EXISTS trg_produto_auditoria_del;

-- 1. Trigger AFTER INSERT (Captura novos registros utilizando a pseudotabela NEW)
DELIMITER $$

CREATE TRIGGER trg_produto_auditoria_ins AFTER INSERT 
ON product
FOR EACH ROW
BEGIN
    INSERT INTO produto_auditoria (
        productid, 
        productname,
        supplierid,
        unitprice,
        package,
        isdiscontinued,
        updatedat,
        db_user, 
        operation
    )
    VALUES (
        NEW.id,
        NEW.productname,
        NEW.supplierid,
        NEW.unitprice,
        NEW.package,
        NEW.isdiscontinued,
        NOW(),
        USER(),
        'INS'
    );
END$$

DELIMITER ;

-- 2. Trigger AFTER DELETE (Captura exclusões utilizando a pseudotabela OLD)
DELIMITER $$

CREATE TRIGGER trg_produto_auditoria_del AFTER DELETE 
ON product
FOR EACH ROW
BEGIN
    INSERT INTO produto_auditoria (
        productid, 
        productname,
        supplierid,
        unitprice,
        package,
        isdiscontinued,
        updatedat,
        db_user, 
        operation
    )
    VALUES (
        OLD.id,
        OLD.productname,
        OLD.supplierid,
        OLD.unitprice,
        OLD.package,
        OLD.isdiscontinued,
        NOW(),
        USER(),
        'DEL'
    );
END$$

DELIMITER ;

-- Inspecionar as Triggers registradas no schema ativo
SHOW TRIGGERS FROM arley_cliente2;


--------------------------------------------------------------------------------
-- PARTE 3: TESTES PRÁTICOS E VALIDAÇÃO DA AUDITORIA
--------------------------------------------------------------------------------

-- Consultar tabela de auditoria antes das alterações
SELECT * FROM produto_auditoria;

-- Inserir novo produto na tabela principal
INSERT INTO product (id, productname, supplierid, unitprice, package, isdiscontinued)
VALUES (100, 'Produto Teste A', 1, 150.00, '10 pkgs', 0);

-- Validar o registro capturado automaticamente na auditoria (Operação INS)
SELECT * FROM produto_auditoria WHERE productid = 100;

-- Excluir o produto inserido
DELETE FROM product WHERE id = 100;

-- Validar a captura do evento de exclusão na auditoria (Operação DEL)
SELECT * FROM produto_auditoria WHERE productid = 100 ORDER BY id ASC;


--------------------------------------------------------------------------------
-- PARTE 4: TESTES DE TRIGGERS BEFORE (VALIDAÇÕES E CÁLCULOS PRÉVIOS)
--------------------------------------------------------------------------------

-- Criar estrutura para teste de gatilho de validação prévia
DROP TABLE IF EXISTS account;
DROP TRIGGER IF EXISTS trg_account_before_ins;

CREATE TABLE account (
  acct_num INT NOT NULL PRIMARY KEY,
  amount DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Trigger BEFORE INSERT acumulando soma em variável de sessão
DELIMITER $$

CREATE TRIGGER trg_account_before_ins BEFORE INSERT 
ON account
FOR EACH ROW
BEGIN
    SET @sum_total = IFNULL(@sum_total, 0) + NEW.amount;
END$$

DELIMITER ;

-- Inicializar variável de sessão e realizar inserções
SET @sum_total = 0;

INSERT INTO account VALUES (101, 50.00), (102, 150.50), (103, -20.00);

-- Consultar o total acumulado calculado pelo gatilho BEFORE
SELECT @sum_total AS total_processado_trigger;

SELECT * FROM account;


--------------------------------------------------------------------------------
-- PARTE 5: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

-- Remover Triggers criadas
DROP TRIGGER IF EXISTS trg_produto_auditoria_ins;
DROP TRIGGER IF EXISTS trg_produto_auditoria_del;
DROP TRIGGER IF EXISTS trg_account_before_ins;

-- Remover tabelas auxiliares de teste
DROP TABLE IF EXISTS produto_auditoria;
DROP TABLE IF EXISTS account;

-- Resetar variáveis de sessão
SET @sum_total = NULL;