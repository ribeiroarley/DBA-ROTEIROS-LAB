/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-08-triggers-e-auditoria-19c.sql
  Objetivo     : Roteiro prático para criação de Triggers DML (AFTER INSERT/DELETE),
                 manipulação das pseudo-variáveis :NEW e :OLD, auditoria de dados 
                 e testes operacionais no Oracle Database 19c.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Database PL/SQL Language Reference
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SETUP DE CONEXÃO E PRIVILÉGIOS (SYSDBA / CLIENTE)
--------------------------------------------------------------------------------

-- Conectar como SYSDBA e abrir o PDB
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Conceder privilégio de criação de Triggers para o Schema CLIENTE
GRANT CREATE TRIGGER TO cliente CONTAINER=CURRENT;

-- Alternar sessão para o Schema CLIENTE
CONNECT cliente/a123@//localhost:1521/ORCLPDB;


--------------------------------------------------------------------------------
-- PARTE 2: CRIAÇÃO DA TABELA DE AUDITORIA
--------------------------------------------------------------------------------

-- Tabela de histórico/log para rastreamento de alterações na tabela Product
CREATE TABLE cliente.produto_auditoria (
    productid      NUMBER NOT NULL,
    productname    VARCHAR2(50) NOT NULL,
    supplierid     NUMBER NOT NULL,
    unitprice      NUMBER(12, 2) NOT NULL,
    package        VARCHAR2(30) NOT NULL,
    isdiscontinued NUMBER(1) NOT NULL,
    updatedat      DATE NOT NULL,
    operation      CHAR(3) NOT NULL,
    CONSTRAINT chk_prod_aud_op CHECK (operation IN ('INS', 'DEL'))
);


--------------------------------------------------------------------------------
-- PARTE 3: CRIAÇÃO DA TRIGGER DE AUDITORIA (AFTER INSERT OR DELETE)
--------------------------------------------------------------------------------

-- Trigger acionada por linha (FOR EACH ROW) após inserção ou exclusão na tabela Product
CREATE OR REPLACE TRIGGER cliente.trg_produto_auditoria
AFTER INSERT OR DELETE ON cliente.product
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO cliente.produto_auditoria (
            productid,
            productname,
            supplierid,
            unitprice,
            package,
            isdiscontinued,
            updatedat,
            operation
        ) VALUES (
            :NEW.id,
            :NEW.productname,
            :NEW.supplierid,
            :NEW.unitprice,
            :NEW.package,
            :NEW.isdiscontinued,
            SYSDATE,
            'INS'
        );
    ELSIF DELETING THEN
        INSERT INTO cliente.produto_auditoria (
            productid,
            productname,
            supplierid,
            unitprice,
            package,
            isdiscontinued,
            updatedat,
            operation
        ) VALUES (
            :OLD.id,
            :OLD.productname,
            :OLD.supplierid,
            :OLD.unitprice,
            :OLD.package,
            :OLD.isdiscontinued,
            SYSDATE,
            'DEL'
        );
    END IF;
END trg_produto_auditoria;
/


--------------------------------------------------------------------------------
-- PARTE 4: TESTE OPERACIONAL E VALIDAÇÃO DOS DADOS
--------------------------------------------------------------------------------

-- 1. Inserção de registro na tabela base (Dispara a Trigger - Operação 'INS')
INSERT INTO cliente.product (
    id,
    productname,
    supplierid,
    unitprice,
    package,
    isdiscontinued
) VALUES (
    201,
    'Produto A - Teste Arley',
    1,
    19.99,
    'Pacote A',
    0
);

-- 2. Remoção do registro inserido (Dispara a Trigger - Operação 'DEL')
DELETE FROM cliente.product 
WHERE id = 201;

-- Confirmar transação
COMMIT;


--------------------------------------------------------------------------------
-- PARTE 5: CONSULTA E VALIDAÇÃO DE AUDITORIA
--------------------------------------------------------------------------------

-- Verificar que o registro foi removido da tabela de produtos
SELECT * 
FROM cliente.product 
WHERE id = 201;

-- Consultar os logs capturados automaticamente pela Trigger
SELECT 
    productid,
    productname,
    unitprice,
    TO_CHAR(updatedat, 'DD/MM/YYYY HH24:MI:SS') AS data_alteracao,
    operation
FROM cliente.produto_auditoria
ORDER BY updatedat ASC;


--------------------------------------------------------------------------------
-- PARTE 6: LIMPEZA DOS OBJETOS DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

/*
DROP TRIGGER cliente.trg_produto_auditoria;
DROP TABLE cliente.produto_auditoria PURGE;
*/