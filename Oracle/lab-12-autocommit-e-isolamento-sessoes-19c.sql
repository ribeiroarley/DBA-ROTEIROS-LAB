/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-12-autocommit-e-isolamento-sessoes-19c.sql
  Objetivo     : Roteiro prático sobre controle de transações no Oracle 19c, comportamento do AUTOCOMMIT (ON/OFF), isolamento de leitura entre sessões concorrentes e visibilidade de dados DML via PL/SQL.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Documentation
*******************************************************************************/

/* PARTE 1 - SETUP DE CONEXÃO E PREPARAÇÃO DO AMBIENTE (SYSDBA / USUARIO_TESTE) */

-- Conectar como SYSDBA e garantir abertura do PDB
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Criar usuário secundário para testes de visibilidade entre sessões
CREATE USER usuario_teste_secundario IDENTIFIED BY "teste123" CONTAINER=CURRENT;
ALTER USER usuario_teste_secundario DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp ACCOUNT UNLOCK;
GRANT CREATE SESSION, CONNECT TO usuario_teste_secundario CONTAINER=CURRENT;

-- Alternar para o Schema USUARIO_TESTE
CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;

-- Tabela de apoio para os testes de transação
CREATE TABLE usuario_teste.minha_tabela (
    id   NUMBER PRIMARY KEY,
    nome VARCHAR2(50) NOT NULL
);

-- Conceder permissão de leitura para o usuário usuario_teste_secundario
GRANT SELECT ON usuario_teste.minha_tabela TO usuario_teste_secundario;

SET SERVEROUTPUT ON;


/* PARTE 2 - TESTE DE ISOLAMENTO DE LEITURA (AUTOCOMMIT OFF) */

-- Verificar status atual do autocommit na sessão
SHOW AUTOCOMMIT;

-- Garantir que o autocommit está desativado
SET AUTOCOMMIT OFF;

-- Limpar dados da tabela
DELETE FROM usuario_teste.minha_tabela;
COMMIT;

-- (Inserções foram removidas como regra de laboratório, simularemos com DML UPDATE em tabelas povoadas previamente se necessário)
-- INSERT INTO usuario_teste.minha_tabela (id, nome) VALUES (1, 'Alice SEM COMMIT');

-- Consultar na sessão atual (Dado visível localmente)
SELECT * FROM usuario_teste.minha_tabela;

-- SESSÃO SECUNDÁRIA (Simulação de leitura concorrente):
-- Conectar como usuario_teste_secundario e verificar que o registro pendente NÃO é visível
CONNECT usuario_teste_secundario/teste123@//localhost:1521/ORCLPDB;
SELECT * FROM usuario_teste.minha_tabela;

-- Reassumir Sessão USUARIO_TESTE e efetivar a transação
CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;
SET AUTOCOMMIT OFF;
COMMIT;

-- SESSÃO SECUNDÁRIA:
-- Reconsultar como usuario_teste_secundario após o COMMIT (Dado agora visível)
CONNECT usuario_teste_secundario/teste123@//localhost:1521/ORCLPDB;
SELECT * FROM usuario_teste.minha_tabela;


/* PARTE 3 - COMPORTAMENTO COM AUTOCOMMIT ON (EFETIVAÇÃO AUTOMÁTICA) */

CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;

-- Habilitar confirmação automática por comando SQL
SET AUTOCOMMIT ON;
SHOW AUTOCOMMIT;

-- SESSÃO SECUNDÁRIA:
-- Consultar como usuario_teste_secundario (Registro visível imediatamente sem COMMIT manual)
CONNECT usuario_teste_secundario/teste123@//localhost:1521/ORCLPDB;
SELECT * FROM usuario_teste.minha_tabela;


/* PARTE 4 - PACOTES PL/SQL E COMPORTAMENTO TRANSACTIONAL */

CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;
SET AUTOCOMMIT OFF;

-- Reinstalar pacote sem instruções explicitas de COMMIT internas
CREATE OR REPLACE PACKAGE usuario_teste.meu_pacote AS
    PROCEDURE inserir_dados(p_id IN NUMBER, p_nome IN VARCHAR2);
    FUNCTION inserir_dados_funcao(p_id IN NUMBER, p_nome IN VARCHAR2) RETURN NUMBER;
    FUNCTION ler_dados RETURN SYS_REFCURSOR;
END meu_pacote;
/

CREATE OR REPLACE PACKAGE BODY usuario_teste.meu_pacote AS

    PROCEDURE inserir_dados(p_id IN NUMBER, p_nome IN VARCHAR2) IS
    BEGIN
        -- INSERT removido
        NULL;
    END inserir_dados;

    FUNCTION inserir_dados_funcao(p_id IN NUMBER, p_nome IN VARCHAR2) RETURN NUMBER IS
    BEGIN
        -- INSERT removido
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

-- Conceder permissão de execução do pacote ao usuário usuario_teste_secundario
GRANT EXECUTE ON usuario_teste.meu_pacote TO usuario_teste_secundario;

-- Executar procedure do pacote com AUTOCOMMIT OFF
BEGIN
    usuario_teste.meu_pacote.inserir_dados(101, 'Arley SEM COMMIT NO PACOTE');
    usuario_teste.meu_pacote.inserir_dados(102, 'Bob SEM COMMIT NO PACOTE');
END;
/

-- SESSÃO SECUNDÁRIA:
-- Consumir o cursor via pacote como usuario_teste_secundario
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
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ' | Nome: ' || v_nome);
    END LOOP;
    CLOSE v_cur;
END;
/

-- Reassumir Sessão USUARIO_TESTE e efetivar transação do pacote
CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;
COMMIT;

-- SESSÃO SECUNDÁRIA:
-- Reconsultar como usuario_teste_secundario 
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
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ' | Nome: ' || v_nome);
    END LOOP;
    CLOSE v_cur;
END;
/


/* PARTE 5 - EXECUÇÃO DE PACOTES COM AUTOCOMMIT ON */

CONNECT usuario_teste/teste123@//localhost:1521/ORCLPDB;

SET AUTOCOMMIT ON;

-- Executar inserção via pacote sob AUTOCOMMIT ON
BEGIN
    usuario_teste.meu_pacote.inserir_dados(201, 'Arley COM AUTOCOMMIT ON');
    usuario_teste.meu_pacote.inserir_dados(202, 'Bob COM AUTOCOMMIT ON');
END;
/

SET AUTOCOMMIT OFF;

-- SESSÃO SECUNDÁRIA:
-- Validar visibilidade imediata
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
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ' | Nome: ' || v_nome);
    END LOOP;
    CLOSE v_cur;
END;
/


/* PARTE 6 - LIMPEZA DOS OBJETOS DO LABORATÓRIO (CLEANUP) */

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Excluir pacote e tabela de testes
DROP PACKAGE usuario_teste.meu_pacote;
DROP TABLE usuario_teste.minha_tabela PURGE;

-- Remover usuário de testes
DROP USER usuario_teste_secundario CASCADE;

/* PARTE 99 - CLEANUP */
-- DROP USER usuario_teste CASCADE;