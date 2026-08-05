/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-10-pacotes-plsql-19c.sql
  Objetivo     : Roteiro prático cobrindo criação de Packages PL/SQL (Specification e Body), encapsulamento de Procedures, Functions e SYS_REFCURSOR, concessão e revogação de privilégios de execução (GRANT EXECUTE) e consumo de pacotes por usuários secundários no Oracle Database 19c Multitenant (CDB/PDB).
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Documentation
*******************************************************************************/

/* PARTE 1 - SETUP DE AMBIENTE E PRIVILÉGIOS (SYSDBA / USUARIO_TESTE) */

-- Conectar como SYSDBA e abrir o PDB
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Conceder privilégio de criação de Packages para o Schema USUARIO_TESTE
GRANT CREATE PACKAGE TO usuario_teste CONTAINER=CURRENT;

-- Criar usuário secundário para testes de permissão e privilégios
CREATE USER usuario_teste_secundario IDENTIFIED BY "teste123" CONTAINER=CURRENT;
ALTER USER usuario_teste_secundario DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp ACCOUNT UNLOCK;
GRANT CREATE SESSION, CONNECT TO usuario_teste_secundario CONTAINER=CURRENT;

-- Alternar sessão para o Schema USUARIO_TESTE
CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;

-- Habilitar exibição de saídas no terminal
SET SERVEROUTPUT ON;


/* PARTE 2 - CRIAÇÃO DO PRIMEIRO PACOTE (ESPECIFICAÇÃO E CORPO) */

-- 1. Especificação do Pacote (Interface Pública)
CREATE OR REPLACE PACKAGE usuario_teste.calculadora_media AS
    PROCEDURE calcular_media(p_valor1 IN NUMBER, p_valor2 IN NUMBER);
    FUNCTION obter_media(p_valor1 IN NUMBER, p_valor2 IN NUMBER) RETURN NUMBER;
END calculadora_media;
/

