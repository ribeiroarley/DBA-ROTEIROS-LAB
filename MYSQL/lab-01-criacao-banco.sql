/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-01-criacao-banco.sql
  Objetivo     : Criacao da estrutura de banco de dados e tabelas InnoDB
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

-- 1. Criacao do banco de dados com charset e collation corretos para MySQL 8.x
DROP DATABASE IF EXISTS teste;
CREATE DATABASE teste CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE teste;

-- 2. Criacao de tabelas com Engine InnoDB
CREATE TABLE usuario_teste (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE pedido_teste (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    data_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pedido_usuario FOREIGN KEY (usuario_id) REFERENCES usuario_teste(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. Insercao de dados (Dados Anonimizados)
INSERT INTO usuario_teste (nome, email) VALUES
('usuarioteste_alpha', 'alpha@teste.com'),
('usuarioteste_beta', 'beta@teste.com'),
('usuarioteste_gamma', 'gamma@teste.com'),
('usuarioteste_delta', 'delta@teste.com');

INSERT INTO pedido_teste (usuario_id, valor) VALUES
(1, 1500.50),
(1, 200.00),
(2, 340.90),
(3, 100.00),
(4, 550.00);

-- CLEANUP
-- DROP DATABASE IF EXISTS teste;
