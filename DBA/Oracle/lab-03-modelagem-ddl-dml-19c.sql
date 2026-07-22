/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-03-modelagem-ddl-dml-19c.sql
  Objetivo     : Laboratório prático cobrindo criação de Schemas, concessão de 
                 privilégios granulares, criação de tabelas (DDL), carga de 
                 dados (DML), persistência automática de PDBs e controle de 
                 transações (COMMIT/ROLLBACK) no Oracle Database 19c.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Database Administrator's Guide
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: CRIAÇÃO E CONFIGURAÇÃO DO SCHEMA 'LIVRARIA' (SYSDBA)
--------------------------------------------------------------------------------

-- Conectar como SYSDBA e garantir abertura do PDB padrão
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Criar o usuário/schema LIVRARIA
CREATE USER livraria IDENTIFIED BY "a123" CONTAINER=CURRENT;

-- Configurar tablespaces padrão e cota de armazenamento
ALTER USER livraria
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users
  ACCOUNT UNLOCK;

-- Conceder privilégios administrativos e de conexão para estudos
GRANT CONNECT, RESOURCE TO livraria CONTAINER=CURRENT;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE TO livraria CONTAINER=CURRENT;


--------------------------------------------------------------------------------
-- PARTE 2: GERENCIAMENTO DE PRIVILÉGIOS E SCHEMA 'CLIENTE'
--------------------------------------------------------------------------------

-- Criar o usuário/schema CLIENTE
CREATE USER cliente IDENTIFIED BY "a123" CONTAINER=CURRENT;

-- Configurar cota e privilégios granulares
ALTER USER cliente 
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users
  ACCOUNT UNLOCK;

GRANT CONNECT TO cliente CONTAINER=CURRENT;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE TRIGGER TO cliente CONTAINER=CURRENT;


--------------------------------------------------------------------------------
-- PARTE 3: PERSISTÊNCIA AUTOMÁTICA DE INICIALIZAÇÃO DO PDB (SAVE STATE)
--------------------------------------------------------------------------------

CONNECT / AS SYSDBA;

-- Configurar o PDB para abrir automaticamente em READ WRITE quando o CDB iniciar
ALTER PLUGGABLE DATABASE ORCLPDB SAVE STATE;

-- Verificar o estado salvo na view do dicionário de dados
SELECT instance_name, con_name, state FROM v$system_parameter WHERE name = 'pdb_plug_in_violations';
SELECT con_name, instance_name, state FROM dba_pdb_saved_states;


--------------------------------------------------------------------------------
-- PARTE 4: CRIAÇÃO DAS TABELAS (DDL) NO SCHEMA 'CLIENTE'
--------------------------------------------------------------------------------

CONNECT cliente/a123@//localhost:1521/ORCLPDB;

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


--------------------------------------------------------------------------------
-- PARTE 5: CARGA DE DADOS (DML) NO SCHEMA 'CLIENTE'
--------------------------------------------------------------------------------

-- Inserindo dados na tabela Customer
INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES (1, 'Maria', 'Anders', 'Berlin', 'Germany', '030-0074321');
INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES (2, 'Ana', 'Trujillo', 'México D.F.', 'Mexico', '(56) 555-4729');
INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES (3, 'Antonio', 'Moreno', 'México D.F.', 'Mexico', '(56) 555-3932');
INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES (4, 'Thomas', 'Hardy', 'London', 'UK', '(256) 555-7788');
INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES (5, 'Christina', 'Berglund', 'Luleå', 'Sweden', '0921-12 34 65');
INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES (15, 'Arley', 'Ribeiro', 'Sao Paulo', 'Brazil', '(11) 555-7647');
INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES (78, 'Liu', 'Wong', 'Butte', 'USA', '(406) 555-5834');
INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES (84, 'Mary', 'Saveley', 'Lyon', 'France', '78.32.54.86');

