/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-12-autocommit-e-isolamento-sessoes-19c.sql
  Objetivo     : Roteiro prático sobre controle de transações no Oracle 19c, 
                 comportamento do AUTOCOMMIT (ON/OFF), isolamento de leitura 
                 entre sessões concorrentes e visibilidade de dados DML via PL/SQL.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Database Concepts / SQL Language Reference
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SETUP DE CONEXÃO E PREPARAÇÃO DO AMBIENTE (SYSDBA / CLIENTE)
--------------------------------------------------------------------------------

-- Conectar como SYSDBA e garantir abertura do PDB
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Criar usuário secundário para testes de visibilidade entre sessões
CREATE USER arleyribeiro IDENTIFIED BY "arley123" CONTAINER=CURRENT;
ALTER USER arleyribeiro DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp ACCOUNT UNLOCK;
GRANT CREATE SESSION, CONNECT TO arleyribeiro CONTAINER=CURRENT;

-- Alternar para o Schema CLIENTE
CONNECT cliente/a123@//localhost:1521/ORCLPDB;

-- Tabela de apoio para os testes de transação
CREATE TABLE cliente.minha_tabela (
    id   NUMBER PRIMARY KEY,
    nome VARCHAR2(50) NOT NULL
);

-- Conceder permissão de leitura para o usuário arleyribeiro
GRANT SELECT ON cliente.minha_tabela TO arleyribeiro;

SET SERVEROUTPUT ON;


--------------------------------------------------------------------------------
-- PARTE 2: TESTE DE ISOLAMENTO DE LEITURA (AUTOCOMMIT OFF)
--------------------------------------------------------------------------------

-- Verificar status atual do autocommit na sessão
SHOW AUTOCOMMIT;

-- Garantir que o autocommit está desativado
SET AUTOCOMMIT OFF;

-- Limpar dados da tabela
DELETE FROM cliente.minha_tabela;
COMMIT;

-- Inserir registro sem efetuar COMMIT
INSERT INTO cliente.minha_tabela (id, nome) VALUES (1, 'Alice SEM COMMIT');

-- Consultar na sessão atual (Dado visível localmente)
SELECT * FROM cliente.minha_tabela;

-- SESSÃO SECUNDÁRIA (Simulação de leitura concorrente):
-- Conectar como arleyribeiro e verificar que o registro pendente NÃO é visível
CONNECT arleyribeiro/arley123@//localhost:1521/ORCLPDB;
SELECT * FROM cliente.minha_tabela;

-- Reassumir Sessão CLIENTE e efetivar a transação
CONNECT cliente/a123@//localhost:1521/ORCLPDB;
SET AUTOCOMMIT OFF;
COMMIT;

-- SESSÃO SECUNDÁRIA:
-- Reconsultar como arleyribeiro após o COMMIT (Dado agora visível)
CONNECT arleyribeiro/arley123@//localhost:1521/ORCLPDB;
SELECT * FROM cliente.minha_tabela;


--------------------------------------------------------------------------------
-- PARTE 3: COMPORTAMENTO COM AUTOCOMMIT ON (EFETIVAÇÃO AUTOMÁTICA)
--------------------------------------------------------------------------------

CONNECT cliente/a123@//localhost:1521/ORCLPDB;

-- Habilitar confirmação automática por comando SQL
SET AUTOCOMMIT ON;
SHOW AUTOCOMMIT;

-- Inserção de registro sob AUTOCOMMIT ON
INSERT INTO cliente.minha_tabela (id, nome) VALUES (2, 'Alice COM AUTOCOMMIT');

-- SESSÃO SECUNDÁRIA:
-- Consultar como arleyribeiro (Registro visível imediatamente sem COMMIT manual)
CONNECT arleyribeiro/arley123@//localhost:1521/ORCLPDB;
SELECT * FROM cliente.minha_tabela;


--------------------------------------------------------------------------------
-- PARTE 4: PACOTES PL/SQL E COMPORTAMENTO TRANSACTIONAL
--------------------------------------------------------------------------------

CONNECT cliente/a123@//localhost:1521/ORCLPDB;
SET AUTOCOMMIT OFF;

-- Reinstalar pacote sem instruções explicitas de COMMIT internas
CREATE OR REPLACE PACKAGE cliente.meu_pacote AS
    PROCEDURE inserir_dados(p_id IN NUMBER, p_nome IN VARCHAR2);
    FUNCTION inserir_dados_funcao(p_id IN NUMBER, p_nome IN VARCHAR2) RETURN NUMBER;
    FUNCTION ler_dados RETURN SYS_REFCURSOR;
