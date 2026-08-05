/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-36-linux-ubuntu-instalacao.md
  Objetivo     : Roteiro de instalacao e preparacao do Ubuntu Server e VirtualBox
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Ubuntu Server Official Docs / LVM Administrator Guide
*******************************************************************************/

# LABORATORIO 36: INFRAESTRUTURA LINUX - INSTALACAO UBUNTU SERVER

## 1. DOWNLOAD DOS REQUISITOS
- Ubuntu Server: Efetue o download da ultima versao do Ubuntu Server (https://ubuntu.com/download/server).
- VirtualBox: Efetue o download da ultima versao do Oracle VirtualBox (https://www.virtualbox.org/).

## 2. PREPARACAO DA VM NO VIRTUALBOX
- Crie uma nova maquina virtual selecionando o tipo Linux e a versao Ubuntu.
- Aumente a memoria RAM para 2GB (ou conforme necessidade/capacidade).
- Crie um disco virtual de 30GB.
- Configure o adaptador de rede (Placa de Rede) da VM para o modo "Bridge". Isso permitira que a VM receba um IP da sua rede local pelo DHCP ou seja fixado manualmente.

## 3. INSTALACAO DO UBUNTU SERVER
- Inicie a VM carregando a ISO do Ubuntu Server baixada.
- Siga os passos normais do instalador, selecionando idioma e layout de teclado.
- Configurando o particionamento LVM (Durante a instalacao):
  - Selecione "Use an entire disk" e marque a opcao "Set up this disk as an LVM group".
  - O disco principal de 30GB devera ser particionado em volumes logicos.
  - O volume "/" (raiz) recebe as instalacoes dos programas (Linux, SGBDs). Aloque cerca de 6GB a 10GB.
  - Crie um Logical Volume para "/home" com cerca de 5GB.
  - Crie um Logical Volume para "/tmp" com cerca de 500MB a 2GB.
  - Crie um Logical Volume para dados de banco de dados (ex: "/dbfiles") com o espaco restante.
- Crie um usuario para administracao padrao: `usuarioteste` e defina uma senha forte.
- Finalize a instalacao e reinicie a VM ("Reboot Now").

## 4. FIXACAO DE IP (VIA NETPLAN)
Apos a instalacao, para ambientes de servidores (banco de dados, aplicacao), recomenda-se IP fixo.

1. Acesse o diretorio do netplan:
```bash
cd /etc/netplan
```

2. Faca o backup do arquivo de configuracao atual (ex: 00-installer-config.yaml):
```bash
sudo cp 00-installer-config.yaml 00-installer-config.yaml.bak
```

3. Edite o arquivo (utilize nano ou vi):
```bash
sudo nano 00-installer-config.yaml
```

4. Configure o arquivo com IP fixo (substitua os IPs 192.168.x.x conforme sua rede):
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: no
      dhcp6: no
      addresses:
        - 192.168.x.150/24
      routes:
        - to: default
          via: 192.168.x.1
```
Atencao: A identacao em YAML eh obrigatoria (utilize espacos, nao TAB).

5. Teste e aplique as novas configuracoes de rede:
```bash
sudo netplan try
sudo netplan apply
```

6. Verifique o novo IP:
```bash
ip a
```

## 5. INSTALACAO E ACESSO VIA PUTTY
Para facilitar a administracao, acesso via SSH eh recomendado usando uma ferramenta externa.

- Faca o download do Putty: https://putty.org/
- Instale no host de origem (Windows ou Jumpbox).
- Abra o Putty, insira o IP fixo configurado na VM (ex: 192.168.x.150) e a porta 22 (SSH).
- Salve a sessao e clique em "Open".
- Realize o login com o usuario `usuarioteste` criado na instalacao do Ubuntu.
