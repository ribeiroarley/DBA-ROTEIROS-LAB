/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-11-backup-senha-criptografada.sql
  Objetivo     : Backup com seguranca usando login-path
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

-- 1. Configuracao do login-path (Execute no DOS)
-- mysql_config_editor set --login-path=backup_user --host=localhost --user=root --password
-- (A senha sera solicitada de forma segura)

-- 2. Backup utilizando login-path criptografado
-- mysqldump --login-path=backup_user teste > C:\backup\bk_seguro_teste.sql

-- CLEANUP
-- mysql_config_editor remove --login-path=backup_user
