/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-13-checagem-integridade.sql
  Objetivo     : Checagem e manutencao da saude do banco com mysqlcheck
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

-- 1. Checagem via mysqlcheck (Executar no DOS)
-- Checar um banco:
-- mysqlcheck -u root -p teste

-- Checar tabelas especificas:
-- mysqlcheck -u root -p teste usuario_teste pedido_teste

-- Checar todas as bases:
-- mysqlcheck -u root -p --all-databases

-- CLEANUP
-- N/A
