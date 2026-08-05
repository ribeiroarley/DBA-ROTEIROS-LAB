/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-25-mysql-enterprise-audit.sql
  Objetivo     : Configuração e gerenciamento do MySQL Enterprise Audit
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Enterprise Audit
*******************************************************************************/

-- -----------------------------------------------------------------------------
-- 1. INTRODUÇÃO E VERIFICAÇÃO INICIAL
-- -----------------------------------------------------------------------------
-- Depois de instalar o plug-in de auditoria, ele grava um arquivo de log (audit.log).
-- Para verificar se o plugin de auditoria já está instalado na instância MySQL:
SELECT PLUGIN_NAME, PLUGIN_STATUS
FROM INFORMATION_SCHEMA.PLUGINS
WHERE PLUGIN_NAME LIKE 'audit%';

-- Para verificar os parâmetros atuais da auditoria:
SHOW VARIABLES LIKE 'audit%';

-- -----------------------------------------------------------------------------
-- 2. INSTALANDO O PLUGIN DE AUDITORIA
-- -----------------------------------------------------------------------------
-- O script de instalação oficial acompanha o MySQL Enterprise.
-- No Windows, execute via prompt de comando (CMD) como administrador:
-- cd "C:\Program Files\MySQL\MySQL Server 8.0\share"
-- mysql -u root -p < audit_log_filter_win_install.sql

-- Após a instalação via linha de comando, confirme o status novamente no Workbench:
SELECT PLUGIN_NAME, PLUGIN_STATUS
FROM INFORMATION_SCHEMA.PLUGINS
WHERE PLUGIN_NAME LIKE 'audit%';

-- -----------------------------------------------------------------------------
-- 3. CONFIGURAÇÃO DE INICIALIZAÇÃO (my.ini)
-- -----------------------------------------------------------------------------
-- Para garantir que a auditoria seja carregada e o formato ajustado,
-- adicione as seguintes linhas na seção [mysqld] do seu arquivo my.ini:
--
-- [mysqld]
-- audit-log=FORCE_PLUS_PERMANENT
-- audit_log_format=JSON
--
-- Após editar o my.ini, reinicie o serviço do MySQL.

-- -----------------------------------------------------------------------------
-- 4. CONFIGURAÇÃO DOS FILTROS DE AUDITORIA
-- -----------------------------------------------------------------------------
-- Por padrão no MySQL 8, nenhum evento é logado até que filtros sejam criados.
-- Os comandos abaixo criam um filtro global que registra tudo e o aplica a todos (%).

-- Cria o filtro 'log_all' para registrar todas as atividades:
SELECT audit_log_filter_set_filter('log_all', '{ "filter": { "log": true } }');

-- Atribui o filtro 'log_all' para todos os usuários (representado por '%'):
SELECT audit_log_filter_set_user('%', 'log_all');

-- -----------------------------------------------------------------------------
-- 5. TESTE DE AUDITORIA
-- -----------------------------------------------------------------------------
-- Execute alguns comandos administrativos básicos para gerar logs no arquivo audit.log.

CREATE SCHEMA IF NOT EXISTS `teste`;
USE `teste`;

CREATE TABLE IF NOT EXISTS `teste`.`tabela_teste` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `descricao` VARCHAR(50) NULL,
  PRIMARY KEY (`id`)
);

-- Executando operações DML para registrar no arquivo de auditoria (audit.log)
INSERT INTO `teste`.`tabela_teste` (`descricao`) VALUES ('Registro de teste 1');
INSERT INTO `teste`.`tabela_teste` (`descricao`) VALUES ('Registro de teste 2');
INSERT INTO `teste`.`tabela_teste` (`descricao`) VALUES ('Registro de teste 3');

UPDATE `teste`.`tabela_teste` SET `descricao` = 'Registro atualizado' WHERE `id` = 1;

DELETE FROM `teste`.`tabela_teste` WHERE `id` = 2;

-- Limpeza do ambiente de teste
DROP TABLE IF EXISTS `teste`.`tabela_teste`;
DROP SCHEMA IF EXISTS `teste`;

-- -----------------------------------------------------------------------------
-- FIM DO LABORATÓRIO
-- -----------------------------------------------------------------------------
