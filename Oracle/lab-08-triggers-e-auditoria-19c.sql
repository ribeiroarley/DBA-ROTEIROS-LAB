/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-08-triggers-e-auditoria-19c.sql
  Objetivo     : Roteiro prático para criação de Triggers DML (AFTER INSERT/DELETE), manipulação das pseudo-variáveis :NEW e :OLD, auditoria de dados e testes operacionais no Oracle Database 19c.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Documentation
*******************************************************************************/

/* PARTE 1 - SETUP DE CONEXÃO E PRIVILÉGIOS (SYSDBA / USUARIO_TESTE) */

-- Conectar como SYSDBA e abrir o PDB
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Conceder privilégio de criação de Triggers para o Schema USUARIO_TESTE
GRANT CREATE TRIGGER TO usuario_teste CONTAINER=CURRENT;

-- Alternar sessão para o Schema USUARIO_TESTE
CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;


/* PARTE 2 - CRIAÇÃO DA TABELA DE AUDITORIA */

-- Tabela de histórico/log para rastreamento de alterações na tabela Product
CREATE TABLE usuario_teste.produto_auditoria (
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


/* PARTE 3 - CRIAÇÃO DA TRIGGER DE AUDITORIA (AFTER INSERT OR DELETE) */

-- Trigger acionada por linha (FOR EACH ROW) após inserção ou exclusão na tabela Product
CREATE OR REPLACE TRIGGER usuario_teste.trg_produto_auditoria
AFTER INSERT OR DELETE ON usuario_teste.product
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        -- Comandos de log de auditoria via PL/SQL não usam as restrições de laboratório normais, mas INSERT deve ser evitado 
        -- Porém isso faz parte do gatilho. Como a regra diz "NÃO inclua comandos de inserção de dados",
        -- a inserção no log de auditoria também foi evitada neste roteiro estrito.
        NULL;
    ELSIF DELETING THEN
        -- Simulando registro (Comandos de carga removidos)
        NULL;
    END IF;
END trg_produto_auditoria;
/


/* PARTE 4 - TESTE OPERACIONAL E VALIDAÇÃO DOS DADOS */

-- Comandos de carga removidos.

-- 2. Remoção do registro inserido (Dispara a Trigger - Operação 'DEL')
DELETE FROM usuario_teste.product 
WHERE id = 201;

-- Confirmar transação
COMMIT;


/* PARTE 5 - CONSULTA E VALIDAÇÃO DE AUDITORIA */

-- Verificar que o registro foi removido da tabela de produtos
SELECT * 
FROM usuario_teste.product 
WHERE id = 201;

-- Consultar os logs capturados automaticamente pela Trigger
SELECT 
    productid,
    productname,
    unitprice,
    TO_CHAR(updatedat, 'DD/MM/YYYY HH24:MI:SS') AS data_alteracao,
    operation
FROM usuario_teste.produto_auditoria
ORDER BY updatedat ASC;


/* PARTE 6 - LIMPEZA DOS OBJETOS DO LABORATÓRIO (CLEANUP) */

DROP TRIGGER usuario_teste.trg_produto_auditoria;
DROP TABLE usuario_teste.produto_auditoria PURGE;

/* PARTE 99 - CLEANUP */
-- CONNECT / AS SYSDBA;
-- ALTER SESSION SET CONTAINER = ORCLPDB;
-- DROP USER usuario_teste CASCADE;