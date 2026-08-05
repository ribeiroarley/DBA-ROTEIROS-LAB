/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-27-mysql-enterprise-backup-instalacao.md
  Objetivo     : Conceitos e instalacao do MySQL Enterprise Backup
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Enterprise Backup
*******************************************************************************/

# MySQL Enterprise Backup

O MySQL Enterprise Backup fornece backup e recuperação de nível empresarial para MySQL. Ele oferece backups dinâmicos, on-line e sem bloqueio em várias plataformas, incluindo Linux, Windows, Mac e Solaris.

## Principais Recursos:

- **Backups on-line "quentes"**: Os backups ocorrem totalmente on-line, sem interromper as transações.
- **Desempenho**: Processo de backup até 49x mais rápido e restore 80x mais rápido quando comparado com utilitários lógicos como mysqldump.
- **Backup Incremental**: Backup apenas dos dados que foram alterados desde o último backup.
- **Backup Parcial**: Segmente tabelas ou espaços de tabela específicos.
- **Backup de Instância Completo**: Faz backup de dados, configurações e outras informações para criar uma "réplica" completa.
- **Point-in-Time Recovery (PITR)**: Recupere para uma transação específica.
- **Criptografia AES 256**: Proteção de todos os dados de backup confidenciais.
- **Validação de backup**: Fornece verificações para confirmar a integridade e a qualidade do backup.

## Instalação no Windows

1. Utilize o MySQL Installer - Comercial.
2. Na aba de produtos, selecione "Add" e procure por **MySQL Enterprise Backup** para instalação.
3. Caso necessário, o download standalone pode ser feito via Oracle eDelivery, instalando o executável e bibliotecas diretamente no servidor (Ex: `C:\Program Files\MySQL\MySQL Enterprise Backup 8.0\`).

## Configuração no MySQL Workbench

1. Configure os pré-requisitos para o MySQL Enterprise Backup no menu **Server -> MySQL Enterprise Backup** ou pelo menu lateral sob **MYSQL ENTERPRISE**, no item **Online Backup**.

## Conceitos Importantes

### apply-log
Atualiza as tabelas do InnoDB no backup, incluindo alterações feitas nos dados enquanto o backup estava em execução. Essa operação garante a consistência e deve ser feita, preferencialmente, durante o backup ou imediatamente antes do restore.

### Backups Incrementais vs Diferenciais
- O primeiro backup em uma série incremental é sempre um backup diferencial (alterações desde o último full).
- Os subsequentes contém apenas alterações feitas desde o último incremental.

## Tabelas de Controle
O progresso e histórico podem ser acompanhados pelas tabelas de sistema:

```sql
DESCRIBE mysql.backup_progress;
DESCRIBE mysql.backup_history;

SELECT * FROM mysql.backup_progress;
SELECT * FROM mysql.backup_history;
```
