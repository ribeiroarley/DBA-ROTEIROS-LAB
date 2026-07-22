/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-23-mecanismos-de-log-e-auditoria-mysql8.sql
  Objetivo     : Roteiro prático para configuração e gerenciamento de logs do
                 servidor MySQL 8.x (General Log, Slow Query Log), inspeção de
                 schemas internos (`mysql`, `sys`), parâmetros estáticos/dinâmicos,
                 e implementação de Auditoria DML customizada com Triggers e JSON.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Server Logs & Audit Logging Triggers
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: INSPEÇÃO DOS SCHEMAS INTERNOS E VERIFICAÇÃO DE STATUS DOS LOGS
--------------------------------------------------------------------------------

-- Seleção do schema de testes do aluno
USE arley_cliente2;

-- Verificar parâmetros do General Query Log e Slow Query Log
SHOW VARIABLES LIKE 'general_log%';
SHOW VARIABLES LIKE 'slow_query_log%';
SHOW VARIABLES LIKE 'log_output%';

-- Consultar tabelas nativas de logs no schema de sistema 'mysql'
SELECT * FROM mysql.general_log LIMIT 10;
SELECT * FROM mysql.slow_log LIMIT 10;


--------------------------------------------------------------------------------
-- PARTE 2: CONFIGURAÇÃO DINÂMICA DO GENERAL LOG (TABLE E FILE)
--------------------------------------------------------------------------------

-- Habilitar captura do General Log direcionando para tabela nativa
SET GLOBAL general_log = 1;
SET GLOBAL log_output = 'TABLE';

-- Executar consulta de teste para registrar na auditoria geral
SELECT * FROM `order` LIMIT 5;

-- Consultar General Log convertendo a coluna BLOB/BINARY 'argument' para texto UTF-8
SELECT 
    event_time, 
    user_host, 
    thread_id, 
    command_type, 
    CONVERT(argument USING utf8mb4) AS argument_sql 
FROM mysql.general_log 
ORDER BY event_time DESC 
LIMIT 10;

-- Redirecionar saída para Tabela e Arquivo no disco
SET GLOBAL log_output = 'FILE,TABLE';
SET GLOBAL general_log_file = 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Data\\mysqld-general-query.log';

-- Desabilitar a captura do General Log
SET GLOBAL general_log = 0;

-- Limpar registros da tabela de log geral
TRUNCATE TABLE mysql.general_log;


--------------------------------------------------------------------------------
-- PARTE 3: CONFIGURAÇÃO DO SLOW QUERY LOG E TESTES DE PERFORMANCE
--------------------------------------------------------------------------------

-- Ativar o Slow Query Log definindo o limite de tempo em segundos (0.5s)
SET GLOBAL slow_query_log = 1;
SET GLOBAL long_query_time = 0.5;
SET GLOBAL log_output = 'TABLE';

-- Executar rotina com atraso forçado (SLEEP) para disparar a captura
SELECT * FROM product WHERE id = 1;
SELECT SLEEP(2) AS execucao_lenta;

-- Consultar Slow Query Log convertendo o texto SQL
SELECT 
    start_time, 
    user_host, 
    query_time, 
    lock_time, 
    rows_sent, 
    rows_examined, 
    CONVERT(sql_text USING utf8mb4) AS sql_query 
FROM mysql.slow_log 
ORDER BY start_time DESC;

-- Configurar Slow Query Log para arquivo físico
SET GLOBAL log_output = 'FILE';
SET GLOBAL slow_query_log_file = 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Data\\mysqld-slow-query.log';

-- Desabilitar captura do Slow Query Log e limpar tabela
SET GLOBAL slow_query_log = 0;
TRUNCATE TABLE mysql.slow_log;


--------------------------------------------------------------------------------
-- PARTE 4: CONFIGURAÇÃO DE LOGS PERMANENTES NO ARQUIVO MY.INI (REFERÊNCIA)
--------------------------------------------------------------------------------

/*
-- Adicionar/Alterar os parâmetros abaixo no bloco [mysqld] do arquivo my.ini:

[mysqld]
log-output = FILE
general_log = 0
general_log_file = "mysqld-general-query.log"
slow_query_log = 1
slow_query_log_file = "mysqld-slow-query.log"
long_query_time = 2.0
*/


--------------------------------------------------------------------------------
-- PARTE 5: AUDITORIA DML AVANÇADA VIA TRIGGERS E DADOS EM FORMATO JSON
--------------------------------------------------------------------------------

-- Criar estrutura de tabela auditada e tabela de log
DROP TABLE IF EXISTS book_audit_log;
DROP TABLE IF EXISTS book;

