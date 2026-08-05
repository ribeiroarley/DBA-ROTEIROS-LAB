/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-24-instalacao-mysql-enterprise.md
  Objetivo     : Instalação do MySQL Enterprise, ingresso em domínio e troubleshooting
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Microsoft Windows Server Docs
*******************************************************************************/

# Laboratório 24: Instalação e Configuração do MySQL Enterprise

## 1. Preparação da Máquina Virtual do Banco de Dados

### 1.1 Criação da VM
1. No VirtualBox, crie uma nova máquina virtual nomeada `SRV-DB01`.
2. Especifique hardware adequado para um servidor de banco de dados (ex: 8096 MB de RAM e 2 vCPUs).
3. Adicione discos virtuais adicionais (além do disco de SO): um para os arquivos de dados (Data) e outro para logs (Redo/Undo), a fim de aplicar boas práticas de I/O.
4. Instale o Windows Server conforme o procedimento padrão (Laboratório 22).

### 1.2 Ingresso no Domínio (`teste.local`)
Após a instalação do SO, o servidor de banco de dados precisa integrar a infraestrutura centralizada.
1. Configure o IP estático do `SRV-DB01` e defina o IP do Domain Controller (`SRV-DC01`) como servidor DNS principal.
2. Acesse as configurações de sistema avançadas (`sysdm.cpl`).
3. Na aba "Computer Name" (Nome do Computador), clique em "Change" (Alterar).
4. Marque a opção "Domain" (Domínio) e insira `teste.local`.
5. Forneça credenciais de administrador do domínio para autorizar a operação.
6. Reinicie o servidor para aplicar o ingresso no domínio.

## 2. Instalação do MySQL Enterprise

1. Com o servidor já pertencente ao domínio `teste.local`, faça o logon utilizando a conta de serviço `TESTE\usuarioteste` ou conceda a ela direitos administrativos locais caso necessite executar o instalador, ou instale como administrador do domínio e configure o serviço posteriormente.
2. Execute o instalador do MySQL Enterprise.
3. Escolha o tipo de configuração "Server Only" ou "Custom".
4. Defina os caminhos de instalação e Data Directory (apontando para os discos adicionais preparados no script PowerShell de automação).
5. Durante a configuração do tipo de conta, configure o serviço Windows do MySQL (`MySQL80`) para ser executado sob a conta de serviço do domínio (`teste.local\usuarioteste`). A senha deverá ser informada.
6. Prossiga com a instalação padrão e defina uma senha forte para o usuário `root` do MySQL.

## 3. Troubleshooting: Falha de Inicialização do Serviço e `my.ini`

É um cenário comum que, ao editar o arquivo de configuração `my.ini`, o serviço do MySQL falhe ao iniciar (Error 1067: The process terminated unexpectedly).

### 3.1 Sintomas e Causas Comuns
- O serviço consta como "Parado" no `services.msc`.
- Edição do arquivo `my.ini` utilizando editores de texto inadequados, que inserem caracteres ocultos (BOM) ou quebram o encode do arquivo.
- Diretórios especificados no `my.ini` não possuem permissões adequadas para a conta `teste.local\usuarioteste`.
- Parâmetros deprecados ou sintaxe inválida no arquivo.

### 3.2 Passos para Resolução
1. **Verificar os Logs de Erro**: O arquivo com extensão `.err` (geralmente localizado no Data Directory) contém a razão exata da falha.
2. **Validar Encode do Arquivo**: O arquivo `my.ini` deve estar preferencialmente em encode ANSI ou UTF-8 sem BOM. Evite usar o Bloco de Notas (Notepad) para edições complexas; prefira ferramentas como Notepad++.
3. **Validar Caminhos**: Certifique-se de que os caminhos definidos em variáveis como `datadir` ou `innodb_data_home_dir` usam barras duplas (`\\`) ou barras normais (`/`) no Windows, ex: `datadir="E:/MySQLData/"`.
4. **Checar Permissões NTFS**: Navegue até as pastas de log e dados definidas no `my.ini`. Clique com o botão direito, acesse a aba Segurança e verifique se a conta `usuarioteste` possui permissão "Full Control" nestes diretórios.
5. **Teste Manual**: Abra o Command Prompt como administrador e tente iniciar o daemon manualmente para observar os erros no console:
   ```cmd
   mysqld --console
   ```

## 4. Configuração do MySQL Workbench (Dark Theme)

Para profissionais que passam longos períodos no Workbench, alterar a interface para um tema escuro reduz a fadiga visual.

### 4.1 Habilitando o Dark Theme
1. Abra o MySQL Workbench.
2. No menu superior, navegue até `Edit > Preferences`.
3. Na janela lateral, selecione a categoria `Fonts & Colors`.
4. Localize a seção referente ao esquema de cores da interface ou do editor de SQL. Dependendo da versão do Workbench, o tema geral pode depender do sistema operacional.
5. Em versões mais recentes do Workbench em sistemas Windows:
   - Para aplicar um Dark Theme efetivo, pode ser necessário alterar o tema global do Windows (Settings > Personalization > Colors > "Choose your color: Dark"). O Workbench herda o tema do sistema.
   - Alternativamente, altere o esquema de cores apenas do Editor SQL em `Edit > Preferences > Fonts & Colors > Color Scheme`, selecionando opções como "High Contrast" ou importando um arquivo de tema XML personalizado.
