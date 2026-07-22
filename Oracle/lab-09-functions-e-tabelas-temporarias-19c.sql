/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-09-functions-e-tabelas-temporarias-19c.sql
  Objetivo     : Roteiro prático cobrindo criação e execução de User Defined 
                 Functions (UDFs) em PL/SQL, chamadas via DUAL e instruções DML, 
                 regras de escopo e uso de Global Temporary Tables (GTT) no 
                 Oracle Database 19c Multitenant (CDB/PDB).
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c PL/SQL Language Reference / Administrator's Guide
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SETUP DE CONEXÃO E PRIVILÉGIOS (SYSDBA / CLIENTE)
--------------------------------------------------------------------------------

-- Conectar como SYSDBA e abrir o PDB
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Conceder privilégio de criação de Functions para o Schema CLIENTE
GRANT CREATE PROCEDURE TO cliente CONTAINER=CURRENT;

-- Alternar sessão para o Schema CLIENTE
CONNECT cliente/a123@//localhost:1521/ORCLPDB;

-- Habilitar saída de buffer de texto no terminal
SET SERVEROUTPUT ON;


--------------------------------------------------------------------------------
-- PARTE 2: FUNCTIONS BÁSICAS COM DUAL E PL/SQL
--------------------------------------------------------------------------------

-- Function simples para concatenação de texto
CREATE OR REPLACE FUNCTION cliente.fn_ola (
    p_nome IN VARCHAR2
) RETURN VARCHAR2 IS
    v_resultado VARCHAR2(100);
BEGIN
    v_resultado := 'Ola, ' || p_nome || '!';
    RETURN v_resultado;
END fn_ola;
/

-- Chamadas via SELECT utilizando a tabela dummy DUAL
SELECT cliente.fn_ola('World') AS mensagem FROM DUAL;
SELECT cliente.fn_ola('Arley Ribeiro') AS mensagem_personalizada FROM DUAL;


-- Function com lógica condicional (IF...ELSE) para cálculo numérico
CREATE OR REPLACE FUNCTION cliente.fn_obter_maximo (
    p_x IN NUMBER,
    p_y IN NUMBER
) RETURN NUMBER IS
    v_maximo NUMBER;
BEGIN
    IF p_x > p_y THEN
        v_maximo := p_x;
    ELSE
        v_maximo := p_y;
    END IF;
    RETURN v_maximo;
END fn_obter_maximo;
/

-- Execução da Function dentro de um Bloco Anônimo PL/SQL
DECLARE
    v_num1   NUMBER := 23;
    v_num2   NUMBER := 45;
    v_max    NUMBER;
BEGIN
    v_max := cliente.fn_obter_maximo(v_num1, v_num2);
    DBMS_OUTPUT.PUT_LINE('Valor maximo entre ' || v_num1 || ' e ' || v_num2 || ' foi: ' || v_max);
END;
/


--------------------------------------------------------------------------------
-- PARTE 3: FUNCTIONS PARA CÁLCULOS FINANCEIROS E REGRAS DE NEGÓCIO
--------------------------------------------------------------------------------

-- Function para cálculo de preço final com aplicação de desconto
CREATE OR REPLACE FUNCTION cliente.fn_calcula_desconto (
    p_qtde             IN NUMBER,
    p_preco_unitario   IN NUMBER,
    p_percentual_desc  IN NUMBER
) RETURN NUMBER IS
BEGIN
    RETURN p_qtde * p_preco_unitario * (1 - p_percentual_desc);
END fn_calcula_desconto;
/

-- Teste isolado via DUAL
SELECT cliente.fn_calcula_desconto(1, 100, 0.1) AS valor_venda_final FROM DUAL;


-- Function com condicional ELSIF para categorização de clientes
CREATE OR REPLACE FUNCTION cliente.fn_nivel_cliente (
    p_credito IN NUMBER
) RETURN VARCHAR2 IS
    v_nivel VARCHAR2(20);
BEGIN
    IF p_credito < 1000 THEN
        v_nivel := 'PRATA';
    ELSIF p_credito < 5000 THEN
        v_nivel := 'PLATINA';
    ELSIF p_credito <= 10000 THEN
        v_nivel := 'OURO';
    ELSE
        v_nivel := 'SUPEROURO';
    END IF;
    RETURN v_nivel;
