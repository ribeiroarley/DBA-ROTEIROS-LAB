/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-03-modelagem-ddl-dml-19c.sql
  Objetivo     : Laboratório prático cobrindo criação de Schemas, concessão de privilégios granulares, criação de tabelas (DDL), carga de dados (DML), persistência automática de PDBs e controle de transações (COMMIT/ROLLBACK) no Oracle Database 19c.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Documentation
*******************************************************************************/

/* PARTE 1 - CRIAÇÃO E CONFIGURAÇÃO DO SCHEMA 'TESTE' (SYSDBA) */

-- Conectar como SYSDBA e garantir abertura do PDB padrão
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Criar o usuário/schema TESTE
CREATE USER teste IDENTIFIED BY "teste123" CONTAINER=CURRENT;

-- Configurar tablespaces padrão e cota de armazenamento
ALTER USER teste
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users
  ACCOUNT UNLOCK;

-- Conceder privilégios administrativos e de conexão para estudos
GRANT CONNECT, RESOURCE TO teste CONTAINER=CURRENT;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE TO teste CONTAINER=CURRENT;


/* PARTE 2 - GERENCIAMENTO DE PRIVILÉGIOS E SCHEMA 'USUARIO_TESTE' */

-- Criar o usuário/schema USUARIO_TESTE
CREATE USER usuario_teste IDENTIFIED BY "teste123" CONTAINER=CURRENT;

-- Configurar cota e privilégios granulares
ALTER USER usuario_teste 
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users
  ACCOUNT UNLOCK;

GRANT CONNECT TO usuario_teste CONTAINER=CURRENT;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE TRIGGER TO usuario_teste CONTAINER=CURRENT;


/* PARTE 3 - PERSISTÊNCIA AUTOMÁTICA DE INICIALIZAÇÃO DO PDB (SAVE STATE) */

CONNECT / AS SYSDBA;

-- Configurar o PDB para abrir automaticamente em READ WRITE quando o CDB iniciar
ALTER PLUGGABLE DATABASE ORCLPDB SAVE STATE;

-- Verificar o estado salvo na view do dicionário de dados
SELECT instance_name, con_name, state FROM v$system_parameter WHERE name = 'pdb_plug_in_violations';
SELECT con_name, instance_name, state FROM dba_pdb_saved_states;


/* PARTE 4 - CRIAÇÃO DAS TABELAS (DDL) NO SCHEMA 'USUARIO_TESTE' */

CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;

CREATE TABLE customer (
    id        NUMBER NOT NULL,
    firstname VARCHAR2(40),
    lastname  VARCHAR2(40),
    city      VARCHAR2(40),
    country   VARCHAR2(40),
    phone     VARCHAR2(20),
    CONSTRAINT customer_pk PRIMARY KEY (id)
);

CREATE TABLE supplier (
    id           NUMBER NOT NULL,
    companyname  VARCHAR2(40),
    contactname  VARCHAR2(50),
    contacttitle VARCHAR2(40),
    city         VARCHAR2(40),
    country      VARCHAR2(40),
    phone        VARCHAR2(30),
    fax          VARCHAR2(30),
    CONSTRAINT supplier_pk PRIMARY KEY (id)
);

CREATE TABLE product (
    id             NUMBER NOT NULL,
    productname    VARCHAR2(50),
    supplierid     NUMBER NOT NULL,
    unitprice      NUMBER(12, 2),
    package        VARCHAR2(30),
    isdiscontinued NUMBER(1),
    CONSTRAINT product_pk PRIMARY KEY (id),
    CONSTRAINT fk_product_supplier1 FOREIGN KEY (supplierid) REFERENCES supplier (id)
);

-- Tabela com nome reservado utilizando aspas duplas
CREATE TABLE "order" (
    id          NUMBER NOT NULL,
    orderdate   DATE,
    ordernumber VARCHAR2(10),
    customerid  NUMBER NOT NULL,
    totalamount NUMBER(12, 2),
    CONSTRAINT order_pk PRIMARY KEY (id),
    CONSTRAINT fk_order_customer1 FOREIGN KEY (customerid) REFERENCES customer (id)
);

CREATE TABLE orderitem (
    id        NUMBER NOT NULL,
    orderid   NUMBER NOT NULL,
    productid NUMBER NOT NULL,
    unitprice NUMBER(12, 2),
    quantity  NUMBER,
    CONSTRAINT orderitem_pk PRIMARY KEY (id),
    CONSTRAINT fk_orderitem_order1 FOREIGN KEY (orderid) REFERENCES "order" (id),
    CONSTRAINT fk_orderitem_product1 FOREIGN KEY (productid) REFERENCES product (id)
);


/* PARTE 5 - CARGA DE DADOS (DML) NO SCHEMA 'USUARIO_TESTE' */

-- (Comandos INSERT foram removidos como política de segurança e limpeza)


/* PARTE 6 - CONTROLE DE TRANSAÇÕES (ROLLBACK E COMMIT) */

-- Validar contagem antes de confirmar a transação
SELECT COUNT(*) FROM customer;
SELECT COUNT(*) FROM supplier;
SELECT COUNT(*) FROM product;
SELECT COUNT(*) FROM "order";
SELECT COUNT(*) FROM orderitem;

-- Teste de cancelamento da transação pendente (desfaz as inserções não commitadas)
ROLLBACK;

-- Confirmar que as tabelas estão vazias após o ROLLBACK
SELECT COUNT(*) FROM customer;

-- Confirmar e persistir permanentemente os dados no disco (Datafiles)
COMMIT;

-- Teste pós-commit (o ROLLBACK não reverterá dados já commitados)
ROLLBACK;

SELECT * FROM customer;
SELECT * FROM "order";


/* PARTE 7 - CLEANUP DO LABORATÓRIO */

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;
DROP USER usuario_teste CASCADE;
DROP USER teste CASCADE;