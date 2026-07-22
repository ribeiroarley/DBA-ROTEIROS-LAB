/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-05-consultas-dml-transacoes-19c.sql
  Objetivo     : Práticas avançadas de consultas SQL (Selects, Joins, Subqueries, 
                 Agregações), manipulação DML (Update, Delete, Truncate) e 
                 controle de transações com blocos PL/SQL e Savepoints 
                 no Oracle Database 19c Multitenant (CDB/PDB).
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c SQL Language Reference / PL/SQL Language Guide
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: CONSULTAS BÁSICAS DE SELEÇÃO E ORDENAÇÃO
--------------------------------------------------------------------------------

-- Conectar à sessão do PDB com o usuário cliente
CONNECT cliente/a123@//localhost:1521/ORCLPDB;

-- Selecionando colunas específicas
SELECT firstname, lastname, city 
FROM customer;

-- Seleção total da tabela
SELECT * 
FROM customer;

-- Filtrando por critérios literais
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

SELECT country, city, firstname, lastname
FROM customer
ORDER BY country ASC, city DESC;


--------------------------------------------------------------------------------
-- PARTE 2: LIMITAÇÃO DE RESULTADOS E DISTINÇÃO (ORACLE 19c Syntax)
--------------------------------------------------------------------------------

-- Limitação de linhas legada via ROWNUM (Até Oracle 11g)
SELECT id, productname, unitprice, package
FROM product
WHERE ROWNUM <= 5
ORDER BY unitprice DESC;

-- Limitação de linhas moderna e padrão ANSI (Oracle 12c+)
SELECT id, productname, unitprice, package
FROM product
ORDER BY unitprice DESC
FETCH FIRST 5 ROWS ONLY;

-- Eliminação de duplicadas (DISTINCT)
SELECT DISTINCT country
FROM supplier
ORDER BY country;


--------------------------------------------------------------------------------
-- PARTE 3: FUNÇÕES DE AGREGAÇÃO, MATEMÁTICAS E DATAS
--------------------------------------------------------------------------------

-- Menor valor (MIN) e ordenação
SELECT MIN(unitprice) AS menor_preco 
FROM product;

-- Uso da função EXTRACT para manipular componentes de datas
SELECT MAX(totalamount) AS maior_pedido_2023
FROM "order"
WHERE EXTRACT(YEAR FROM orderdate) = 2023;

-- Contagem, Somatório, Média e Arredondamento (ROUND, SUM, AVG, COUNT)
SELECT COUNT(id) AS total_clientes 
FROM customer;

SELECT SUM(totalamount) AS faturamento_2023
FROM "order" 
WHERE EXTRACT(YEAR FROM orderdate) = 2023;

SELECT ROUND(AVG(totalamount), 2) AS media_pedidos
FROM "order";


--------------------------------------------------------------------------------
-- PARTE 4: OPERADORES LÓGICOS, INTERVALOS E BUSCA TEXTUAL
--------------------------------------------------------------------------------

-- Cláusulas AND, OR, NOT
SELECT id, firstname, lastname, city, country
FROM customer 
WHERE firstname = 'Antonio' AND lastname = 'Moreno';

SELECT id, firstname, lastname, city, country
FROM customer
WHERE country = 'Spain' OR country = 'France';

SELECT id, firstname, lastname, city, country
FROM customer
WHERE NOT country = 'USA';

-- Operadores IN e NOT IN
SELECT id, companyname, city, country
FROM supplier
WHERE country IN ('USA', 'UK', 'Japan');

SELECT id, productname, unitprice
FROM product
WHERE unitprice NOT IN (10, 20, 30, 40, 50);

-- Operador BETWEEN com valores e datas
SELECT id, productname, unitprice
FROM product
WHERE unitprice BETWEEN 10 AND 20
ORDER BY unitprice;

SELECT COUNT(id) AS qtvendas, SUM(totalamount) AS valortotal
FROM "order"
WHERE orderdate BETWEEN TO_DATE('01/01/2023', 'DD/MM/YYYY') 
                    AND TO_DATE('03/01/2023', 'DD/MM/YYYY');

-- Busca por padrões de texto (LIKE e Wildcards)
SELECT id, productname, unitprice, package
FROM product
WHERE productname LIKE '%na%';

