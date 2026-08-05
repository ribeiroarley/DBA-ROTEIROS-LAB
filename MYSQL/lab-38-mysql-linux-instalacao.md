/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-38-mysql-linux-instalacao.md
  Objetivo     : Instalação do MySQL no Ubuntu e Troubleshooting de Infraestrutura
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Linux Optimizations
*******************************************************************************/

# Instalação do MySQL Server no Linux Ubuntu e Troubleshooting

Este laboratório abrange os passos de infraestrutura e instalação necessários para configurar o MySQL 8.0 em um ambiente Ubuntu Server.

## 1. Clonagem de VM no VirtualBox e Configuração de Rede

Após clonar a VM, é necessário garantir a conectividade e a resolução de nomes correta.

### Configuração de IP Estático e DNS (Netplan)

Edite o arquivo de configuração de rede para fixar o IP e adicionar um servidor DNS válido.

```bash
cd /etc/netplan
sudo cp 00-installer-config.yaml 00-installer-config.yaml.bak
sudo nano 00-installer-config.yaml
```

Adicione as configurações de IP e DNS:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: no
      dhcp6: no
      addresses:
        - 192.168.1.160/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8]
```

Aplique as configurações de rede:

```bash
sudo netplan try
sudo netplan apply
```

## 2. Troubleshooting de Espaço em Disco

Caso ocorra erro por falta de espaço em `/var/cache/apt/archives/` durante a instalação:

Limpe os caches e remova pacotes obsoletos:
```bash
sudo apt-get autoclean
sudo apt-get autoremove
```

Se o `swapfile` estiver consumindo muito espaço, reduza-o temporariamente:
```bash
sudo swapoff /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1M count=128
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon -s
```

## 3. Instalação do MySQL Server

Atualize os repositórios e instale o pacote:
```bash
sudo apt-get update
sudo apt install mysql-server -y
```

Verifique o status do serviço:
```bash
sudo systemctl status mysql
```

## 4. Configuração de Segurança Inicial

Defina a senha do super usuário root localmente:
```bash
sudo mysql
```

```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'SenhaForte123!';
EXIT;
```

Execute o script de segurança para remover usuários anônimos e bases de teste:
```bash
sudo mysql_secure_installation
```
*(Siga os prompts de configuração para reforçar a segurança e proibir acesso remoto ao root, caso desejado.)*

## 5. Configuração para Acesso Remoto

### Alteração no my.cnf
Edite o arquivo de configuração para escutar em todos os IPs ou no IP da máquina:

```bash
sudo nano /etc/mysql/my.cnf
```

Adicione ou modifique a seção `[mysqld]`:
```ini
[mysqld]
bind-address = 0.0.0.0
port = 3306
```

Reinicie o serviço MySQL:
```bash
sudo systemctl restart mysql
```

### Liberação no Firewall (UFW)
Permita o tráfego na porta 3306 do MySQL:
```bash
sudo ufw allow 3306/tcp
sudo ufw reload
sudo ufw status
```

### Criação do Primeiro Banco de Dados e Usuário

Acesse o MySQL:
```bash
sudo mysql -u root -p
```

Execute os comandos SQL para criar o banco, tabelas, usuários e permissões:

```sql
CREATE DATABASE primeiradb;
USE primeiradb;

CREATE TABLE primeiratabela (
    id INT, 
    nome VARCHAR(50)
);

INSERT INTO primeiratabela (id, nome) VALUES (1, 'usuarioteste');
SELECT * FROM primeiratabela;

-- Criacao de usuario para acesso remoto
CREATE USER IF NOT EXISTS 'usuarioteste'@'%' IDENTIFIED BY 'SenhaForte123!';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON primeiradb.* TO 'usuarioteste'@'%';

FLUSH PRIVILEGES;
EXIT;
```

A partir deste ponto, o ambiente está preparado para conexões remotas através do MySQL Workbench utilizando as credenciais do `usuarioteste`.
