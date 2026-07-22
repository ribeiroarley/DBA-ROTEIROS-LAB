/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-10-stored-procedures-e-programacao-mysql8.sql
  Objetivo     : Roteiro prático para criação, execução, tratamento de parâmetros
                 (IN, OUT, INOUT), variáveis de sessão, estruturas condicionais 
                 (IF/ELSEIF), laços de repetição (WHILE/LEAVE) e SQL Dinâmico 
                 em Stored Procedures no MySQL 8.x.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Stored Routines & SQL Syntax
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SELEÇÃO DO SCHEMA E STORED PROCEDURE SIMPLES (SEM PARÂMETROS)
--------------------------------------------------------------------------------

USE arley_cliente2;[cite: 15]

-- Remover procedure se existente para garantir reexecução
DROP PROCEDURE IF EXISTS sp_product_list;[cite: 15]

-- Alterar delimitador para compilar bloco de código contendo múltiplos ponto e vírgula
DELIMITER $$

CREATE PROCEDURE sp_product_list()
BEGIN
    SELECT 
        id,
        productname,
        supplierid,
        unitprice,
        package,
        isdiscontinued
    FROM product
    ORDER BY productname DESC;[cite: 15]
END$$

DELIMITER ;

-- Inspecionar rotinas existentes no schema ativo
SHOW PROCEDURE STATUS WHERE db = 'arley_cliente2';[cite: 15]

SELECT 
    routine_name, 
    routine_type, 
    definer, 
    created, 
    security_type 
FROM information_schema.routines 
WHERE routine_type = 'PROCEDURE' AND routine_schema = 'arley_cliente2';[cite: 15]

-- Executar a Stored Procedure
CALL sp_product_list();[cite: 15]


--------------------------------------------------------------------------------
-- PARTE 2: PROCEDURES COM PARÂMETROS DE ENTRADA (IN) E TRATAMENTO DE NULL
--------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS sp_product_list_by_price;[cite: 15]

DELIMITER $$

CREATE PROCEDURE sp_product_list_by_price(
    IN p_min_price DECIMAL(12,2),
    IN p_max_price DECIMAL(12,2),
    IN p_product_name VARCHAR(50)
)
BEGIN
    -- Tratamento para simular parâmetros opcionais com valores padrão
    IF p_min_price IS NULL THEN
        SET p_min_price = 0.00;[cite: 15]
    END IF;[cite: 15]

    IF p_max_price IS NULL THEN
        SET p_max_price = 9999999999.99;[cite: 15]
    END IF;[cite: 15]

    SELECT 
        id,
        productname,
        supplierid,
        unitprice
    FROM product
    WHERE unitprice >= p_min_price 
      AND unitprice <= p_max_price
      AND productname LIKE CONCAT('%', IFNULL(p_product_name, ''), '%')[cite: 15]
    ORDER BY id ASC;[cite: 15]
END$$

DELIMITER ;

-- Testes de chamada passando diferentes combinações de parâmetros
CALL sp_product_list_by_price(10.00, 20.00, 'Ch');[cite: 15]
CALL sp_product_list_by_price(NULL, NULL, 'a');[cite: 15]
CALL sp_product_list_by_price(50.00, NULL, NULL);[cite: 15]


--------------------------------------------------------------------------------
-- PARTE 3: USO DE VARIÁVEIS DE SESSÃO E PARÂMETROS DE SAÍDA (OUT E INOUT)
--------------------------------------------------------------------------------

-- Criar variáveis de sessão e atribuir valores
SET @ano_filtro = 2012;[cite: 15]

SELECT 
    id, 
    orderdate, 
    ordernumber, 
    customerid, 
    totalamount
FROM `order`
WHERE YEAR(orderdate) = @ano_filtro;[cite: 15]

-- Procedure com parâmetro OUT
DROP PROCEDURE IF EXISTS sp_total_produtos;[cite: 15]

DELIMITER $$

CREATE PROCEDURE sp_total_produtos(
    OUT p_total INT
)
BEGIN
    SELECT COUNT(id)
    INTO p_total
    FROM product;[cite: 15]
END$$

DELIMITER ;

-- Executar procedure e capturar o retorno em variável de sessão
CALL sp_total_produtos(@total_cadastrado);[cite: 15]
SELECT @total_cadastrado AS total_produtos_sistema;[cite: 15]

-- Procedure com parâmetros IN e OUT
DROP PROCEDURE IF EXISTS sp_buscar_produto;[cite: 15]

DELIMITER $$

CREATE PROCEDURE sp_buscar_produto(
    IN p_produto_id INT,
    OUT p_nome_produto VARCHAR(50)
)
BEGIN
    SELECT productname
    INTO p_nome_produto
    FROM product
    WHERE id = p_produto_id;[cite: 15]
