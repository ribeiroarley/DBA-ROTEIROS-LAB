/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-03-consultas.sql
  Objetivo     : Execucao de consultas SQL basicas e agrupamentos
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

USE teste;

-- 1. Consulta simples
SELECT * FROM usuario_teste;

-- 2. Consulta com JOIN
SELECT u.nome, p.valor, p.data_pedido 
FROM usuario_teste u
INNER JOIN pedido_teste p ON u.id = p.usuario_id;

-- 3. Agrupamento
SELECT u.nome, SUM(p.valor) as total_gasto
FROM usuario_teste u
LEFT JOIN pedido_teste p ON u.id = p.usuario_id
GROUP BY u.nome;

-- CLEANUP
-- DROP DATABASE IF EXISTS teste;
