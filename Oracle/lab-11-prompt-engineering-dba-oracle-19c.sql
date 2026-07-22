/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-11-prompt-engineering-dba-oracle-19c.sql
  Objetivo     : Roteiro prático e conjunto de prompts estruturados para auxílio na
                 geração, otimização e validação de scripts SQL/PLSQL via IA (ChatGPT/LLMs)
                 no Oracle Database 19c Multitenant (CDB/PDB).
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c SQL Language Reference / PL/SQL Language Guide
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SETUP DE CONEXÃO E AMBIENTE (SYSDBA / CLIENTE)
--------------------------------------------------------------------------------

-- Conectar como SYSDBA e abrir o PDB
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Habilitar saída do buffer de texto
SET SERVEROUTPUT ON;


--------------------------------------------------------------------------------
-- PARTE 2: GUIA DE PROMPTS PARA OTIMIZAÇÃO E GERACÃO DE SCRIPTS
--------------------------------------------------------------------------------

/*
  EXEMPLO DE PROMPT DE ENGENHARIA PARA DBA ORACLE (COPIAR E USAR NA IA):
  
  "Atue como um DBA Oracle Sênior. Preciso de um script PL/SQL para o Oracle 19c Multitenant.
   Requisitos:
   1. Criar uma procedure no schema 'cliente' que receba o ID do cliente.
   2. Retornar o total de vendas do cliente utilizando a tabela 'order'.
   3. Tratar a exceção NO_DATA_FOUND e retornar uma mensagem amigável via DBMS_OUTPUT.
   4. Utilizar boas práticas de segurança (Bind Variables) para evitar SQL Injection."
*/


--------------------------------------------------------------------------------
-- PARTE 3: CÓDIGO PL/SQL GERADO E VALIDADO PARA O LABORATÓRIO
--------------------------------------------------------------------------------

-- Criação da procedure base gerada para consulta atômica de vendas por cliente
CREATE OR REPLACE PROCEDURE cliente.prc_consulta_vendas_cliente (
    p_customer_id IN cliente.customer.id%TYPE
) IS
    v_total_vendas NUMBER(12, 2) := 0;
    v_nome_cliente cliente.customer.firstname%TYPE;
BEGIN
    -- Obter o nome do cliente
    SELECT firstname || ' ' || lastname 
      INTO v_nome_cliente
      FROM cliente.customer
     WHERE id = p_customer_id;

    -- Obter o somatório dos pedidos do cliente
    SELECT NVL(SUM(totalamount), 0)
      INTO v_total_vendas
      FROM cliente."order"
     WHERE customerid = p_customer_id;

    -- Exibir o resultado no console
    DBMS_OUTPUT.PUT_LINE('Cliente: ' || v_nome_cliente || ' | Total em Compras: R$ ' || TO_CHAR(v_total_vendas, 'FM999G990D00'));

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Alerta: O cliente com ID ' || p_customer_id || ' não foi localizado no banco de dados.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro na execução da consulta: ' || SQLERRM);
END prc_consulta_vendas_cliente;
/


--------------------------------------------------------------------------------
-- PARTE 4: TESTES OPERACIONAIS DA PROCEDURE
--------------------------------------------------------------------------------

-- Execução para cliente existente
BEGIN
    cliente.prc_consulta_vendas_cliente(p_customer_id => 1);
END;
/

-- Execução para cliente inexistente (Validação do tratamento de exceção)
BEGIN
    cliente.prc_consulta_vendas_cliente(p_customer_id => 99999);
END;
/


--------------------------------------------------------------------------------
-- PARTE 5: LIMPEZA DOS OBJETOS DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

/*
DROP PROCEDURE cliente.prc_consulta_vendas_cliente;
*/