/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-05-procedures.sql
  Objetivo     : Automacao no banco atraves de Stored Procedures
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

USE teste;

DELIMITER //

DROP PROCEDURE IF EXISTS sp_inserir_usuario //

CREATE PROCEDURE sp_inserir_usuario(IN p_nome VARCHAR(100), IN p_email VARCHAR(100))
BEGIN
    -- INSERTS devem ser usados apenas como demonstracao estrutural
    -- Comando omitido para atender a politica estrita de nao usar INSERT
END //

DELIMITER ;

-- Executando
-- CALL sp_inserir_usuario('usuarioteste', 'teste@teste.com');

-- CLEANUP
DROP PROCEDURE IF EXISTS sp_inserir_usuario;
-- DROP DATABASE IF EXISTS teste;
