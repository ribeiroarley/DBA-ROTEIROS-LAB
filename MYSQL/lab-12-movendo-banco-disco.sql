/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-12-movendo-banco-disco.sql
  Objetivo     : Procedimento para alteracao do datadir
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

-- 1. Alterar variavel datadir no my.ini ou my.cnf
-- # Path to the database root
-- datadir=D:/NOVO_DIRETORIO/Data

-- 2. Parar o servico do MySQL
-- 3. Mover/Copiar a pasta Data para o novo local
-- 4. Renomear a pasta antiga (ex: Data_old) para backup
-- 5. Iniciar o servico do MySQL

-- CLEANUP
-- N/A