END$$

DELIMITER ;

-- Teste de busca por ID
CALL sp_buscar_produto(2, @nome_encontrado);[cite: 15]
SELECT @nome_encontrado AS produto_retornado;[cite: 15]


--------------------------------------------------------------------------------
-- PARTE 4: ESTRUTURAS DE CONTROLE (IF/ELSEIF E LAÇOS REPETITIVOS WHILE)
--------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS sp_avaliar_vendas_ano;[cite: 15]

DELIMITER $$

CREATE PROCEDURE sp_avaliar_vendas_ano(
    IN p_ano INT
)
BEGIN
    DECLARE v_total_vendas DECIMAL(12,2) DEFAULT 0.00;

    SELECT IFNULL(SUM(i.unitprice * i.quantity), 0.00)
    INTO v_total_vendas
    FROM orderitem i
    INNER JOIN `order` o ON o.id = i.orderid
    WHERE YEAR(o.orderdate) = p_ano;[cite: 15]

    IF v_total_vendas < 1000.00 THEN
        SELECT v_total_vendas AS valor, 'Volume de vendas BAIXO (Menor que 1000)' AS status_vendas;[cite: 15]
    ELSEIF v_total_vendas < 5000.00 THEN
        SELECT v_total_vendas AS valor, 'Volume de vendas MÉDIO (Entre 1000 e 5000)' AS status_vendas;[cite: 15]
    ELSE
        SELECT v_total_vendas AS valor, 'Volume de vendas ALTO (Maior ou igual a 5000)' AS status_vendas;[cite: 15]
    END IF;
END$$

DELIMITER ;

CALL sp_avaliar_vendas_ano(2012);[cite: 15]

-- Demonstrar laço WHILE com controle de interrupção (LEAVE)
DROP PROCEDURE IF EXISTS sp_testar_while;[cite: 15]

DELIMITER $$

CREATE PROCEDURE sp_testar_while()
BEGIN
    DECLARE v_contador INT DEFAULT 0;

    meu_loop: WHILE v_contador <= 10 DO
        SET v_contador = v_contador + 1;[cite: 15]
        
        IF v_contador = 5 THEN
            LEAVE meu_loop; -- Interrompe a execução do laço ao atingir o valor 5[cite: 15]
        END IF;
    END WHILE meu_loop;[cite: 15]

    SELECT v_contador AS resultado_final_loop;
END$$

DELIMITER ;

CALL sp_testar_while();[cite: 15]


--------------------------------------------------------------------------------
-- PARTE 5: EXECUÇÃO DE SQL DINÂMICO (PREPARE, EXECUTE, DEALLOCATE)
--------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS sp_dynamic_query;[cite: 15]

DELIMITER $$

CREATE PROCEDURE sp_dynamic_query(
    IN p_tabela VARCHAR(64),
    IN p_colunas VARCHAR(255),
    IN p_ordem VARCHAR(64)
)
BEGIN
    SET @sql_text = CONCAT('SELECT ', p_colunas, ' FROM ', p_tabela, ' ORDER BY ', p_ordem);[cite: 15]
    
    PREPARE stmt FROM @sql_text;[cite: 15]
    EXECUTE stmt;[cite: 15]
    DEALLOCATE PREPARE stmt;[cite: 15]
END$$

DELIMITER ;

-- Executar consulta dinâmica com passagem de tabela, colunas e ordenação
CALL sp_dynamic_query('customer', 'id, firstname, city', 'firstname');[cite: 15]


--------------------------------------------------------------------------------
-- PARTE 6: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

-- Limpar Stored Procedures criadas no laboratório
DROP PROCEDURE IF EXISTS sp_product_list;[cite: 15]
DROP PROCEDURE IF EXISTS sp_product_list_by_price;[cite: 15]
DROP PROCEDURE IF EXISTS sp_total_produtos;[cite: 15]
DROP PROCEDURE IF EXISTS sp_buscar_produto;[cite: 15]
DROP PROCEDURE IF EXISTS sp_avaliar_vendas_ano;[cite: 15]
DROP PROCEDURE IF EXISTS sp_testar_while;[cite: 15]
DROP PROCEDURE IF EXISTS sp_dynamic_query;[cite: 15]

-- Limpar variáveis de sessão utilizadas
SET @ano_filtro = NULL;[cite: 15]
SET @total_cadastrado = NULL;[cite: 15]
SET @nome_encontrado = NULL;[cite: 15]
SET @produto = NULL;[cite: 15]
SET @sql_text = NULL;[cite: 15]