CREATE TABLE book (
    id BIGINT NOT NULL,
    author VARCHAR(255),
    price_in_cents INT,
    publisher VARCHAR(255),
    title VARCHAR(255),
    CONSTRAINT pk_book PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE book_audit_log (
    book_id BIGINT NOT NULL,
    old_row_data JSON,
    new_row_data JSON,
    dml_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    dml_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dml_created_by VARCHAR(255) NOT NULL,
    CONSTRAINT pk_book_audit_log PRIMARY KEY (book_id, dml_type, dml_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Trigger para INSERT
DELIMITER $$

CREATE TRIGGER trg_book_insert_audit
AFTER INSERT ON book 
FOR EACH ROW
BEGIN
    INSERT INTO book_audit_log (
        book_id,
        old_row_data,
        new_row_data,
        dml_type,
        dml_timestamp,
        dml_created_by
    )
    VALUES (
        NEW.id,
        NULL,
        JSON_OBJECT(
            'title', NEW.title,
            'author', NEW.author,
            'price_in_cents', NEW.price_in_cents,
            'publisher', NEW.publisher
        ),
        'INSERT',
        CURRENT_TIMESTAMP,
        USER()
    );
END$$

-- Trigger para UPDATE
CREATE TRIGGER trg_book_update_audit
AFTER UPDATE ON book 
FOR EACH ROW
BEGIN
    INSERT INTO book_audit_log (
        book_id,
        old_row_data,
        new_row_data,
        dml_type,
        dml_timestamp,
        dml_created_by
    )
    VALUES (
        NEW.id,
        JSON_OBJECT(
            'title', OLD.title,
            'author', OLD.author,
            'price_in_cents', OLD.price_in_cents,
            'publisher', OLD.publisher
        ),
        JSON_OBJECT(
            'title', NEW.title,
            'author', NEW.author,
            'price_in_cents', NEW.price_in_cents,
            'publisher', NEW.publisher
        ),
        'UPDATE',
        CURRENT_TIMESTAMP,
        USER()
    );
END$$

-- Trigger para DELETE
CREATE TRIGGER trg_book_delete_audit
AFTER DELETE ON book 
FOR EACH ROW
BEGIN
    INSERT INTO book_audit_log (
        book_id,
        old_row_data,
        new_row_data,
        dml_type,
        dml_timestamp,
        dml_created_by
    )
    VALUES (
        OLD.id,
        JSON_OBJECT(
            'title', OLD.title,
            'author', OLD.author,
            'price_in_cents', OLD.price_in_cents,
            'publisher', OLD.publisher
        ),
        NULL,
        'DELETE',
        CURRENT_TIMESTAMP,
        USER()
    );
END$$

DELIMITER ;

-- Testar fluxo de DML para disparar as Triggers
INSERT INTO book (id, author, price_in_cents, publisher, title)
VALUES (1, 'Vlad Mihalcea', 3990, 'Amazon', 'High-Performance Java Persistence');

UPDATE book SET price_in_cents = 4499 WHERE id = 1;

DELETE FROM book WHERE id = 1;

-- Consultar o log de auditoria gerado
SELECT * FROM book_audit_log;

-- Extrair e projetar campos do JSON utilizando JSON_TABLE (Recurso moderno MySQL 8.0+)
SELECT
    l.dml_timestamp AS versao_timestamp,
    l.book_id,
    l.dml_type,
    l.dml_created_by,
    r.title,
    r.author,
    r.price_in_cents,
    r.publisher
FROM book_audit_log l
LEFT JOIN JSON_TABLE(
    COALESCE(l.new_row_data, l.old_row_data),
    '$' COLUMNS (
        title VARCHAR(255) PATH '$.title',
        author VARCHAR(255) PATH '$.author',
        price_in_cents INT PATH '$.price_in_cents',
        publisher VARCHAR(255) PATH '$.publisher'
    )
) AS r ON TRUE
ORDER BY l.dml_timestamp ASC;


--------------------------------------------------------------------------------
-- PARTE 6: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

-- Desabilitar logs globais de teste
SET GLOBAL general_log = 0;
SET GLOBAL slow_query_log = 0;

-- Limpar tabelas nativas de logs
TRUNCATE TABLE mysql.general_log;
TRUNCATE TABLE mysql.slow_log;

-- Apagar objetos criados durante o laboratório
DROP TRIGGER IF EXISTS trg_book_insert_audit;
DROP TRIGGER IF EXISTS trg_book_update_audit;
DROP TRIGGER IF EXISTS trg_book_delete_audit;
DROP TABLE IF EXISTS book_audit_log;
DROP TABLE IF EXISTS book;