SELECT id, productname, unitprice, package
FROM product
WHERE productname LIKE 'Cha_' OR productname LIKE 'Chan_';

-- Tratamento de valores nulos (IS NULL / IS NOT NULL)
SELECT id, companyname, phone, fax 
FROM supplier
WHERE fax IS NULL;

SELECT id, companyname, phone, fax 
FROM supplier
WHERE fax IS NOT NOT NULL;


--------------------------------------------------------------------------------
-- PARTE 5: AGRUPAMENTO DE DADOS (GROUP BY) E FILTROS DE AGREGAÇÃO (HAVING)
--------------------------------------------------------------------------------

-- Agrupamento básico
SELECT country, COUNT(id) AS total_clientes
FROM customer
GROUP BY country
ORDER BY total_clientes DESC;

-- Agrupamento com filtro em colunas agregadas usando HAVING
SELECT country, COUNT(id) AS total_clientes
FROM customer
WHERE country <> 'USA'
GROUP BY country
HAVING COUNT(id) >= 9
ORDER BY total_clientes DESC;

SELECT firstname, lastname, AVG(totalamount) AS media_pedidos
FROM "order" o 
JOIN customer c ON o.customerid = c.id
GROUP BY firstname, lastname
HAVING AVG(totalamount) BETWEEN 1000 AND 1200;


--------------------------------------------------------------------------------
-- PARTE 6: JUNÇÃO DE TABELAS (JOINS) E OPERADORES DE CONJUNTO (UNION)
--------------------------------------------------------------------------------

-- INNER JOIN
SELECT c.id, c.firstname, c.lastname, o.orderdate, o.totalamount
FROM customer c 
INNER JOIN "order" o ON c.id = o.customerid;

SELECT o.ordernumber, 
       TO_CHAR(o.orderdate, 'YYYY-MM-DD') AS data_formatada,
       p.productname, i.quantity, i.unitprice
FROM "order" o
JOIN orderitem i ON o.id = i.orderid
JOIN product p ON p.id = i.productid
ORDER BY o.ordernumber;

-- LEFT JOIN e identificação de nulos
SELECT c.firstname, c.lastname, c.city, c.country, o.ordernumber, o.totalamount
FROM customer c 
LEFT JOIN "order" o ON o.customerid = c.id
WHERE o.totalamount IS NULL
ORDER BY c.firstname;

-- RIGHT JOIN equivalente
SELECT c.firstname, c.lastname, c.city, c.country, o.totalamount
FROM "order" o 
RIGHT JOIN customer c ON o.customerid = c.id
WHERE o.totalamount IS NULL
ORDER BY c.firstname;

-- UNION com concatenação nativa do Oracle (||)
SELECT 'Customer' AS tipo, 
       firstname || ' ' || lastname AS nome_contato, 
       city, country, phone
FROM customer
UNION
SELECT 'Supplier' AS tipo, 
       contactname AS nome_contato, 
       city, country, phone
FROM supplier;


--------------------------------------------------------------------------------
-- PARTE 7: SUBQUERIES E CLÁUSULA EXISTS
--------------------------------------------------------------------------------

-- Subquery na cláusula WHERE (IN)
SELECT productname
FROM product p
WHERE id IN (SELECT productid 
            FROM orderitem 
            WHERE quantity > 10);

-- Subquery correlacionada no SELECT
SELECT c.id, c.firstname, c.lastname,
       (SELECT COUNT(o.id) 
        FROM "order" o 
        WHERE o.customerid = c.id) AS ordercount
FROM customer c
ORDER BY ordercount DESC;

-- Subqueries com EXISTS e NOT EXISTS
SELECT companyname
FROM supplier s
WHERE EXISTS (SELECT 1 
              FROM product p 
              WHERE p.supplierid = s.id 
                AND p.unitprice > 100);

SELECT companyname
FROM supplier s
WHERE NOT EXISTS (SELECT 1 
                  FROM product p 
                  WHERE p.supplierid = s.id 
                    AND p.unitprice > 100);


--------------------------------------------------------------------------------
-- PARTE 8: CRIAÇÃO DE TABELAS A PARTIR DE SELECT (CTAS)
--------------------------------------------------------------------------------

