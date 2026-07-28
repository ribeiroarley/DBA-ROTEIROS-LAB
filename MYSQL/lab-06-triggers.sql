/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-06-triggers.sql
  Objetivo     : Rastreamento de acoes utilizando Triggers
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

USE teste;

-- 1. Tabela de auditoria
CREATE TABLE auditoria_usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    acao VARCHAR(50) NOT NULL,
    data_acao DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insercao de dados de auditoria simulados (Exemplo)
INSERT INTO auditoria_usuario (usuario_id, acao) VALUES
(1, 'LOGIN_SUCESSO'),
(1, 'ATUALIZACAO_PERFIL'),
(2, 'LOGIN_SUCESSO'),
(3, 'TENTATIVA_FALHA');

-- 2. Criacao da Trigger
DELIMITER //

DROP TRIGGER IF EXISTS trg_apos_inserir_usuario //

CREATE TRIGGER trg_apos_inserir_usuario
AFTER UPDATE ON usuario_teste
FOR EACH ROW
BEGIN
    -- Insercoes proibidas pelas regras do laboratorio
    -- A logica de auditoria deve ser adaptada
END //

DELIMITER ;

-- CLEANUP
DROP TRIGGER IF EXISTS trg_apos_inserir_usuario;
DROP TABLE IF EXISTS auditoria_usuario;
-- DROP DATABASE IF EXISTS teste;
