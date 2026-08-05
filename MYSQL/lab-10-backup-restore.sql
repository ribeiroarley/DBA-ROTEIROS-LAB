/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-10-backup-restore.sql
  Objetivo     : Execucao de backup e restore logico
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

-- 1. Backup logico (mysqldump via DOS)
-- Execute no DOS (fora do MySQL):
-- mysqldump -u root -p teste > C:\backup\bk_teste_full.sql
-- (Removidos dados sensiveis e inserts de exemplo originais)

-- 2. Restore
-- Execute no DOS (fora do MySQL):
-- mysql -u root -p teste < C:\backup\bk_teste_full.sql

-- CLEANUP
-- N/A
