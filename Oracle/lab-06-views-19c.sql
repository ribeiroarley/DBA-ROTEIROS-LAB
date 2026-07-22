/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-06-views-19c.sql
  Objetivo     : Roteiro prático sobre criação, alteração (CREATE OR REPLACE), 
                 consultas, manipulação DML via Views simples, Views com JOINs, 
                 Views encadeadas, uso de FETCH FIRST e exclusão no 
                 Oracle Database 19c Multitenant (CDB/PDB).
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Administrator's Guide / SQL Language Reference
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: AMBIENTAÇÃO E PRIVILÉGIOS (SYSDBA / CLIENTE)
--------------------------------------------------------------------------------

-- Conectar como SYSDBA e garantir contexto no PDB
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Conceder privilégio explícito de criação de Views para o Schema CLIENTE
GRANT CREATE VIEW TO cliente CONTAINER=CURRENT;

-- Alternar sessão para o Schema CLIENTE
CONNECT cliente/a123@//localhost:1521/ORCLPDB;


--------------------------------------------------------------------------------
-- PARTE 2: VIEW SIMPLES E OPERAÇÕES DML VIA VIEW
--------------------------------------------------------------------------------

-- Consulta base da tabela Customer
SELECT * FROM cliente.customer;

-- Criar View para filtrar clientes residentes em Madrid
CREATE OR REPLACE VIEW cliente.vw_custumer_madrid AS
SELECT id, firstname, lastname, city, country, phone
FROM cliente.customer 
WHERE city = 'Madrid';

-- Consultando a View
SELECT * FROM cliente.vw_custumer_madrid;

-- Consultando a View aplicando filtro adicional
SELECT * 
FROM cliente.vw_custumer_madrid 
WHERE phone LIKE '%555%';

-- Inserindo registro compatível com o filtro da View (Será visível na tabela e na View)
INSERT INTO cliente.vw_custumer_madrid (id, firstname, lastname, city, country, phone)
VALUES (102, 'arley', 'ribeiro de madrid', 'Madrid', 'Spain', '9999999');

-- Inserindo registro não compatível com o filtro da View (Visível na tabela base, mas não na View)
INSERT INTO cliente.vw_custumer_madrid (id, firstname, lastname, city, country, phone)
VALUES (103, 'arley', 'ribeiro do porto', 'Porto', 'Portugal', '9999999');

COMMIT;

-- Validação da visibilidade dos dados
SELECT * FROM cliente.vw_custumer_madrid;
SELECT * FROM cliente.customer WHERE lastname = 'ribeiro do porto';

-- Exclusão de registro através da View
DELETE FROM cliente.vw_custumer_madrid 
WHERE lastname = 'ribeiro de madrid';

COMMIT;

-- Validação da remoção do registro na tabela base
SELECT * FROM cliente.customer WHERE lastname = 'ribeiro de madrid';


--------------------------------------------------------------------------------
-- PARTE 3: VIEW COM JOINS E EXTRAÇÃO DE DATAS (EXTRACT)
--------------------------------------------------------------------------------

-- Criar View agregando vendas diárias utilizando funções nativas de data
CREATE OR REPLACE VIEW cliente.dailysales AS
SELECT
    EXTRACT(YEAR FROM o.orderdate) AS y,
    EXTRACT(MONTH FROM o.orderdate) AS m,
    EXTRACT(DAY FROM o.orderdate) AS d,
    p.id AS product_id,
    p.productname,
    (i.quantity * i.unitprice) AS sales
FROM cliente."order" o
INNER JOIN cliente.orderitem i ON o.id = i.orderid
INNER JOIN cliente.product p   ON p.id = i.productid;

-- Consultas na View com ordenação e agregação
SELECT * 
FROM cliente.dailysales 
ORDER BY y, m, d, sales DESC;

SELECT y AS ano, m AS mes, SUM(sales) AS vendas_mes
FROM cliente.dailysales
GROUP BY y, m
ORDER BY ano ASC, mes DESC;


--------------------------------------------------------------------------------
-- PARTE 4: ALTERAÇÃO DE VIEWS (CREATE OR REPLACE VIEW)
--------------------------------------------------------------------------------

-- Modificar a estrutura da View adicionando colunas do cliente
CREATE OR REPLACE VIEW cliente.dailysales AS
SELECT
    EXTRACT(YEAR FROM o.orderdate) AS y,
    EXTRACT(MONTH FROM o.orderdate) AS m,
    EXTRACT(DAY FROM o.orderdate) AS d,
    p.id AS product_id,
    p.productname,
    (i.quantity * i.unitprice) AS sales,
    c.firstname, 
    c.lastname
FROM cliente."order" o
INNER JOIN cliente.customer c  ON c.id = o.customerid 
INNER JOIN cliente.orderitem i ON o.id = i.orderid
INNER JOIN cliente.product p   ON p.id = i.productid;

-- Validar a estrutura atualizada
SELECT * 
FROM cliente.dailysales 
ORDER BY y, m, d, sales DESC;


--------------------------------------------------------------------------------
-- PARTE 5: VIEWS ENCADEADAS (VIEW BASEADA EM OUTRA VIEW)
--------------------------------------------------------------------------------

-- Criar View secundária com limitação de linhas (FETCH FIRST 5 ROWS ONLY)
CREATE OR REPLACE VIEW cliente.dailysalefilha AS
SELECT 
    firstname || ' ' || lastname AS nomecompleto, 
    SUM(d.sales) AS totalsales
FROM cliente.dailysales d
GROUP BY firstname, lastname
FETCH FIRST 5 ROWS ONLY;

SELECT * FROM cliente.dailysalefilha;

-- Redefinir View secundária adicionando ordenação interna (ORDER BY)
CREATE OR REPLACE VIEW cliente.dailysalefilha AS
SELECT 
    firstname || ' ' || lastname AS nomecompleto, 
    SUM(d.sales) AS totalsales
FROM cliente.dailysales d
GROUP BY firstname, lastname
ORDER BY firstname;

-- Teste de sobreposição de ordenação
SELECT * FROM cliente.dailysalefilha;
SELECT * FROM cliente.dailysalefilha ORDER BY totalsales DESC;


--------------------------------------------------------------------------------
-- PARTE 6: EXCLUSÃO DE VIEWS (DROP VIEW) E DICIONÁRIO DE DADOS
--------------------------------------------------------------------------------

-- Remover Views criadas
DROP VIEW cliente.dailysalefilha;
DROP VIEW cliente.dailysales;
DROP VIEW cliente.vw_custumer_madrid;

-- Recompor View principal para histórico do laboratório
CREATE OR REPLACE VIEW cliente.dailysales AS
SELECT
    EXTRACT(YEAR FROM o.orderdate) AS y,
    EXTRACT(MONTH FROM o.orderdate) AS m,
    EXTRACT(DAY FROM o.orderdate) AS d,
    p.id AS product_id,
    p.productname,
    (i.quantity * i.unitprice) AS sales,
    c.firstname, 
    c.lastname
FROM cliente."order" o
INNER JOIN cliente.customer c  ON c.id = o.customerid 
INNER JOIN cliente.orderitem i ON o.id = i.orderid
INNER JOIN cliente.product p   ON p.id = i.productid;

-- Verificar Views existentes pertencentes ao usuário conectado
SELECT view_name, text_length 
FROM user_views 
ORDER BY view_name;

-- Limpeza de dados de teste inseridos na tabela Customer
DELETE FROM cliente.customer WHERE id IN (102, 103);
COMMIT;