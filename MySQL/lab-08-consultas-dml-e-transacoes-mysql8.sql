/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-08-consultas-dml-e-transacoes-mysql8.sql
  Objetivo     : Roteiro de estudos práticos abrangendo DML (SELECT, INSERT, UPDATE,
                 DELETE, TRUNCATE), junções (JOINs), agregações, subqueries, 
                 funções ANSI/MySQL 8.x, controle de transações (ACID/Safe Updates)
                 e alteração DDL de colunas AUTO_INCREMENT.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Optimization and DML
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SELEÇÃO DO SCHEMA E CONSULTAS BÁSICAS (SELECT, WHERE, ORDER BY, LIMIT)
--------------------------------------------------------------------------------

USE arley_cliente2;

-- Seleção simples de colunas
SELECT firstname, lastname, city 
FROM customer;

-- Filtro com predicado de igualdade
SELECT id, firstname, lastname, city, country, phone
FROM customer
WHERE country = 'Sweden';

-- Ordenação ascendente e descendente
SELECT companyname, contactname, city, country
FROM supplier
ORDER BY companyname ASC;

SELECT companyname, contactname, city, country
FROM supplier
ORDER BY companyname DESC;

-- Paginação e limitação de resultados (Padrão LIMIT no MySQL)
SELECT id, productname, unitprice, package
FROM product
ORDER BY unitprice DESC
LIMIT 5;

-- Remoção de duplicidades (DISTINCT)
SELECT DISTINCT country
FROM supplier
ORDER BY country;


--------------------------------------------------------------------------------
-- PARTE 2: FUNÇÕES DE AGREGAÇÃO E AGRUPAMENTO (GROUP BY, HAVING)
--------------------------------------------------------------------------------

-- Mínimo, Máximo, Soma, Média e Contagem
SELECT MIN(unitprice) AS menor_preco, MAX(unitprice) AS maior_preco 
FROM product;

SELECT COUNT(id) AS total_clientes 
FROM customer;

SELECT SUM(totalamount) AS total_vendas, AVG(totalamount) AS media_vendas
FROM `order`
WHERE YEAR(orderdate) = 2012;

-- Agrupamento por país com ordenação
SELECT country, COUNT(id) AS total_clientes
FROM customer
GROUP BY country
ORDER BY total_clientes DESC;

-- Agrupamento com filtro sobre o resultado agregado (HAVING)
SELECT country, COUNT(id) AS total_clientes
FROM customer
WHERE country <> 'USA'
GROUP BY country
HAVING COUNT(id) >= 5
ORDER BY total_clientes DESC;

-- Vendas agregadas por cliente
SELECT customerid, 
       COUNT(id) AS qtvendas, 
       SUM(totalamount) AS valortotal,  
       AVG(totalamount) AS mediavendas, 
       MIN(totalamount) AS menorvenda, 
       MAX(totalamount) AS maiorvenda
FROM `order`
GROUP BY customerid
ORDER BY qtvendas DESC;


--------------------------------------------------------------------------------
-- PARTE 3: JUNÇÕES (INNER JOIN, LEFT JOIN, RIGHT JOIN) E CONCATENAÇÃO
--------------------------------------------------------------------------------

-- Inner Join entre Pedidos e Clientes
SELECT o.ordernumber, o.totalamount, c.firstname, c.lastname, c.city, c.country
FROM `order` o
INNER JOIN customer c ON o.customerid = c.id;

-- Inner Join de múltiplas tabelas com conversão de data (CONVERT)
SELECT o.ordernumber, 
       CONVERT(o.orderdate, DATE) AS data_pedido, 
       p.productname, 
       i.quantity, 
       i.unitprice
FROM `order` o
INNER JOIN orderitem i ON o.id = i.orderid
INNER JOIN product p ON p.id = i.productid
ORDER BY o.ordernumber;

-- Left Join (Todos os clientes, com ou sem pedidos)
SELECT c.firstname, c.lastname, c.city, c.country, o.ordernumber, o.totalamount
FROM customer c
LEFT JOIN `order` o ON o.customerid = c.id
ORDER BY o.totalamount;

-- Right Join (Identificação de clientes sem pedidos associados)
SELECT c.firstname, c.lastname, c.city, c.country
FROM `order` o
RIGHT JOIN customer c ON o.customerid = c.id
WHERE o.totalamount IS NULL;

-- Operador UNION com concatenação ANSI no MySQL (CONCAT)
SELECT 'Customer' AS tipo, 
       CONCAT(firstname, ' ', lastname) AS nome_contato, 
       city, country, phone
FROM customer
UNION
SELECT 'Supplier' AS tipo, 
       contactname AS nome_contato, 
       city, country, phone
