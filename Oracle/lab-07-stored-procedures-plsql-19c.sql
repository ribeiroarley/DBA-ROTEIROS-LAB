/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-07-stored-procedures-plsql-19c.sql
  Objetivo     : Roteiro prático sobre criação e execução de Stored Procedures (PL/SQL), parâmetros IN/OUT e DEFAULT, estruturas de controle (IF, LOOP, WHILE), transações em blocos com SAVEPOINT, SQL Dinâmico (EXECUTE IMMEDIATE) e mitigação de SQL Injection via Bind Variables no Oracle Database 19c.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Documentation
*******************************************************************************/

/* PARTE 1 - SETUP DE CONEXÃO E PRIVILÉGIOS (SYSDBA / USUARIO_TESTE) */

-- Conectar como SYSDBA e abrir o PDB
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Conceder privilégio de criação de Procedures para o Schema USUARIO_TESTE
GRANT CREATE PROCEDURE TO usuario_teste CONTAINER=CURRENT;

-- Alternar sessão para o Schema USUARIO_TESTE
CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;

-- Habilitar saída de buffer de texto no terminal
SET SERVEROUTPUT ON;


/* PARTE 2 - STORED PROCEDURES BÁSICAS E CONSULTAS AGREGADAS */

-- Procedure simples de Hello World
CREATE OR REPLACE PROCEDURE usuario_teste.hello_oracle AS 
BEGIN
   DBMS_OUTPUT.PUT_LINE('HELLO WORLD!'); 
END hello_oracle;
/

-- Execução da Procedure
BEGIN
  usuario_teste.hello_oracle;
END;
/

-- Procedure para consulta agregada e armazenamento em variável local
CREATE OR REPLACE PROCEDURE usuario_teste.prc_qtde_vendas AS 
  v_soma_vendas NUMBER;
BEGIN
   SELECT SUM(totalamount) INTO v_soma_vendas FROM usuario_teste."order";
   DBMS_OUTPUT.PUT_LINE('Soma de Vendas: ' || v_soma_vendas);
END prc_qtde_vendas;
/

-- Execução
BEGIN
  usuario_teste.prc_qtde_vendas;
END;
/


/* PARTE 3 - PARÂMETROS IN, OUT E ESTRUTURAS CONDICIONAIS */

-- Procedure com parâmetro de entrada (IN) e saída (OUT) para cálculo do volume de esfera
CREATE OR REPLACE PROCEDURE usuario_teste.p_esfera (
  p_raio   IN  NUMBER, 
  p_volume OUT NUMBER
) IS
  c_pi CONSTANT NUMBER := 3.14159265;
BEGIN 
  p_volume := (4 / 3) * c_pi * POWER(p_raio, 3); 
END p_esfera;
/

-- Teste da procedure com variáveis de bloco anônimo
DECLARE 
   v_raio   NUMBER := 10;
   v_volume NUMBER;
BEGIN
    usuario_teste.p_esfera(v_raio, v_volume);
    DBMS_OUTPUT.PUT_LINE('Raio: ' || v_raio || ' | Volume Calculado: ' || v_volume);
END;
/

-- Procedure com controle condicional IF...ELSE
CREATE OR REPLACE PROCEDURE usuario_teste.prc_compara_menor (
  p_x IN  NUMBER,
  p_y IN  NUMBER,
  p_z OUT NUMBER
) AS
BEGIN
  IF p_x < p_y THEN
    p_z := p_x;
  ELSE
    p_z := p_y;
  END IF;
END prc_compara_menor;
/

-- Execução
DECLARE
  v_val1   NUMBER := 10;
  v_val2   NUMBER := 5;
  v_menor  NUMBER;
BEGIN
  usuario_teste.prc_compara_menor(v_val1, v_val2, v_menor);
  DBMS_OUTPUT.PUT_LINE('O menor valor entre ' || v_val1 || ' e ' || v_val2 || ' eh: ' || v_menor);
END;
/


