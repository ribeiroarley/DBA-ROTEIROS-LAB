/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-09-views-e-operacoes-dml-mysql8.sql
  Objetivo     : Roteiro prático para criação, alteração, consulta e teste de
                 atualizabilidade (DML DML-updatable views) em Views simples e
                 complexas com JOINs no MySQL 8.x, abordando restrições de DDL e
                 commits implícitos.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Views & CREATE VIEW Statement
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SELEÇÃO DO SCHEMA E CRIAÇÃO DE VIEW SIMPLES (FILTRADA)
--------------------------------------------------------------------------------

USE arley_cliente2;

-- Garantir remoção da view se já existir
DROP VIEW IF EXISTS vw_customer_madrid;

-- Criar view baseada na tabela 'customer' filtrando por cidade
CREATE VIEW vw_customer_madrid AS
SELECT 
    id,
    firstname,
    lastname,
    city,
    country,
    phone
FROM customer
WHERE city = 'Madrid';

-- Consultar a View criada
SELECT * FROM vw_customer_madrid;

-- Consultar aplicando filtros adicionais na View
SELECT id, firstname, lastname, city, phone
FROM vw_customer_madrid
WHERE phone LIKE '%555%';


--------------------------------------------------------------------------------
-- PARTE 2: OPERAÇÕES DML VIA VIEW SIMPLES (INSERT, DELETE, TRANSAÇÕES)
--------------------------------------------------------------------------------

-- Inserir registro que atende ao filtro da View (city = 'Madrid')
INSERT INTO vw_customer_madrid (firstname, lastname, city, country, phone)
VALUES ('arley', 'ribeiro de madrid', 'Madrid', 'Spain', '9999999');

-- Inserir registro com cidade diferente do filtro da View
INSERT INTO vw_customer_madrid (firstname, lastname, city, country, phone)
VALUES ('arley', 'ribeiro do porto', 'Porto', 'Portugal', '9999999');

-- Verificar que o registro 'Porto' não aparece na View devido ao WHERE da View
SELECT * FROM vw_customer_madrid WHERE lastname LIKE 'ribeiro%';

-- Confirmar presença do registro diretamente na tabela base
SELECT * FROM customer WHERE lastname LIKE 'ribeiro%';

-- Deletar registro via View simples
DELETE FROM vw_customer_madrid WHERE lastname = 'ribeiro de madrid';

-- Testar transação DML (ROLLBACK) sobre a View
START TRANSACTION;

DELETE FROM vw_customer_madrid WHERE phone LIKE '%555%';

-- Confirmar remoção temporária na sessão
SELECT COUNT(*) FROM vw_customer_madrid WHERE phone LIKE '%555%';

-- Reverter operação
ROLLBACK;

-- Confirmar restauração dos dados após o ROLLBACK
SELECT COUNT(*) FROM vw_customer_madrid WHERE phone LIKE '%555%';


--------------------------------------------------------------------------------
-- PARTE 3: CRIAÇÃO E ALTERAÇÃO DE VIEWS COMPLEXAS COM JOIN E AGREGAÇÕES
--------------------------------------------------------------------------------

-- Criar View agregada de vendas diárias
CREATE OR REPLACE VIEW vw_daily_sales AS
SELECT
    YEAR(o.orderdate) AS ano,
    MONTH(o.orderdate) AS mes,
    DAY(o.orderdate) AS dia,
    p.id AS product_id,
    p.productname,
    i.quantity * i.unitprice AS total_sales
FROM `order` o
INNER JOIN orderitem i ON o.id = i.orderid
INNER JOIN product p ON p.id = i.productid;

-- Consultar a View de vendas com ordenação
SELECT * FROM vw_daily_sales ORDER BY ano DESC, mes DESC, dia DESC, total_sales DESC;

-- Agregação sobre a View (Vendas por mês)
SELECT 
    ano, 
    mes, 
    SUM(total_sales) AS vendas_mes
FROM vw_daily_sales
GROUP BY ano, mes
ORDER BY ano ASC, mes DESC;

-- Média de vendas por ano
SELECT 
    ano, 
    AVG(total_sales) AS vendas_media_ano
FROM vw_daily_sales
GROUP BY ano
ORDER BY ano ASC;

-- Alterar a View utilizando CREATE OR REPLACE VIEW (Sintaxe compatível com MySQL 8.x)
CREATE OR REPLACE VIEW vw_daily_sales AS
SELECT
    YEAR(o.orderdate) AS ano,
    MONTH(o.orderdate) AS mes,
    DAY(o.orderdate) AS dia,
    p.id AS product_id,
    p.productname,
    i.quantity * i.unitprice AS total_sales,
    c.firstname,
    c.lastname
FROM `order` o
INNER JOIN customer c ON c.id = o.customerid 
INNER JOIN orderitem i ON o.id = i.orderid
INNER JOIN product p ON p.id = i.productid;

-- Consultar View atualizada agrupando por cliente
SELECT 
    CONCAT(firstname, ' ', lastname) AS nome_cliente, 
    SUM(total_sales) AS total_comprado
FROM vw_daily_sales
GROUP BY firstname, lastname
ORDER BY total_comprado DESC
LIMIT 5;


--------------------------------------------------------------------------------
-- PARTE 4: TESTES DE RESTRIÇÕES DML EM VIEWS COM JOIN E TRANSAÇÕES DDL
--------------------------------------------------------------------------------

-- Tentativa de exclusão em View de JOIN (Irá gerar erro: Cannot delete from join view)
-- DELETE FROM vw_daily_sales WHERE ano = 2012;

-- Demonstrar comportamento de DDL (DROP VIEW) dentro de transações no MySQL
-- Nota: Comandos DDL causam COMMIT implícito no MySQL e não suportam ROLLBACK.
START TRANSACTION;

DROP VIEW IF EXISTS vw_daily_sales;

-- O ROLLBACK abaixo não restaurará a View descartada devido ao commit implícito do DROP VIEW
ROLLBACK;

-- Recriar a View para manter a consistência do ambiente
CREATE OR REPLACE VIEW vw_daily_sales AS
SELECT
    YEAR(o.orderdate) AS ano,
    MONTH(o.orderdate) AS mes,
    DAY(o.orderdate) AS dia,
    p.id AS product_id,
    p.productname,
    i.quantity * i.unitprice AS total_sales,
    c.firstname,
    c.lastname
FROM `order` o
INNER JOIN customer c ON c.id = o.customerid 
INNER JOIN orderitem i ON o.id = i.orderid
INNER JOIN product p ON p.id = i.productid;


--------------------------------------------------------------------------------
-- PARTE 5: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

-- Remover os registros de teste criados na tabela base 'customer'
DELETE FROM customer WHERE lastname = 'ribeiro do porto';

-- Remover as Views criadas no laboratório
DROP VIEW IF EXISTS vw_customer_madrid;
DROP VIEW IF EXISTS vw_daily_sales;

-- Confirmar que nenhuma View restou no schema ativo
SHOW FULL TABLES WHERE table_type = 'VIEW';