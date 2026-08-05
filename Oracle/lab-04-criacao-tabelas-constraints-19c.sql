/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-04-criacao-tabelas-constraints-19c.sql
  Objetivo     : Roteiro prático para criação do Schema 'USUARIO_TESTE' e definição de DDL com Primary Keys e Foreign Keys no Oracle Database 19c.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Documentation
*******************************************************************************/

/* PARTE 1 - SETUP DO SCHEMA E PERMISSÕES (SYSDBA) */

-- Conectar como SYSDBA e garantir o contexto do PDB
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Criar o Schema USUARIO_TESTE caso ainda não exista
CREATE USER usuario_teste IDENTIFIED BY "teste123" CONTAINER=CURRENT;

-- Conceder quota e privilégios necessários
ALTER USER usuario_teste 
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users
  ACCOUNT UNLOCK;

GRANT CONNECT, RESOURCE TO usuario_teste CONTAINER=CURRENT;
GRANT CREATE TABLE TO usuario_teste CONTAINER=CURRENT;


/* PARTE 2 - CRIAÇÃO DAS TABELAS E CONSTRAINTS (DDL) */

-- Alternar a sessão para conectar diretamente com o usuário USUARIO_TESTE
CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;

-- 1. Tabela Supplier (Fornecedores)
CREATE TABLE usuario_teste.supplier (
  id           NUMBER NOT NULL,
  companyname  VARCHAR2(40),
  contactname  VARCHAR2(50),
  contacttitle VARCHAR2(40),
  city         VARCHAR2(40),
  country      VARCHAR2(40),
  phone        VARCHAR2(30),
  fax          VARCHAR2(30),
  CONSTRAINT pk_supplier PRIMARY KEY (id)
);

-- 2. Tabela Product (Produtos)
CREATE TABLE usuario_teste.product (
  id             NUMBER NOT NULL,
  productname    VARCHAR2(50),
  supplierid     NUMBER NOT NULL,
  unitprice      NUMBER(12, 2),
  package        VARCHAR2(30),
  isdiscontinued NUMBER(1),
  CONSTRAINT pk_product PRIMARY KEY (id),
  CONSTRAINT fk_product_supplier1 FOREIGN KEY (supplierid)
    REFERENCES usuario_teste.supplier (id)
);

-- 3. Tabela Customer (Clientes)
CREATE TABLE usuario_teste.customer (
  id        NUMBER NOT NULL,
  firstname VARCHAR2(40),
  lastname  VARCHAR2(40),
  city      VARCHAR2(40),
  country   VARCHAR2(40),
  phone     VARCHAR2(20),
  CONSTRAINT pk_customer PRIMARY KEY (id)
);

-- 4. Tabela "order" (Pedidos - Palavra Reservada tratada com Aspas Duplas)
CREATE TABLE usuario_teste."order" (
  id          NUMBER NOT NULL,
  orderdate   DATE,
  ordernumber VARCHAR2(10),
  customerid  NUMBER NOT NULL,
  totalamount NUMBER(12, 2),
  CONSTRAINT pk_order PRIMARY KEY (id),
  CONSTRAINT fk_order_customer1 FOREIGN KEY (customerid)
    REFERENCES usuario_teste.customer (id)
);

-- 5. Tabela OrderItem (Itens do Pedido)
CREATE TABLE usuario_teste.orderitem (
  id        NUMBER NOT NULL,
  orderid   NUMBER NOT NULL,
  productid NUMBER NOT NULL,
  unitprice NUMBER(12, 2),
  quantity  NUMBER,
  CONSTRAINT pk_orderitem PRIMARY KEY (id),
  CONSTRAINT fk_orderitem_product1 FOREIGN KEY (productid)
    REFERENCES usuario_teste.product (id),
  CONSTRAINT fk_orderitem_order1 FOREIGN KEY (orderid)
    REFERENCES usuario_teste."order" (id)
);


/* PARTE 3 - VALIDAÇÃO DAS TABELAS E CONSTRAINTS NO DICIONÁRIO DE DADOS */

-- Listar tabelas criadas no Schema do usuário conectado
SELECT table_name 
FROM user_tables 
ORDER BY table_name;

-- Consultar as Primary Keys e Foreign Keys criadas
SELECT 
    constraint_name, 
    constraint_type, 
    table_name, 
    r_constraint_name 
FROM user_constraints 
WHERE table_name IN ('SUPPLIER', 'PRODUCT', 'CUSTOMER', 'order', 'ORDERITEM')
ORDER BY table_name, constraint_type;

/* PARTE 99 - CLEANUP */
CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;
DROP USER usuario_teste CASCADE;