-- 2. Corpo do Pacote (Implementação Privada)
CREATE OR REPLACE PACKAGE BODY usuario_teste.calculadora_media AS

    PROCEDURE calcular_media(p_valor1 IN NUMBER, p_valor2 IN NUMBER) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Media Calculada: ' || (p_valor1 + p_valor2) / 2);
    END calcular_media;

    FUNCTION obter_media(p_valor1 IN NUMBER, p_valor2 IN NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN (p_valor1 + p_valor2) / 2;
    END obter_media;

END calculadora_media;
/


/* PARTE 3 - EXECUÇÃO E TESTES DE MÉTODOS DO PACOTE */

-- Execução do procedimento do pacote
BEGIN
    usuario_teste.calculadora_media.calcular_media(10, 20);
END;
/

-- Execução da função do pacote via bloco anônimo
DECLARE
    v_media NUMBER;
BEGIN
    v_media := usuario_teste.calculadora_media.obter_media(15, 25);
    DBMS_OUTPUT.PUT_LINE('Media obtida via Function: ' || v_media);
END;
/


/* PARTE 4 - CONTROLE DE ACESSO E CONCESSÃO DE PRIVILÉGIOS (GRANT / REVOKE) */

-- Conceder permissão de execução do pacote para o usuário usuario_teste_secundario
GRANT EXECUTE ON usuario_teste.calculadora_media TO usuario_teste_secundario;

-- Conectar como o usuário secundário usuario_teste_secundario
CONNECT usuario_teste_secundario/teste123@//localhost:1521/ORCLPDB;
SET SERVEROUTPUT ON;

-- Testar execução do pacote pertencente ao Schema USUARIO_TESTE
BEGIN
    usuario_teste.calculadora_media.calcular_media(10, 20);
END;
/

DECLARE
    v_media NUMBER;
BEGIN
    v_media := usuario_teste.calculadora_media.obter_media(15, 25);
    DBMS_OUTPUT.PUT_LINE('Media obtida por usuario_teste_secundario: ' || v_media);
END;
/

-- Reconectar como USUARIO_TESTE para revogar privilégios
CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;

REVOKE EXECUTE ON usuario_teste.calculadora_media FROM usuario_teste_secundario;

-- Testar acesso negado (Esperado erro ORA-00942 ou ORA-01031 ao reconectar)
CONNECT usuario_teste_secundario/teste123@//localhost:1521/ORCLPDB;
SET SERVEROUTPUT ON;

/*
BEGIN
    usuario_teste.calculadora_media.calcular_media(10, 20);
END;
/
*/

-- Reassumir conexão com o Schema USUARIO_TESTE e reestabelecer o privilégio
CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;
GRANT EXECUTE ON usuario_teste.calculadora_media TO usuario_teste_secundario;


/* PARTE 5 - PACOTE AVANÇADO COM DML E CURSORES (SYS_REFCURSOR) */

-- Tabela de apoio para os testes de DML e cursores
CREATE TABLE usuario_teste.minha_tabela (
    id   NUMBER PRIMARY KEY,
    nome VARCHAR2(50) NOT NULL
);

-- Especificação do Pacote Avançado
CREATE OR REPLACE PACKAGE usuario_teste.meu_pacote AS
    PROCEDURE inserir_dados(p_id IN NUMBER, p_nome IN VARCHAR2);
    FUNCTION inserir_dados_funcao(p_id IN NUMBER, p_nome IN VARCHAR2) RETURN NUMBER;
    FUNCTION ler_dados RETURN SYS_REFCURSOR;
END meu_pacote;
/

-- Corpo do Pacote Avançado
CREATE OR REPLACE PACKAGE BODY usuario_teste.meu_pacote AS

    PROCEDURE inserir_dados(p_id IN NUMBER, p_nome IN VARCHAR2) IS
    BEGIN
        -- Comandos de carga removidos (INSERT)
        NULL;
    END inserir_dados;

    FUNCTION inserir_dados_funcao(p_id IN NUMBER, p_nome IN VARCHAR2) RETURN NUMBER IS
    BEGIN
        -- Comandos de carga removidos (INSERT)
        RETURN 1;
    END inserir_dados_funcao;

    FUNCTION ler_dados RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR SELECT id, nome FROM usuario_teste.minha_tabela ORDER BY id;
        RETURN v_cursor;
    END ler_dados;

END meu_pacote;
/


/* PARTE 6 - EXECUÇÃO DO PACOTE AVANÇADO E CONSUMO DE CURSOR */

-- Chamada da Procedure do pacote
BEGIN
    usuario_teste.meu_pacote.inserir_dados(1, 'Alice');
    usuario_teste.meu_pacote.inserir_dados(2, 'Bob');
END;
/

-- Chamada da Function com retorno de indicador
DECLARE
    v_result NUMBER;
BEGIN
    v_result := usuario_teste.meu_pacote.inserir_dados_funcao(4, 'Ana');
    DBMS_OUTPUT.PUT_LINE('Status da insercao: ' || v_result);
END;
/

-- Consumo do Cursor SYS_REFCURSOR retornado pela Function
DECLARE
    v_cur  SYS_REFCURSOR;
    v_id   NUMBER;
    v_nome VARCHAR2(50);
BEGIN
    v_cur := usuario_teste.meu_pacote.ler_dados;
    LOOP
        FETCH v_cur INTO v_id, v_nome;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ' | Nome: ' || v_nome);
    END LOOP;
    CLOSE v_cur;
END;
/


/* PARTE 7 - ACESSO DE USUÁRIO SECUNDÁRIO AO PACOTE COM CURSOR */

-- Conceder permissão de execução do novo pacote e acesso à tabela base
GRANT EXECUTE ON usuario_teste.meu_pacote TO usuario_teste_secundario;
GRANT SELECT, INSERT ON usuario_teste.minha_tabela TO usuario_teste_secundario;

-- Testar consumo do cursor pelo usuário usuario_teste_secundario
CONNECT usuario_teste_secundario/teste123@//localhost:1521/ORCLPDB;
SET SERVEROUTPUT ON;

DECLARE
    v_cur  SYS_REFCURSOR;
    v_id   NUMBER;
    v_nome VARCHAR2(50);
BEGIN
    v_cur := usuario_teste.meu_pacote.ler_dados;
    LOOP
        FETCH v_cur INTO v_id, v_nome;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Acesso por usuario_teste_secundario -> ID: ' || v_id || ' | Nome: ' || v_nome);
    END LOOP;
    CLOSE v_cur;
END;
/


/* PARTE 8 - LIMPEZA DOS OBJETOS DO LABORATÓRIO (CLEANUP) */

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Exclusão de pacotes e tabela de teste
DROP PACKAGE usuario_teste.calculadora_media;
DROP PACKAGE usuario_teste.meu_pacote;
DROP TABLE usuario_teste.minha_tabela PURGE;

-- Remoção do usuário de testes
DROP USER usuario_teste_secundario CASCADE;

/* PARTE 99 - CLEANUP */
-- DROP USER usuario_teste CASCADE;