END meu_pacote;
/

CREATE OR REPLACE PACKAGE BODY cliente.meu_pacote AS

    PROCEDURE inserir_dados(p_id IN NUMBER, p_nome IN VARCHAR2) IS
    BEGIN
        INSERT INTO cliente.minha_tabela (id, nome) VALUES (p_id, p_nome);
    END inserir_dados;

    FUNCTION inserir_dados_funcao(p_id IN NUMBER, p_nome IN VARCHAR2) RETURN NUMBER IS
    BEGIN
        INSERT INTO cliente.minha_tabela (id, nome) VALUES (p_id, p_nome);
        RETURN 1;
    END inserir_dados_funcao;

    FUNCTION ler_dados RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR SELECT id, nome FROM cliente.minha_tabela ORDER BY id;
        RETURN v_cursor;
    END ler_dados;

END meu_pacote;
/

-- Conceder permissão de execução do pacote ao usuário arleyribeiro
GRANT EXECUTE ON cliente.meu_pacote TO arleyribeiro;

-- Executar procedure do pacote com AUTOCOMMIT OFF
BEGIN
    cliente.meu_pacote.inserir_dados(101, 'Arley SEM COMMIT NO PACOTE');
    cliente.meu_pacote.inserir_dados(102, 'Bob SEM COMMIT NO PACOTE');
END;
/

-- SESSÃO SECUNDÁRIA:
-- Consumir o cursor via pacote como arleyribeiro (Registros 101 e 102 NÃO aparecem)
CONNECT arleyribeiro/arley123@//localhost:1521/ORCLPDB;
SET SERVEROUTPUT ON;

DECLARE
    v_cur  SYS_REFCURSOR;
    v_id   NUMBER;
    v_nome VARCHAR2(50);
BEGIN
    v_cur := cliente.meu_pacote.ler_dados;
    LOOP
        FETCH v_cur INTO v_id, v_nome;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ' | Nome: ' || v_nome);
    END LOOP;
    CLOSE v_cur;
END;
/

-- Reassumir Sessão CLIENTE e efetivar transação do pacote
CONNECT cliente/a123@//localhost:1521/ORCLPDB;
COMMIT;

-- SESSÃO SECUNDÁRIA:
-- Reconsultar como arleyribeiro (Registros 101 e 102 agora visíveis)
CONNECT arleyribeiro/arley123@//localhost:1521/ORCLPDB;
SET SERVEROUTPUT ON;

DECLARE
    v_cur  SYS_REFCURSOR;
    v_id   NUMBER;
    v_nome VARCHAR2(50);
BEGIN
    v_cur := cliente.meu_pacote.ler_dados;
    LOOP
        FETCH v_cur INTO v_id, v_nome;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ' | Nome: ' || v_nome);
    END LOOP;
    CLOSE v_cur;
END;
/


--------------------------------------------------------------------------------
-- PARTE 5: EXECUÇÃO DE PACOTES COM AUTOCOMMIT ON
--------------------------------------------------------------------------------

CONNECT cliente/a123@//localhost:1521/ORCLPDB;

SET AUTOCOMMIT ON;

-- Executar inserção via pacote sob AUTOCOMMIT ON
BEGIN
    cliente.meu_pacote.inserir_dados(201, 'Arley COM AUTOCOMMIT ON');
    cliente.meu_pacote.inserir_dados(202, 'Bob COM AUTOCOMMIT ON');
END;
/

SET AUTOCOMMIT OFF;

-- SESSÃO SECUNDÁRIA:
-- Validar visibilidade imediata dos registros 201 e 202
CONNECT arleyribeiro/arley123@//localhost:1521/ORCLPDB;
SET SERVEROUTPUT ON;

DECLARE
    v_cur  SYS_REFCURSOR;
    v_id   NUMBER;
    v_nome VARCHAR2(50);
BEGIN
    v_cur := cliente.meu_pacote.ler_dados;
    LOOP
        FETCH v_cur INTO v_id, v_nome;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ' | Nome: ' || v_nome);
    END LOOP;
    CLOSE v_cur;
END;
/


--------------------------------------------------------------------------------
-- PARTE 6: LIMPEZA DOS OBJETOS DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Excluir pacote e tabela de testes
DROP PACKAGE cliente.meu_pacote;
DROP TABLE cliente.minha_tabela PURGE;

-- Remover usuário de testes
DROP USER arleyribeiro CASCADE;