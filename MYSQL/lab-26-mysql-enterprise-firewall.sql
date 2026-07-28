/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-26-mysql-enterprise-firewall.sql
  Objetivo     : Configuração, learning mode e protect mode do Enterprise Firewall
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Enterprise Firewall
*******************************************************************************/

-- 1. INSTALACAO DO PLUGIN FIREWALL
-- Via command line (no diretorio share):
-- mysql -u root -p < win_install_firewall.sql

-- Verificando a instalacao
SHOW GLOBAL VARIABLES LIKE 'mysql_firewall_mode';

-- 2. PRIVILEGIOS DE FIREWALL (ROOT)
SHOW GRANTS FOR CURRENT_USER();
GRANT FIREWALL_ADMIN ON *.* TO 'root'@'localhost';
GRANT FIREWALL_EXEMPT ON *.* TO 'root'@'localhost';
SHOW GRANTS FOR CURRENT_USER();

-- 3. CONFIGURACAO (ATIVACAO)
-- Em runtime:
SET PERSIST mysql_firewall_mode = ON;

-- 4. CRIACAO DE USUARIOS PARA O LABORATORIO (ANONIMIZADOS) E PERMISSOES
CREATE USER IF NOT EXISTS 'usuarioteste'@'localhost' IDENTIFIED BY 'teste';
GRANT ALL ON teste.* TO 'usuarioteste'@'localhost';

CREATE USER IF NOT EXISTS 'usuario_teste'@'localhost' IDENTIFIED BY 'teste';
GRANT ALL ON teste.* TO 'usuario_teste'@'localhost';

CREATE USER IF NOT EXISTS 'teste'@'localhost' IDENTIFIED BY 'teste';
GRANT ALL ON teste.* TO 'teste'@'localhost';

-- 5. CONFIGURANDO O MODO DE APRENDIZADO (RECORDING)
-- Registrando o perfil de grupo e ativando o modo de aprendizado
CALL mysql.sp_set_firewall_group_mode('fwgrp', 'RECORDING');

-- Adicionando os usuarios ao grupo
CALL mysql.sp_firewall_group_enlist('fwgrp', 'usuarioteste@localhost');
CALL mysql.sp_firewall_group_enlist('fwgrp', 'usuario_teste@localhost');
CALL mysql.sp_firewall_group_enlist('fwgrp', 'teste@localhost');

-- Simulando operacoes de leitura para o aprendizado do firewall (na sessao do usuario)
SELECT * FROM teste.customer;
SELECT * FROM teste.order WHERE customerid = 78;
SELECT count(*) FROM teste.order;

-- 6. VERIFICANDO AS INFORMACOES NO PERFORMANCE SCHEMA
SELECT MODE FROM performance_schema.firewall_groups WHERE NAME = 'fwgrp';

SELECT * FROM performance_schema.firewall_membership
WHERE GROUP_ID = 'fwgrp' ORDER BY MEMBER_ID;

-- 7. ATIVANDO O MODO DE PROTECAO (PROTECTING)
CALL mysql.sp_set_firewall_group_mode('fwgrp', 'PROTECTING');

-- Verificando alteracao
SELECT MODE FROM performance_schema.firewall_groups WHERE NAME = 'fwgrp';

-- 8. TESTANDO BLOQUEIO (As operacoes abaixo nao foram aprendidas e serao bloqueadas pelo Firewall)
-- SELECT * FROM teste.order WHERE customerid = 13 OR 1=1;
-- SELECT count(*) FROM teste.product;

-- 9. CONFIGURANDO RASTREAMENTO (OPCIONAL NO MY.INI)
-- [mysqld]
-- mysql_firewall_trace=ON
-- log_error_verbosity=3

-- 10. REMOVENDO USUARIO DO GRUPO DO FIREWALL
CALL mysql.sp_firewall_group_delist('fwgrp', 'teste@localhost');

SELECT * FROM performance_schema.firewall_membership
WHERE GROUP_ID = 'fwgrp' ORDER BY MEMBER_ID;

-- 11. MODO DETECTING (Apenas alerta, sem bloqueio)
CALL mysql.sp_set_firewall_group_mode('fwgrp', 'DETECTING');

-- 12. DESATIVANDO O FIREWALL OU RESETANDO O GRUPO
CALL mysql.sp_set_firewall_group_mode('fwgrp', 'OFF');
CALL mysql.sp_set_firewall_group_mode('fwgrp', 'RESET');

-- 13. MONITORAMENTO
SHOW GLOBAL STATUS LIKE 'Firewall%';

-- 14. REMOCAO DO PLUGIN FIREWALL
CALL mysql.sp_firewall_group_delist('fwgrp', 'usuarioteste@localhost');
CALL mysql.sp_firewall_group_delist('fwgrp', 'usuario_teste@localhost');

DROP TABLE IF EXISTS mysql.firewall_group_allowlist;
DROP TABLE IF EXISTS mysql.firewall_groups;
DROP TABLE IF EXISTS mysql.firewall_membership;
DROP TABLE IF EXISTS mysql.firewall_users;
DROP TABLE IF EXISTS mysql.firewall_whitelist;

UNINSTALL PLUGIN MYSQL_FIREWALL;
UNINSTALL PLUGIN MYSQL_FIREWALL_USERS;
UNINSTALL PLUGIN MYSQL_FIREWALL_WHITELIST;

DROP FUNCTION IF EXISTS firewall_group_delist;
DROP FUNCTION IF EXISTS firewall_group_enlist;
DROP FUNCTION IF EXISTS mysql_firewall_flush_status;
DROP FUNCTION IF EXISTS normalize_statement;
DROP FUNCTION IF EXISTS read_firewall_group_allowlist;
DROP FUNCTION IF EXISTS read_firewall_groups;
DROP FUNCTION IF EXISTS read_firewall_users;
DROP FUNCTION IF EXISTS read_firewall_whitelist;
DROP FUNCTION IF EXISTS set_firewall_group_mode;
DROP FUNCTION IF EXISTS set_firewall_mode;

DROP PROCEDURE IF EXISTS mysql.sp_firewall_group_delist;
DROP PROCEDURE IF EXISTS mysql.sp_firewall_group_enlist;
DROP PROCEDURE IF EXISTS mysql.sp_reload_firewall_group_rules;
DROP PROCEDURE IF EXISTS mysql.sp_reload_firewall_rules;
DROP PROCEDURE IF EXISTS mysql.sp_set_firewall_group_mode;
DROP PROCEDURE IF EXISTS mysql.sp_set_firewall_group_mode_and_user;
DROP PROCEDURE IF EXISTS mysql.sp_set_firewall_mode;

REVOKE FIREWALL_ADMIN ON *.* FROM 'root'@'localhost';
REVOKE FIREWALL_EXEMPT ON *.* FROM 'root'@'localhost';
