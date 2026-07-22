/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-04-criacao-tabelas-constraints-19c.sql
  Objetivo     : Roteiro prático para criação do Schema 'CLIENTE' e definição de 
                 DDL com Primary Keys e Foreign Keys no Oracle Database 19c.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c SQL Language Reference
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SETUP DO SCHEMA E PERMISSÕES (SYSDBA)
--------------------------------------------------------------------------------

-- Conectar como SYSDBA e garantir o contexto do PDB
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Criar o Schema CLIENTE caso ainda não exista
CREATE USER cliente IDENTIFIED BY "a123" CONTAINER=CURRENT;

-- Conceder quota e privilégios necessários
ALTER USER cliente 
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users
  ACCOUNT UNLOCK;

GRANT CONNECT, RESOURCE TO cliente CONTAINER=CURRENT;
GRANT CREATE TABLE TO cliente CONTAINER=CURRENT;


--------------------------------------------------------------------------------
-- PARTE 2: CRIAÇÃO DAS TABELAS E CONSTRAINTS (DDL)
--------------------------------------------------------------------------------

-- Alternar a sessão para conectar diretamente com o usuário CLIENTE
CONNECT cliente/a123@//localhost:1521/ORCLPDB;

-- 1. Tabela Supplier (Fornecedores)
CREATE TABLE cliente.supplier (
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
CREATE TABLE cliente.product (
  id             NUMBER NOT NULL,
  productname    VARCHAR2(50),
  supplierid     NUMBER NOT NULL,
  unitprice      NUMBER(12, 2),
  package        VARCHAR2(30),
  isdiscontinued NUMBER(1),
  CONSTRAINT pk_product PRIMARY KEY (id),
  CONSTRAINT fk_product_supplier1 FOREIGN KEY (supplierid)
    REFERENCES cliente.supplier (id)
);

-- 3. Tabela Customer (Clientes)
CREATE TABLE cliente.customer (
  id        NUMBER NOT NULL,
  firstname VARCHAR2(40),
  lastname  VARCHAR2(40),
  city      VARCHAR2(40),
  country   VARCHAR2(40),
  phone     VARCHAR2(20),
  CONSTRAINT pk_customer PRIMARY KEY (id)
);

-- 4. Tabela "order" (Pedidos - Palavra Reservada tratada com Aspas Duplas)
CREATE TABLE cliente."order" (
  id          NUMBER NOT NULL,
  orderdate   DATE,
  ordernumber VARCHAR2(10),
  customerid  NUMBER NOT NULL,
  totalamount NUMBER(12, 2),
  CONSTRAINT pk_order PRIMARY KEY (id),
  CONSTRAINT fk_order_customer1 FOREIGN KEY (customerid)
    REFERENCES cliente.customer (id)
);

-- 5. Tabela OrderItem (Itens do Pedido)
CREATE TABLE cliente.orderitem (
  id        NUMBER NOT NULL,
  orderid   NUMBER NOT NULL,
  productid NUMBER NOT NULL,
  unitprice NUMBER(12, 2),
  quantity  NUMBER,
  CONSTRAINT pk_orderitem PRIMARY KEY (id),
  CONSTRAINT fk_orderitem_product1 FOREIGN KEY (productid)
    REFERENCES cliente.product (id),
  CONSTRAINT fk_orderitem_order1 FOREIGN KEY (orderid)
    REFERENCES cliente."order" (id)
);


--------------------------------------------------------------------------------
-- PARTE 3: VALIDAÇÃO DAS TABELAS E CONSTRAINTS NO DICIONÁRIO DE DADOS
--------------------------------------------------------------------------------

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