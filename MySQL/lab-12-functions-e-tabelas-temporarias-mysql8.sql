/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-12-functions-e-tabelas-temporarias-mysql8.sql
  Objetivo     : Roteiro prático para criação, execução e validação de User-Defined
                 Functions (UDFs) determinísticas, classificação condicional,
                 encapsulamento de cálculos em DMLs e manipulação de Tabelas
                 Temporárias (TEMPORARY TABLE) no MySQL 8.x.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Stored Functions & CREATE TEMPORARY TABLE
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SELEÇÃO DO SCHEMA E USER-DEFINED FUNCTIONS (UDF) SIMPLES
--------------------------------------------------------------------------------

USE arley_cliente2;

-- Remover função se existente
DROP FUNCTION IF EXISTS fn_saudacao;

-- Criar função simples de manipulação de string com cláusula DETERMINISTIC
CREATE FUNCTION fn_saudacao (p_nome CHAR(20))
RETURNS CHAR(50) DETERMINISTIC
    RETURN CONCAT('Ola, ', p_nome, '!');

-- Executar a função via SELECT
SELECT fn_saudacao('Arley Ribeiro') AS mensagem;


--------------------------------------------------------------------------------
-- PARTE 2: FUNÇÃO DE CÁLCULO FINANCEIRO E INTEGRAÇÃO COM SELECT / SUM
--------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS fn_calcular_desconto;

DELIMITER $$

CREATE FUNCTION fn_calcular_desconto(
    p_quantidade INT,
    p_preco_unitario DECIMAL(10,2),
    p_percentual_desconto DECIMAL(4,2)
)
RETURNS DECIMAL(10,2) DETERMINISTIC
BEGIN
    RETURN p_quantidade * p_preco_unitario * (1.00 - p_percentual_desconto);
END$$

DELIMITER ;

-- Testar a função isoladamente
SELECT fn_calcular_desconto(2, 100.00, 0.10) AS valor_com_desconto;

-- Consultar funções registradas no schema
SHOW FUNCTION STATUS WHERE db = 'arley_cliente2';

-- Utilizar a função encapsulada diretamente em uma consulta DML
SELECT 
    id,
    quantity,
    unitprice,
    fn_calcular_desconto(quantity, unitprice, 0.10) AS valor_liquido
FROM orderitem;

-- Utilizar o resultado da função como argumento para agregador SUM
SELECT 
    SUM(fn_calcular_desconto(quantity, unitprice, 0.10)) AS faturamento_liquido_total
FROM orderitem;


--------------------------------------------------------------------------------
-- PARTE 3: FUNÇÃO COM LÓGICA DE NEGÓCIO E CONTROLE CONDICIONAL (IF/ELSEIF)
--------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS fn_classificar_nivel_cliente;

DELIMITER $$

CREATE FUNCTION fn_classificar_nivel_cliente(
    p_credito DECIMAL(10,2)
) 
RETURNS VARCHAR(20) DETERMINISTIC
BEGIN
    DECLARE v_nivel VARCHAR(20);

    IF p_credito < 1000.00 THEN
        SET v_nivel = 'PRATA';
    ELSEIF p_credito < 5000.00 THEN
        SET v_nivel = 'PLATINA';
    ELSEIF p_credito <= 10000.00 THEN
        SET v_nivel = 'OURO';
    ELSE
        SET v_nivel = 'SUPER OURO';
    END IF;

    RETURN v_nivel;
END$$

DELIMITER ;

-- Testes de validação da lógica de limites
SELECT fn_classificar_nivel_cliente(500.00) AS nivel_500;
SELECT fn_classificar_nivel_cliente(2500.00) AS nivel_2500;
SELECT fn_classificar_nivel_cliente(7500.00) AS nivel_7500;
SELECT fn_classificar_nivel_cliente(15000.00) AS nivel_15000;


--------------------------------------------------------------------------------
-- PARTE 4: FUNÇÕES AGREGADORAS INTERNAS (INTO VARIABLE)
--------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS fn_obter_faturamento_bruto;

DELIMITER $$

CREATE FUNCTION fn_obter_faturamento_bruto()
RETURNS DECIMAL(12,2) DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(12,2);
    
    SELECT IFNULL(SUM(unitprice * quantity), 0.00)
    INTO v_total
    FROM orderitem;
    
    RETURN v_total;
END$$

DELIMITER ;

-- Executar a função agregadora interna
SELECT fn_obter_faturamento_bruto() AS total_bruto_acumulado;


--------------------------------------------------------------------------------
-- PARTE 5: MANIPULAÇÃO DE TABELAS TEMPORÁRIAS (TEMPORARY TABLE)
--------------------------------------------------------------------------------

-- Remover tabela temporária se existente no escopo da sessão
DROP TEMPORARY TABLE IF EXISTS tmp_customer_berlin;

-- Criar tabela temporária isolada para o escopo da conexão atual
CREATE TEMPORARY TABLE tmp_customer_berlin (
  id INT NOT NULL,
  firstname VARCHAR(40) NULL,
  lastname VARCHAR(40) NULL,
  city VARCHAR(40) NULL,
  country VARCHAR(40) NULL,
  phone VARCHAR(20) NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Carga de dados na tabela temporária a partir de tabela física
INSERT INTO tmp_customer_berlin (id, firstname, lastname, city, country, phone)
SELECT id, firstname, lastname, city, country, phone
FROM customer
WHERE city = 'Berlin';

-- Consultar dados da tabela temporária
SELECT * FROM tmp_customer_berlin;


--------------------------------------------------------------------------------
-- PARTE 6: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

-- Remover User-Defined Functions criadas
DROP FUNCTION IF EXISTS fn_saudacao;
DROP FUNCTION IF EXISTS fn_calcular_desconto;
DROP FUNCTION IF EXISTS fn_classificar_nivel_cliente;
DROP FUNCTION IF EXISTS fn_obter_faturamento_bruto;

-- Descartar a tabela temporária (Opcional, pois é descartada ao fechar a conexão)
DROP TEMPORARY TABLE IF EXISTS tmp_customer_berlin;