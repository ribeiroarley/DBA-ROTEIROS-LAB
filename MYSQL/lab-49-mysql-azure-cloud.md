/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-49-mysql-azure-cloud.md
  Objetivo     : Implantação IaaS/PaaS e Migração de MySQL para a Microsoft Azure
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Microsoft Azure Docs / MySQL Cloud Deployments
*******************************************************************************/

# Laboratório: Implantação IaaS/PaaS e Migração de MySQL para a Microsoft Azure

## 1. Infraestrutura como Serviço (IaaS)

### 1.1. Criação e Acesso às Máquinas Virtuais
- Provisionar uma VM com Windows Server e uma VM com Linux via Portal do Azure.
- Conectar-se à VM Windows via protocolo RDP.
- Conectar-se à VM Linux via SSH (Putty).

### 1.2. Gerenciamento de Discos
- Adicionar novos discos nas VMs pela console da Azure.
- No Windows: Utilizar a ferramenta Computer Management (Gerenciamento de Disco) para inicializar, formatar e montar os discos.
- No Linux: Verificar os discos não montados e particionar.
  ```bash
  lsblk --noheadings --raw
  sudo fdisk /dev/sdc
  ```

### 1.3. Dimensionamento (Resize)
- Verificar a utilização de CPU e Memória na VM.
- Efetuar o Resize da VM diretamente pelo portal da Azure.
- A VM será reiniciada. Validar a persistência dos dados nos discos virtuais anexados (os discos temporários são limpos em reboots estruturais da cloud).

### 1.4. Instalação do MySQL (Linux)
- Acessar a VM Linux criada na Azure.
- Atualizar cache e instalar o MySQL Server:
  ```bash
  sudo apt update
  sudo apt install mysql-server
  sudo service mysql status
  mysql --version
  ```
- Validar o acesso e aplicar configurações iniciais:
  ```bash
  mysql -u root
  SHOW DATABASES;
  exit;
  ```
- Executar script de segurança padrão:
  ```bash
  sudo mysql_secure_installation
  ```

## 2. Plataforma como Serviço (PaaS)

### 2.1. Implantação do Serviço
- No portal Azure, buscar por "Servidores flexíveis do Banco de Dados do Azure para MySQL".
- Criar a instância PaaS. 
- Endpoint padrão do laboratório: `servidor-mysql-teste.mysql.database.azure.com`

### 2.2. Configuração e Parâmetros
- Acessar a guia de "Parâmetros do servidor" e ajustar os buffers:
  - `innodb_buffer_pool_size`
  - `innodb_io_capacity_max`
- Acessar a aba "Monitoramento e Métricas" e configurar a visão da performance.

### 2.3. Liberação de IP e Conexão SSL
- Acessar a aba "Rede" da instância PaaS.
- Adicionar regra de Firewall para o IP da rede local (ex: `203.0.113.x`).
- Configurar SSL:
  - Mudar a opção "Usar SSL" para "Require" (Exigir).
  - Obter o certificado raiz global da Azure e utilizá-lo no cliente.
- Conectar via MySQL Workbench:
  - Host: `servidor-mysql-teste.mysql.database.azure.com`
  - Usuário: `usuarioteste`

## 3. Migração e Backup

### 3.1. Padronização de Collation
- Validar e atualizar as configurações de Collation locais antes da exportação para garantir compatibilidade com a Cloud, substituindo formatos obsoletos por UTF8MB4.
  ```sql
  ALTER TABLE cliente_teste COLLATE UTF8MB4_GENERAL_CI;
  ALTER TABLE produto_teste COLLATE UTF8MB4_GENERAL_CI;
  ALTER TABLE cliente_teste MODIFY nome_cliente VARCHAR(40) COLLATE UTF8MB4_GENERAL_CI;
  ```

### 3.2. Exportação Local e Importação na Nuvem (Migração)
- Exportar a base local utilizando o utilitário `mysqldump` sem gerar lock em toda a estrutura.
  ```bash
  mysqldump -u usuarioteste -p --single-transaction --routines --triggers base_teste > dump_base_teste.sql
  ```
- Realizar os ajustes no arquivo SQL (se necessário), alterando referências de collations incompatíveis ou antigas.
- Importar o backup na instância PaaS na Azure:
  ```bash
  mysql -h servidor-mysql-teste.mysql.database.azure.com -u usuarioteste -p base_teste < dump_base_teste.sql
  ```

### 3.3. Backup e Restore Nativo (Azure)
- Validar políticas de backup em "Exibir trabalhos" (Backup Center).
- Backups automatizados da Azure ocorrem periodicamente (Full diários, Log a cada 5 min) retidos conforme configuração.
- Para recuperar bancos, utilizar a funcionalidade "Restaurar" que provisiona um novo servidor. Em seguida, migrar os dados para o servidor original ou alterar os ponteiros da aplicação.

## 4. Governança

### 4.1. Controle de Custos
- Acompanhar painel "Gerenciamento de Custos" do Azure para evitar gastos desnecessários.

### 4.2. Exclusão Segura de Recursos
- Desligar as VMs quando não estiverem em uso.
- Remover todo o Grupo de Recursos (Resource Group) ao finalizar o laboratório.
- Caso ocorram falhas na exclusão devido ao "Deleted State", limpar os cofres de backup do Azure Site Recovery manualmente no menu de Itens de Backup antes de remover o grupo.
