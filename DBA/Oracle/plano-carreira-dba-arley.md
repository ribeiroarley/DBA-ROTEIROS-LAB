# 🎯 Meu Plano de Carreira DBA - Arley Ribeiro

Este documento é a minha base pessoal de estudos, desenvolvimento técnico e estratégia de carreira como **DBA Júnior focado em Oracle Database (19c / Multitenant)**.

---

## 📌 Minha Visão de Carreira

Consolidar minha atuação como Administrador de Banco de Dados Júnior, dominando os fundamentos práticos de administração, segurança, automação e otimização. O objetivo final é evoluir de forma consistente para o nível Pleno e estruturar competências para projetos de alta complexidade e consultoria técnica.

---

## 🚀 Pilares do Meu Desenvolvimento

Para me destacar e evoluir com segurança, mantenho o foco em três pilares fundamentais:

1. **Domínio Teórico e Prático dos Fundamentos**: Não apenas rodar scripts, mas entender exatamente a arquitetura em segundo plano (SGA, PGA, Datafiles, Redo Logs e UNDO).
2. **Capacidade de Comunicação Técnica**: Explicar com clareza a causa-raiz dos problemas e justificativas das soluções aplicadas nos laboratórios.
3. **Resolução de Problemas Sob Pressão**: Treinar troubleshooting e recuperação de ambiente (RMAN/Flashback) para manter o controle em cenários críticos.

---

## 🗺️ Trilha Pessoal de Aprendizado (Roadmap)

### Fase 1: Base Técnica Consistente (Concluída/Em Aprimoramento)
- [x] **Arquitetura Oracle 19c**: Entendimento de instâncias, memórias, processos e Multitenant (CDB/PDB).
- [x] **Manipulação de Armazenamento**: Gestão de Tablespaces (Smallfile, Bigfile, Temporary e UNDO).
- [x] **Segurança e Privilégios**: Criação de Users, Roles, Quotas e controle fino de permissões de objetos.

### Fase 2: Operação, Backup e Recovery
- [x] **Estratégias de Backup**: Utilização do RMAN (Full, Incremental Level 0/1, Archivelog e Compressão).
- [x] **Data Pump**: Exportação e importação lógica de Schemas e Tabelas (`expdp`/`impdp`).
- [x] **Técnicas de Recovery**: Point-In-Time Recovery (PITR), restauração de Controlfile, SPfile, Datafiles e Flashback (Query, Table, Database).

### Fase 3: Performance, Manutenção e Automação
- [x] **Tuning Básico**: Leitura e interpretação de Planos de Execução (`EXPLAIN PLAN`, `DBMS_XPLAN`), análise de cardinalidade e Wait Events.
- [x] **Estatísticas e Índices**: Coleta via `DBMS_STATS`, otimização e Rebuild de Índices B-Tree/Unique.
- [x] **Automação de Tarefas**: Agendamento de Jobs corporativos com `DBMS_SCHEDULER`, Shell Scripts e Python para automação operacionais.

---

## 🛠️ Stack Tecnológica de Apoio

* **SGBDs Relacionais**: Oracle Database 19c (Principal), SQL Server, PostgreSQL, MySQL.
* **Infraestrutura e Virtualização**: Windows Server 2022, VirtualBox, Hyper-V e Docker.
* **Linguagens e Automação**: SQL, PL/SQL, Python, PowerShell e Shell Script.
* **Ferramentas de Engenharia de Dados & BI**: Data Warehouse, ETL (SSIS/SSAS) e Power BI.

---

## 📋 Regra de Ouro Pessoal

> "Você não precisa saber tudo de cor, mas precisa saber exatamente onde procurar, como testar isoladamente em laboratório e como aplicar com segurança sem impactar o ambiente."

**Proprietário do Plano:** Arley Ribeiro  
**Repositório Base:** `dba-education-lab`