/* PARTE 4 - ESTRUTURAS DE REPETIÇÃO (LOOP SIMPLES E WHILE) */

-- Procedure com LOOP simples e condição EXIT
CREATE OR REPLACE PROCEDURE usuario_teste.prc_exemplo_loop AS 
  v_cont NUMBER := 0;
BEGIN
  LOOP
    v_cont := v_cont + 1;
    DBMS_OUTPUT.PUT_LINE('Resultado Loop Simples: ' || v_cont); 
    IF v_cont >= 10 THEN
      EXIT;
    END IF;
  END LOOP;
END prc_exemplo_loop;
/

BEGIN
   usuario_teste.prc_exemplo_loop;
END;
/

-- Procedure com WHILE LOOP
CREATE OR REPLACE PROCEDURE usuario_teste.prc_exemplo_while AS 
  v_cont NUMBER := 0;
BEGIN
  WHILE v_cont < 10 LOOP
    v_cont := v_cont + 1;
    DBMS_OUTPUT.PUT_LINE('Resultado While Loop: ' || v_cont);
  END LOOP;
END prc_exemplo_while;
/

BEGIN
   usuario_teste.prc_exemplo_while;
END;
/


/* PARTE 5 - CURSORES IMPLÍCITOS, PARÂMETROS MÚLTIPLOS E OPCIONAIS (DEFAULT) */

-- Cursor FOR LOOP para percorrer registros
CREATE OR REPLACE PROCEDURE usuario_teste.get_product_details IS
BEGIN
  FOR product_rec IN (
    SELECT id, productname, supplierid, unitprice, package, isdiscontinued
    FROM usuario_teste.product
    ORDER BY productname DESC
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Id: ' || product_rec.id || 
                         ', ProductName: ' || product_rec.productname || 
                         ', UnitPrice: ' || product_rec.unitprice);
  END LOOP;
END get_product_details;
/

BEGIN
  usuario_teste.get_product_details;
END;
/

-- Procedure com parâmetros opcionais (DEFAULT NULL) e ancoragem de tipos (%TYPE)
CREATE OR REPLACE PROCEDURE usuario_teste.get_product_details_opt (
  p_supplier_id IN usuario_teste.product.supplierid%TYPE  DEFAULT NULL,
  p_min_price   IN usuario_teste.product.unitprice%TYPE   DEFAULT NULL,
  p_prod_name   IN usuario_teste.product.productname%TYPE DEFAULT NULL
) IS
BEGIN
  FOR product_rec IN (
    SELECT id, productname, supplierid, unitprice, package, isdiscontinued
    FROM usuario_teste.product
    WHERE (p_supplier_id IS NULL OR supplierid = p_supplier_id)
      AND (p_min_price   IS NULL OR unitprice >= p_min_price)
      AND (p_prod_name   IS NULL OR productname LIKE '%' || p_prod_name || '%')
    ORDER BY productname DESC
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Id: ' || product_rec.id || 
                         ' | Prod: ' || product_rec.productname || 
                         ' | Preco: ' || product_rec.unitprice);
  END LOOP;
END get_product_details_opt;
/

-- Teste com todos os parâmetros
BEGIN
  usuario_teste.get_product_details_opt(p_supplier_id => 2, p_min_price => 10.00, p_prod_name => 'Louisiana');
END;
/

-- Teste omitindo filtros (Parâmetros Nulos)
BEGIN
  usuario_teste.get_product_details_opt(p_supplier_id => NULL, p_min_price => 10.00, p_prod_name => NULL);
END;
/


/* PARTE 6 - TRANSAÇÕES EM BLOCOS DENTRO DE STORED PROCEDURES */

-- Procedure encapsulando transação e tratamento de exceções com SAVEPOINT
CREATE OR REPLACE PROCEDURE usuario_teste.prc_insere_dados_bloco AS 
  v_error_message VARCHAR2(4000);