END fn_nivel_cliente;
/

-- Teste com múltiplos cenários via Bloco Anônimo
BEGIN
    DBMS_OUTPUT.PUT_LINE('Credito 100:   ' || cliente.fn_nivel_cliente(100));
    DBMS_OUTPUT.PUT_LINE('Credito 4999:  ' || cliente.fn_nivel_cliente(4999));
    DBMS_OUTPUT.PUT_LINE('Credito 5000:  ' || cliente.fn_nivel_cliente(5000));
    DBMS_OUTPUT.PUT_LINE('Credito 10000: ' || cliente.fn_nivel_cliente(10000));
    DBMS_OUTPUT.PUT_LINE('Credito 10001: ' || cliente.fn_nivel_cliente(10001));
END;
/


-- Refatoração utilizando a instrução CASE (Simplificação da lógica)
CREATE OR REPLACE FUNCTION cliente.fn_nivel_cliente_case (
    p_credito IN NUMBER
) RETURN VARCHAR2 AS
BEGIN
    RETURN CASE
        WHEN p_credito < 1000  THEN 'PRATA'
        WHEN p_credito < 5000  THEN 'PLATINA'
        WHEN p_credito <= 10000 THEN 'OURO'
        ELSE 'SUPEROURO'
    END;
END fn_nivel_cliente_case;
/

-- Chamada da versão refatorada em queries SQL
SELECT cliente.fn_nivel_cliente_case(100)  AS resultado_100 FROM DUAL;
SELECT cliente.fn_nivel_cliente_case(4999) AS resultado_4999 FROM DUAL;


--------------------------------------------------------------------------------
-- PARTE 4: INTEGRAÇÃO DE FUNCTIONS COM QUERIES E TABELAS DO BANCO
--------------------------------------------------------------------------------

-- Aplicando a Function diretamente sobre colunas da tabela OrderItem
SELECT 
    id, 
    quantity, 
    unitprice,
    cliente.fn_calcula_desconto(quantity, unitprice, 0.10) AS valor_com_desconto
FROM cliente.orderitem;

-- Agregando o retorno de uma Function em tempo de execução (SUM + UDF)
SELECT 
    ROUND(SUM(cliente.fn_calcula_desconto(quantity, unitprice, 0.10)), 2) AS total_vendas_com_desconto
FROM cliente.orderitem;


--------------------------------------------------------------------------------
-- PARTE 5: GLOBAL TEMPORARY TABLES (GTT) E ESCOPO DE SESSÃO
--------------------------------------------------------------------------------

-- Criar tabela temporária preservando dados durante a sessão ativa (ON COMMIT PRESERVE ROWS)
CREATE GLOBAL TEMPORARY TABLE cliente.gt_customer_berlin (
    id        NUMBER NOT NULL,
    firstname VARCHAR2(40),
    lastname  VARCHAR2(40),
    city      VARCHAR2(40),
    country   VARCHAR2(40),
    phone     VARCHAR2(20),
    CONSTRAINT pk_gt_cust_berlin PRIMARY KEY (id)
) ON COMMIT PRESERVE ROWS;

-- Inserindo dados na GTT a partir de uma tabela física
INSERT INTO cliente.gt_customer_berlin
SELECT id, firstname, lastname, city, country, phone
FROM cliente.customer
WHERE city = 'Berlin';

COMMIT;

-- Consultando dados na sessão criadora (Dados visíveis apenas na sessão atual)
SELECT * FROM cliente.gt_customer_berlin;

-- Limpeza total de dados e remoção da estrutura da tabela temporária
TRUNCATE TABLE cliente.gt_customer_berlin;
DROP TABLE cliente.gt_customer_berlin PURGE;


--------------------------------------------------------------------------------
-- PARTE 6: LIMPEZA DOS OBJETOS DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

/*
DROP FUNCTION cliente.fn_ola;
DROP FUNCTION cliente.fn_obter_maximo;
DROP FUNCTION cliente.fn_calcula_desconto;
DROP FUNCTION cliente.fn_nivel_cliente;
DROP FUNCTION cliente.fn_nivel_cliente_case;
*/