FROM supplier;


--------------------------------------------------------------------------------
-- PARTE 4: SUBQUERIES E OPERADORES LÓGICOS (IN, EXISTS, NOT EXISTS)
--------------------------------------------------------------------------------

-- Subquery com IN
SELECT productname
FROM product
WHERE id IN (
    SELECT productid 
    FROM orderitem 
    WHERE quantity > 10
);

-- Subquery correlacionada no SELECT
SELECT c.id, c.firstname, c.lastname,
       (SELECT COUNT(o.id) FROM `order` o WHERE o.customerid = c.id) AS total_pedidos
FROM customer c;

-- Subquery com EXISTS (Fornecedores com produtos acima de R$ 100)
SELECT companyname
FROM supplier s
WHERE EXISTS (
    SELECT 1 
    FROM product p 
    WHERE p.supplierid = s.id AND p.unitprice > 100.00
);

-- Subquery com NOT EXISTS
SELECT companyname
FROM supplier s
WHERE NOT EXISTS (
    SELECT 1 
    FROM product p 
    WHERE p.supplierid = s.id AND p.unitprice > 100.00
);


--------------------------------------------------------------------------------
-- PARTE 5: MANIPULAÇÃO DE ESTRUTURAS TEMPORÁRIAS E DML (CREATE TABLE AS SELECT)
--------------------------------------------------------------------------------

-- Criar tabela a partir do resultado de um SELECT (CTAS)
CREATE TABLE IF NOT EXISTS supplier_usa AS
SELECT * FROM supplier WHERE country = 'USA';

SELECT * FROM supplier_usa;

-- Remover tabela de teste
DROP TABLE IF EXISTS supplier_usa;


--------------------------------------------------------------------------------
-- PARTE 6: CONTROLE DE TRANSAÇÕES E SEGURANÇA DE ATUALIZAÇÃO (SAFE UPDATES)
--------------------------------------------------------------------------------

-- Atualização simples por Chave Primária
UPDATE supplier
SET city = 'Oslo', phone = '(0)1-953530', fax = '(0)1-953555'
WHERE id = 2;

-- Teste de Transação com ROLLBACK (Utilizando desativação temporária do Safe Updates)
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;
UPDATE product
SET isdiscontinued = 0
WHERE isdiscontinued = 1;

-- Verificar o estado alterado dentro da transação
SELECT COUNT(*) FROM product WHERE isdiscontinued = 1;

-- Reverter alterações não confirmadas
ROLLBACK;

-- Reativar o modo de segurança de updates
SET SQL_SAFE_UPDATES = 1;

-- Teste de Transação com COMMIT
START TRANSACTION;
UPDATE product
SET isdiscontinued = 1
WHERE id = 9;

COMMIT;

-- Teste de DELETE com ROLLBACK em tabela relacional
START TRANSACTION;
DELETE FROM orderitem WHERE quantity = 1;
ROLLBACK;


--------------------------------------------------------------------------------
-- PARTE 7: CARGA DE DADOS COM INSERT SELECT E ALTERAÇÃO DE AUTO_INCREMENT
--------------------------------------------------------------------------------

-- Criar tabela de backup para demonstração de TRUNCATE
CREATE TABLE IF NOT EXISTS orderitem_bkp AS SELECT * FROM orderitem;
TRUNCATE TABLE orderitem_bkp;
DROP TABLE IF EXISTS orderitem_bkp;

-- Carga em massa via INSERT INTO ... SELECT utilizando funções de string
INSERT INTO customer (firstname, lastname, city, country, phone)
SELECT LEFT(contactname, 5), 
       SUBSTRING(contactname, 2, 3), 
       city, country, phone
FROM supplier
WHERE companyname = 'Bigfoot Breweries';

-- Modificar atributo AUTO_INCREMENT da Chave Primária com desligamento de FK Checks
SET FOREIGN_KEY_CHECKS = 0;

ALTER TABLE customer 
MODIFY COLUMN id INT NOT NULL AUTO_INCREMENT, 
AUTO_INCREMENT = 500;

SET FOREIGN_KEY_CHECKS = 1;

-- Testar novo auto incremento inserido
INSERT INTO customer (firstname, lastname, city, country, phone)
VALUES ('Arley', 'Ribeiro', 'Belo Horizonte', 'Brazil', '(31) 99999-8888');

SELECT * FROM customer WHERE id >= 500;


--------------------------------------------------------------------------------
-- PARTE 8: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

/*
-- Descomentar as linhas abaixo caso deseje resetar as alterações feitas na base:

USE arley_cliente2;
DELETE FROM customer WHERE id >= 500;
ALTER TABLE customer AUTO_INCREMENT = 1;
*/