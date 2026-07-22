/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-14-agendamento-de-eventos-e-automacao-mysql8.sql
  Objetivo     : Roteiro prático para habilitação do Event Scheduler, criação de
                 Eventos pontuais (AT), recorrentes (EVERY), controle de janela de 
                 execução (STARTS/ENDS), alteração (ALTER EVENT), habilitação/
                 desabilitação e automação de tarefas administrativas no MySQL 8.x.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Using the Event Scheduler & CREATE EVENT
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: VERIFICAÇÃO E ATIVAÇÃO DO EVENT SCHEDULER
--------------------------------------------------------------------------------

USE arley_cliente2;

-- Verificar o status atual da variável do agendador de eventos no MySQL
SHOW VARIABLES LIKE 'event_scheduler';

-- Habilitar globalmente o agendador de eventos (Exige privilégio SYSTEM_VARIABLES_ADMIN ou SUPER)
SET GLOBAL event_scheduler = ON;

-- Confirmar a ativação do serviço
SHOW VARIABLES LIKE 'event_scheduler';


--------------------------------------------------------------------------------
-- PARTE 2: EVENTOS PONTUAIS DE EXECUÇÃO IMEDIATA E AGENDADA (AT)
--------------------------------------------------------------------------------

-- 1. Criar evento pontual para execução imediata (CURRENT_TIMESTAMP)
DELIMITER $$

CREATE EVENT IF NOT EXISTS ev_carga_imediata
    ON SCHEDULE AT CURRENT_TIMESTAMP
    DO
    BEGIN
        INSERT INTO customer (id, firstname, lastname, city, country, phone)
        VALUES (270, 'Arley', 'Ribeiro Immediato', 'Belo Horizonte', 'Brazil', '+55 31 99999-0001');
    END$$

DELIMITER ;

-- Inspecionar eventos agendados ou concluídos no schema
SHOW EVENTS FROM arley_cliente2;

-- Confirmar a inserção efetuada pelo evento
SELECT * FROM customer WHERE id = 270;

-- 2. Criar evento pontual com intervalo relativo (NOW() + 1 MINUTE)
DELIMITER $$

CREATE EVENT IF NOT EXISTS ev_carga_postergada_1min
    ON SCHEDULE AT NOW() + INTERVAL 1 MINUTE
    DO
    BEGIN
        INSERT INTO customer (id, firstname, lastname, city, country, phone)
        VALUES (280, 'Arley', 'Ribeiro 1Minuto', 'Belo Horizonte', 'Brazil', '+55 31 99999-0002');
    END$$

DELIMITER ;

-- Inspecionar o evento em fila de execução
SHOW EVENTS FROM arley_cliente2;

-- 3. Criar evento pontual transacional em data/hora fixa
DELIMITER $$

CREATE EVENT IF NOT EXISTS ev_manutencao_transacional
    ON SCHEDULE AT '2026-12-31 23:59:00'
    DO
    BEGIN
        START TRANSACTION;
            INSERT INTO customer (id, firstname, lastname, city, country, phone)
            VALUES (290, 'Arley', 'Ribeiro Agendado', 'Belo Horizonte', 'Brazil', '+55 31 99999-0003');
            
            DELETE FROM customer WHERE id = 3;
        COMMIT;
    END$$

DELIMITER ;

SHOW EVENTS FROM arley_cliente2;


--------------------------------------------------------------------------------
-- PARTE 3: EVENTO PARA CRIAÇÃO DE ESTRUTURA DDL (CREATE TABLE)
--------------------------------------------------------------------------------

DELIMITER $$

CREATE EVENT IF NOT EXISTS ev_criar_tabela_exemplo
    ON SCHEDULE AT CURRENT_TIMESTAMP
    DO
    BEGIN
        CREATE TABLE IF NOT EXISTS tabela_exemplo_evento (
            id INT NOT NULL,
            companyname VARCHAR(40) NULL,
            contactname VARCHAR(50) NULL,
            contacttitle VARCHAR(40) NULL,
            city VARCHAR(40) NULL,
            country VARCHAR(40) NULL,
            phone VARCHAR(30) NULL,
            fax VARCHAR(30) NULL,
            PRIMARY KEY (id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
    END$$

DELIMITER ;

SHOW EVENTS FROM arley_cliente2;


--------------------------------------------------------------------------------
-- PARTE 4: EVENTOS RECORRENTES COM JANELA DE INÍCIO E FIM (EVERY)
--------------------------------------------------------------------------------

-- 1. Criar evento recorrente mensal com janela pré-definida
DELIMITER $$

CREATE EVENT IF NOT EXISTS ev_manutencao_mensal
    ON SCHEDULE EVERY 1 MONTH
    STARTS '2026-08-01 00:00:00'
    ENDS '2026-12-31 23:59:59'
    DO
    BEGIN
        UPDATE product
        SET isdiscontinued = 0
        WHERE isdiscontinued = 1;
    END$$

DELIMITER ;

-- 2. Criar evento recorrente de hora em hora com duração limitada a 2 horas
DELIMITER $$

CREATE EVENT IF NOT EXISTS ev_job_recorrente_1hora
    ON SCHEDULE EVERY 1 HOUR
    STARTS CURRENT_TIMESTAMP
    ENDS CURRENT_TIMESTAMP + INTERVAL 2 HOUR
    DO
    BEGIN
        UPDATE product
        SET isdiscontinued = 0
        WHERE isdiscontinued = 1;
    END$$

DELIMITER ;

SHOW EVENTS FROM arley_cliente2;


--------------------------------------------------------------------------------
-- PARTE 5: GERENCIAMENTO DE EVENTOS (DISABLE, ENABLE, RENAME, ALTER)
--------------------------------------------------------------------------------

-- Desabilitar um evento ativo sem excluí-lo do banco
ALTER EVENT ev_job_recorrente_1hora DISABLE;

SHOW EVENTS FROM arley_cliente2;

-- Reabilitar o evento
ALTER EVENT ev_job_recorrente_1hora ENABLE;

-- Renomear um evento existente
ALTER EVENT ev_job_recorrente_1hora RENAME TO ev_job_recorrente_1hora_novo;

SHOW EVENTS FROM arley_cliente2;

-- Alterar a agenda e o corpo de instrução de um evento existente
ALTER EVENT ev_job_recorrente_1hora_novo
    ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 DAY
    DO
        UPDATE product SET isdiscontinued = 0 WHERE id = 1;

SHOW EVENTS FROM arley_cliente2;


--------------------------------------------------------------------------------
-- PARTE 6: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

-- Remover os eventos criados durante o laboratório
DROP EVENT IF EXISTS ev_carga_imediata;
DROP EVENT IF EXISTS ev_carga_postergada_1min;
DROP EVENT IF EXISTS ev_manutencao_transacional;
DROP EVENT IF EXISTS ev_criar_tabela_exemplo;
DROP EVENT IF EXISTS ev_manutencao_mensal;
DROP EVENT IF EXISTS ev_job_recorrente_1hora;
DROP EVENT IF EXISTS ev_job_recorrente_1hora_novo;

-- Remover registros e tabelas criadas pelos eventos
DELETE FROM customer WHERE id IN (270, 280, 290);
DROP TABLE IF EXISTS tabela_exemplo_evento;

-- Inspecionar confirmação de limpeza dos eventos
SHOW EVENTS FROM arley_cliente2;