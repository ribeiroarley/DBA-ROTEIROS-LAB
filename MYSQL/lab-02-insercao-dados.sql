/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-02-insercao-dados.sql
  Objetivo     : Pratica de manipulacao de dados de forma anonimizada
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

USE teste;

-- 1. Insercao de usuarios (Dados Anonimizados)
INSERT INTO usuario_teste (nome, email) VALUES 
('usuarioteste_01', 'teste01@teste.com'),
('usuarioteste_02', 'teste02@teste.com'),
('usuarioteste_03', 'teste03@teste.com');

-- 2. Insercao de pedidos vinculados aos usuarios (Dados Anonimizados)
-- Presumindo que os IDs gerados acima foram 1, 2 e 3
INSERT INTO pedido_teste (usuario_id, valor) VALUES 
(1, 150.50),
(1, 45.00),
(2, 320.00),
(3, 99.90);

-- CLEANUP
-- DROP DATABASE IF EXISTS teste;
