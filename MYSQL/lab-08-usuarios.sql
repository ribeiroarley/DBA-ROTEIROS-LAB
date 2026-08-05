/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-08-usuarios.sql
  Objetivo     : Criacao e gerenciamento de contas de usuario MySQL
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

-- 1. Criacao de usuario
DROP USER IF EXISTS 'usuarioteste'@'localhost';
CREATE USER 'usuarioteste'@'localhost' IDENTIFIED BY 'SenhaForte@123';

-- 2. Alteracao de senha
ALTER USER 'usuarioteste'@'localhost' IDENTIFIED BY 'NovaSenhaForte@123';

-- 3. Renomeacao
RENAME USER 'usuarioteste'@'localhost' TO 'usuario_teste'@'localhost';

-- CLEANUP
DROP USER IF EXISTS 'usuario_teste'@'localhost';
-- DROP DATABASE IF EXISTS teste;
