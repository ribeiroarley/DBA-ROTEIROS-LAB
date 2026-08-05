/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-04-views.sql
  Objetivo     : Criacao e gerenciamento de visualizacoes (Views)
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

USE teste;

-- 1. Criacao de View
CREATE OR REPLACE VIEW vw_resumo_pedidos AS
SELECT u.nome, SUM(p.valor) as total_gasto, COUNT(p.id) as total_pedidos
FROM usuario_teste u
LEFT JOIN pedido_teste p ON u.id = p.usuario_id
GROUP BY u.nome;

-- 2. Consulta na View
SELECT * FROM vw_resumo_pedidos;

-- CLEANUP
DROP VIEW IF EXISTS vw_resumo_pedidos;
-- DROP DATABASE IF EXISTS teste;
