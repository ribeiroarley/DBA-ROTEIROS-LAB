/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-22-infra-virtualbox-dc.md
  Objetivo     : Configuração inicial de VM e promoção a Domain Controller (AD)
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Microsoft Windows Server Docs
*******************************************************************************/

# Laboratório 22: Infraestrutura com VirtualBox e Domain Controller

## 1. Introdução

Este laboratório aborda a preparação da infraestrutura base para o ambiente de banco de dados, estabelecendo um controlador de domínio (Domain Controller - DC) utilizando o Microsoft Windows Server no VirtualBox. O Active Directory (AD) é fundamental para centralizar o gerenciamento de identidade e controle de acesso, requisitos comuns em ambientes corporativos que hospedam sistemas de gerenciamento de banco de dados relacionais (RDBMS) como o MySQL Enterprise.

Um Domínio, no contexto do Active Directory, é um agrupamento lógico de computadores, usuários e outros recursos de rede que compartilham um banco de dados de diretório centralizado. O Domain Controller é o servidor que executa os serviços de domínio do Active Directory (AD DS), autenticando usuários e aplicando políticas de segurança.

## 2. Preparação do Ambiente e Download

1. Faça o download da versão mais recente do Oracle VM VirtualBox.
2. Faça o download da imagem ISO de avaliação do Windows Server (recomenda-se a versão mais recente suportada em seu ambiente, ex: 2019 ou 2022) no Microsoft Evaluation Center.

## 3. Criação da Máquina Virtual (DC) no VirtualBox

1. Abra o VirtualBox e selecione a opção para criar uma nova máquina virtual.
2. Defina o nome como `SRV-DC01` e selecione o tipo "Microsoft Windows" e a versão correspondente ao Windows Server.
3. Aloque memória RAM (recomenda-se no mínimo 4096 MB para o DC).
4. Crie um disco rígido virtual do tipo VDI, dinamicamente alocado, com no mínimo 50 GB.
5. Nas configurações da VM, na seção "Rede", configure o Adaptador 1 como "Rede Interna" (para comunicação isolada com o servidor de banco de dados) ou "Placa em Modo Bridge" (se necessitar acesso à rede externa).
6. Na seção "Armazenamento", monte a imagem ISO do Windows Server no drive óptico virtual.

## 4. Instalação do Sistema Operacional

1. Inicie a máquina virtual.
2. Siga o assistente de instalação do Windows Server.
3. Selecione a edição "Desktop Experience" (Experiência Desktop) para possuir interface gráfica, a menos que opte pelo modo Server Core (requer administração via PowerShell).
4. Escolha a instalação personalizada (Custom: Install Windows only).
5. Selecione o disco virtual criado anteriormente e prossiga com a instalação.
6. Ao finalizar, defina uma senha forte para a conta de Administrador local.

## 5. Promoção a Domain Controller

Antes de promover o servidor, é mandatório configurar um IP estático. A configuração do IP será abordada com mais detalhes nas automações, mas para o DC, certifique-se de que ele aponta para si mesmo como servidor DNS (ou para a interface loopback `127.0.0.1`).

1. Abra o "Server Manager" (Gerenciador do Servidor).
2. Clique em "Manage" (Gerenciar) e em seguida em "Add Roles and Features" (Adicionar Funções e Recursos).
3. Prossiga pelo assistente selecionando "Role-based or feature-based installation".
4. Na seleção de funções do servidor (Server Roles), marque a caixa "Active Directory Domain Services". Adicione os recursos requeridos (Add Features).
5. Avance as telas e clique em "Install" (Instalar).
6. Após a conclusão da instalação, clique no link "Promote this server to a domain controller" (Promover este servidor a um controlador de domínio) na mesma tela ou na notificação (bandeira amarela) do Server Manager.
7. Selecione "Add a new forest" (Adicionar uma nova floresta).
8. No campo "Root domain name", insira `teste.local`.
9. Defina a senha do DSRM (Directory Services Restore Mode).
10. Prossiga pelas opções de DNS (pode ignorar o aviso de delegação DNS).
11. Aceite os caminhos padrão para banco de dados, logs e SYSVOL.
12. Revise as opções e aguarde a verificação de pré-requisitos.
13. Clique em "Install" (Instalar). O servidor será reiniciado automaticamente ao término do processo, já operando como Controlador de Domínio para `teste.local`.