BEGIN
  SAVEPOINT start_transaction;

  -- Comandos de carga removidos. UPDATE usado como exemplo.
  UPDATE usuario_teste.supplier SET city = 'City A' WHERE id = 400;

  COMMIT;

EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    v_error_message := SQLERRM;
    ROLLBACK TO SAVEPOINT start_transaction;
    RAISE_APPLICATION_ERROR(-20001, 'Erro de Chave Duplicada: ' || v_error_message);

  WHEN OTHERS THEN
    v_error_message := SQLERRM;
    ROLLBACK TO SAVEPOINT start_transaction;
    RAISE_APPLICATION_ERROR(-20002, 'Erro na Transação: ' || v_error_message);
END prc_insere_dados_bloco;
/

BEGIN
  usuario_teste.prc_insere_dados_bloco;
END;
/


/* PARTE 7 - SQL DINÂMICO (EXECUTE IMMEDIATE) E BIND VARIABLES (ANTI-SQL INJECTION) */

-- Procedure com SQL Dinâmico Genérico
CREATE OR REPLACE PROCEDURE usuario_teste.prc_count_tabela (
  p_table_name IN VARCHAR2
) AS
  v_sql    VARCHAR2(1000);
  v_result NUMBER;
BEGIN
  -- Construção da query dinâmica sanitizada
  v_sql := 'SELECT COUNT(*) FROM ' || DBMS_ASSERT.SQL_OBJECT_NAME(p_table_name);

  EXECUTE IMMEDIATE v_sql INTO v_result;

  DBMS_OUTPUT.PUT_LINE('Total de registros na tabela ' || p_table_name || ': ' || v_result);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro na execução do SQL Dinâmico: ' || SQLERRM);
END prc_count_tabela;
/

BEGIN
  usuario_teste.prc_count_tabela('CUSTOMER');
  usuario_teste.prc_count_tabela('PRODUCT');
END;
/

-- Demonstração de Prevenção de SQL Injection utilizando BIND VARIABLES (:v_id)
DECLARE
    v_query    VARCHAR2(1000);
    v_result   SYS_REFCURSOR;
    v_customer usuario_teste.customer%ROWTYPE;
    v_id       NUMBER := 1; -- Parâmetro seguro
BEGIN
    -- Utilização de sintaxe segura com Bind Variable
    v_query := 'SELECT * FROM usuario_teste.customer WHERE id = :v_id';

    OPEN v_result FOR v_query USING v_id;

    LOOP
        FETCH v_result INTO v_customer;
        EXIT WHEN v_result%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('ID: ' || v_customer.id || 
                             ' | Name: ' || v_customer.firstname || 
                             ' | City: ' || v_customer.city);
    END LOOP;

    CLOSE v_result;
END;
/


/* PARTE 8 - LIMPEZA DE OBJETOS DO LABORATÓRIO (DROP PROCEDURES) */

DROP PROCEDURE usuario_teste.hello_oracle;
DROP PROCEDURE usuario_teste.prc_qtde_vendas;
DROP PROCEDURE usuario_teste.p_esfera;
DROP PROCEDURE usuario_teste.prc_compara_menor;
DROP PROCEDURE usuario_teste.prc_exemplo_loop;
DROP PROCEDURE usuario_teste.prc_exemplo_while;
DROP PROCEDURE usuario_teste.get_product_details;
DROP PROCEDURE usuario_teste.get_product_details_opt;
DROP PROCEDURE usuario_teste.prc_insere_dados_bloco;
DROP PROCEDURE usuario_teste.prc_count_tabela;

-- Limpeza de registros criados nos testes
DELETE FROM usuario_teste.product  WHERE id = 400;
DELETE FROM usuario_teste.customer WHERE id = 400;
DELETE FROM usuario_teste.supplier WHERE id = 400;
COMMIT;

/* PARTE 99 - CLEANUP */
-- CONNECT / AS SYSDBA;
-- ALTER SESSION SET CONTAINER = ORCLPDB;
-- DROP USER usuario_teste CASCADE;