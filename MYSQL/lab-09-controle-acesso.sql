/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-09-controle-acesso.sql
  Objetivo     : Gestao de permissoes e privilegios de acesso
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

-- 1. Conceder privilegios
DROP USER IF EXISTS 'usuario_teste'@'localhost';
CREATE USER 'usuario_teste'@'localhost' IDENTIFIED BY 'SenhaSegura@2024';

GRANT SELECT, INSERT ON teste.* TO 'usuario_teste'@'localhost';
FLUSH PRIVILEGES;

-- 2. Revogar privilegios
REVOKE INSERT ON teste.* FROM 'usuario_teste'@'localhost';
FLUSH PRIVILEGES;

-- 3. Visualizar privilegios
SHOW GRANTS FOR 'usuario_teste'@'localhost';

-- CLEANUP
DROP USER IF EXISTS 'usuario_teste'@'localhost';
-- DROP DATABASE IF EXISTS teste;