-- Inserindo dados na tabela Supplier
INSERT INTO supplier (id, companyname, contactname, city, country, phone, fax) VALUES (1, 'Exotic Liquids', 'Charlotte Cooper', 'London', 'UK', '(56) 555-2222', NULL);
INSERT INTO supplier (id, companyname, contactname, city, country, phone, fax) VALUES (2, 'New Orleans Cajun Delights', 'Shelley Burke', 'New Orleans', 'USA', '(100) 555-4822', NULL);
INSERT INTO supplier (id, companyname, contactname, city, country, phone, fax) VALUES (3, 'Grandma Kellys Homestead', 'Regina Murphy', 'Ann Arbor', 'USA', '(313) 555-5735', '(313) 555-3349');

-- Inserindo dados na tabela Product
INSERT INTO product (id, productname, supplierid, unitprice, package, isdiscontinued) VALUES (1, 'Chai', 1, 18.00, '10 boxes x 20 bags', 0);
INSERT INTO product (id, productname, supplierid, unitprice, package, isdiscontinued) VALUES (2, 'Chang', 1, 19.00, '24 - 12 oz bottles', 0);
INSERT INTO product (id, productname, supplierid, unitprice, package, isdiscontinued) VALUES (11, 'Queso Cabrales', 2, 21.00, '1 kg pkg.', 0);

-- Inserindo dados na tabela "order"
INSERT INTO "order" (id, orderdate, customerid, totalamount, ordernumber) VALUES (1, TO_DATE('01/01/2023', 'DD/MM/YYYY'), 78, 1863.40, '542379');
INSERT INTO "order" (id, orderdate, customerid, totalamount, ordernumber) VALUES (2, TO_DATE('01/01/2023', 'DD/MM/YYYY'), 78, 1863.40, '542379');
INSERT INTO "order" (id, orderdate, customerid, totalamount, ordernumber) VALUES (3, TO_DATE('01/01/2023', 'DD/MM/YYYY'), 15, 1813.00, '542380');
INSERT INTO "order" (id, orderdate, customerid, totalamount, ordernumber) VALUES (4, TO_DATE('01/01/2023', 'DD/MM/YYYY'), 84, 670.80, '542381');

-- Inserindo dados na tabela OrderItem
INSERT INTO orderitem (id, orderid, productid, unitprice, quantity) VALUES (1, 1, 11, 14.00, 12);
INSERT INTO orderitem (id, orderid, productid, unitprice, quantity) VALUES (2, 1, 1, 9.80, 10);
INSERT INTO orderitem (id, orderid, productid, unitprice, quantity) VALUES (3, 3, 2, 15.20, 20);


--------------------------------------------------------------------------------
-- PARTE 6: CONTROLE DE TRANSAÇÕES (ROLLBACK E COMMIT)
--------------------------------------------------------------------------------

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

-- Reexecutar as inserções principais para efetivar a gravação
INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES (1, 'Maria', 'Anders', 'Berlin', 'Germany', '030-0074321');
INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES (15, 'Arley', 'Ribeiro', 'Sao Paulo', 'Brazil', '(11) 555-7647');
INSERT INTO supplier (id, companyname, contactname, city, country, phone, fax) VALUES (1, 'Exotic Liquids', 'Charlotte Cooper', 'London', 'UK', '(56) 555-2222', NULL);
INSERT INTO product (id, productname, supplierid, unitprice, package, isdiscontinued) VALUES (1, 'Chai', 1, 18.00, '10 boxes x 20 bags', 0);
INSERT INTO "order" (id, orderdate, customerid, totalamount, ordernumber) VALUES (1, TO_DATE('01/01/2023', 'DD/MM/YYYY'), 15, 1863.40, '542379');
INSERT INTO orderitem (id, orderid, productid, unitprice, quantity) VALUES (1, 1, 1, 18.00, 10);

-- Confirmar e persistir permanentemente os dados no disco (Datafiles)
COMMIT;

-- Teste pós-commit (o ROLLBACK não reverterá dados já commitados)
ROLLBACK;

SELECT * FROM customer;
SELECT * FROM "order";


--------------------------------------------------------------------------------
-- PARTE 7: CLEANUP DO LABORATÓRIO (OPCIONAL)
--------------------------------------------------------------------------------

/*
CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;
DROP USER cliente CASCADE;
DROP USER livraria CASCADE;
*/