-- CTAS: Create Table As Select
CREATE TABLE supplier_usa AS
SELECT *
FROM supplier
WHERE country = 'USA';

SELECT * FROM supplier_usa;

-- Limpeza da tabela temporária
DROP TABLE supplier_usa PURGE;


--------------------------------------------------------------------------------
-- PARTE 9: MANIPULAÇÃO DML (UPDATE COM SUBQUERY)
--------------------------------------------------------------------------------

-- Atualização individual com Commit
UPDATE supplier
SET city = 'Oslo', 
    phone = '(0)1-953530', 
    fax = '(0)1-953555'
WHERE id = 2;

COMMIT;

-- Atualização correlacionada entre tabelas (Aumento de 10% para clientes dos USA)
UPDATE "order" o
SET o.totalamount = o.totalamount * 1.1
WHERE o.customerid IN (
    SELECT c.id
    FROM customer c
    WHERE c.country = 'USA'
);

COMMIT;


--------------------------------------------------------------------------------
-- PARTE 10: TRANSAÇÕES ROBUSTAS COM PL/SQL, SAVEPOINTS E TRATAMENTO DE ERROS
--------------------------------------------------------------------------------

-- Bloco PL/SQL Anônimo para inserção atômica com rollback automático em caso de falha
DECLARE
  v_error_message VARCHAR2(4000);
BEGIN 
  -- Definindo ponto de restauração na transação
  SAVEPOINT start_transaction;

  INSERT INTO supplier (id, companyname, contactname, contacttitle, city, country, phone, fax)
  VALUES (100, 'Supplier Company', 'Arley Ribeiro', 'CEO', 'City A', 'Country A', '123-456-7890', '123-456-7891');

  INSERT INTO customer (id, firstname, lastname, city, country, phone)
  VALUES (100, 'Arley', 'Ribeiro', 'City B', 'Country B', '987-654-3210');

  INSERT INTO product (id, productname, supplierid, unitprice, package, isdiscontinued)
  VALUES (100, 'Product 100', 100, 19.99, 'Package A', 0);

  INSERT INTO "order" (id, orderdate, ordernumber, customerid, totalamount)
  VALUES (100, TO_DATE('2023-08-08', 'YYYY-MM-DD'), 'ORD-123', 100, 50.00);

  INSERT INTO orderitem (id, orderid, productid, unitprice, quantity)
  VALUES (100, 100, 100, 19.99, 2);

  -- Efetivar a transação inteira se não houver erros
  COMMIT;

EXCEPTION 
  WHEN OTHERS THEN
    v_error_message := SQLERRM;
    ROLLBACK TO SAVEPOINT start_transaction;
    DBMS_OUTPUT.PUT_LINE('Transação abortada. Erro registrado: ' || v_error_message);
END;
/

-- Bloco PL/SQL Anônimo para exclusão atômica tratada
DECLARE
  v_error_message VARCHAR2(4000);
BEGIN
  SAVEPOINT start_transaction;

  DELETE FROM orderitem WHERE id = 100;
  DELETE FROM "order" WHERE id = 100;
  DELETE FROM product WHERE id = 100;
  DELETE FROM customer WHERE id = 100;
  DELETE FROM supplier WHERE id = 100;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    v_error_message := SQLERRM;
    ROLLBACK TO SAVEPOINT start_transaction;
    DBMS_OUTPUT.PUT_LINE('Exclusão abortada. Erro registrado: ' || v_error_message);
END;
/


--------------------------------------------------------------------------------
-- PARTE 11: DIFERENÇA ENTRE DELETE E TRUNCATE (DDL vs DML)
--------------------------------------------------------------------------------

-- Criando tabela de testes
CREATE TABLE neworderitem AS 
SELECT * FROM orderitem;

-- O DELETE gera informações no Undo/Redo e pode ser desfeito via ROLLBACK
DELETE FROM neworderitem;
ROLLBACK;

-- O TRUNCATE é uma operação DDL de desalocação de extensões. Não gera Undo e faz COMMIT implícito
TRUNCATE TABLE neworderitem;

-- Tentativa de Rollback não surtirá efeito após o TRUNCATE
ROLLBACK;

-- Limpeza da tabela de testes
DROP TABLE neworderitem PURGE;