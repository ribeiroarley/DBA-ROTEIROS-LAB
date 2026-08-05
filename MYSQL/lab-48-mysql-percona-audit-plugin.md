/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-48-mysql-percona-audit-plugin.md
  Objetivo     : Instalação, configuração e testes do Percona Audit Plugin no MySQL
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Percona Server / MySQL Security and Auditing
*******************************************************************************/

# Laboratório 48: MySQL Percona Audit Plugin

O Percona Audit Log Plugin fornece monitoramento e registro de atividades de conexão, operações de mudança de dados, estruturas de bancos e consultas realizadas em um servidor MySQL. Esta é uma implementação alternativa ao MySQL Enterprise Audit Log.

---

## 1. Download e Transferência do Plugin

Para maior segurança, recomenda-se baixar o plugin em um ambiente controlado e transferi-lo para o servidor Linux via cliente SFTP (como WinSCP).

1. Acesse a página oficial de downloads da Percona.
2. Selecione o **Percona Server for MySQL** correspondente à versão exata do seu Oracle MySQL instalado e a distribuição Linux correta.
3. Baixe o pacote correspondente (`.deb` ou `.rpm`).
4. Conecte-se ao servidor (ex: `192.168.x.x`) via WinSCP e transfira o pacote baixado para o diretório `/home/usuarioteste/`.

---

## 2. Preparação e Instalação no Sistema Operacional

Acesse o servidor Linux e realize a extração do plugin e o posicionamento no diretório correto.

```bash
# Acessar o diretório de destino da transferência
cd /home/usuarioteste/

# Criar um diretório de trabalho temporário
mkdir perconamysqlsetup

# Extrair os arquivos do pacote baixado (substitua pelo nome exato do arquivo)
dpkg-deb -x percona-server-server_8.0.x.deb perconamysqlsetup/

# Navegar até o diretório do plugin extraído
cd perconamysqlsetup/usr/lib/mysql/plugin/

# Copiar o plugin para o diretório de plugins do MySQL
sudo cp audit_log.so /usr/lib/mysql/plugin/

# Criar o diretório exclusivo para armazenamento dos arquivos de log de auditoria
sudo mkdir -p /var/lib/mysql/auditmysqlpercona

# Alterar a propriedade do diretório para o usuário de serviço do MySQL
sudo chown -R mysql:mysql /var/lib/mysql/auditmysqlpercona/

# Remover os arquivos temporários e pacotes de instalação
cd /home/usuarioteste/
rm -rf perconamysqlsetup/
rm -f percona-server-server_*.deb
```

---

## 3. Configuração do Arquivo my.cnf

Efetue os ajustes no arquivo de configuração do MySQL para inicialização automática e definição de políticas de auditoria.

```bash
sudo nano /etc/my.cnf
```

Adicione o seguinte conteúdo dentro do bloco `[mysqld]`:

```ini
[mysqld]
# Carregamento do Plugin de Auditoria
plugin-load=audit_log.so

# Configuração de Destino e Formato do Log
audit_log_file = /var/lib/mysql/auditmysqlpercona/audit.log
audit_log_handler = FILE
audit_log_format = CSV

# Política de Auditoria Geral
audit_log_policy = QUERIES

# Filtros de Comandos Auditados
audit_log_include_commands = 'delete, update, create, drop, truncate, alter_table, create_table, drop_table, create_db, drop_db, create_user, alter_user, drop_user'

# Filtros de Exclusão (Contas e Bancos ignorados pela auditoria)
audit_log_exclude_accounts = 'usuario_teste@localhost'
audit_log_exclude_databases = 'mysql'

# Políticas de Rotação de Log
# Geração de novo arquivo ao atingir 1GB (1000000000 bytes)
audit_log_rotate_on_size = 1000000000
# Retenção de 5 arquivos antigos após rotação
audit_log_rotations = 5
```

Reinicie o serviço MySQL para aplicar as novas configurações:

```bash
sudo systemctl restart mysql
```

---

## 4. Instalação e Validação via SQL

Com o serviço reiniciado, instale o plugin internamente no MySQL e realize as validações.

```bash
mysql -u root -p
```

```sql
-- Validar o diretório padrão de plugins
SHOW GLOBAL VARIABLES LIKE 'plugin_dir';

-- Instalar o plugin de auditoria
INSTALL PLUGIN audit_log SONAME 'audit_log.so';

-- Confirmar se o plugin encontra-se com status ACTIVE
SHOW PLUGINS;

-- Realizar operações estruturais para gerar registros de auditoria
CREATE DATABASE db_teste;
USE db_teste;
CREATE TABLE tb_teste (id INT);

-- Validar com uma consulta DQL
SELECT * FROM tb_teste;

-- Limpar o ambiente
DROP TABLE tb_teste;
DROP DATABASE db_teste;

EXIT;
```

---

## 5. Verificação dos Arquivos de Auditoria

Retorne ao terminal do sistema operacional e valide a existência e o conteúdo do arquivo de log formatado em CSV.

```bash
# Validar a criação do arquivo de log
ls -l /var/lib/mysql/auditmysqlpercona/

# Inspecionar o conteúdo gravado pela auditoria
cat /var/lib/mysql/auditmysqlpercona/audit.log
```
