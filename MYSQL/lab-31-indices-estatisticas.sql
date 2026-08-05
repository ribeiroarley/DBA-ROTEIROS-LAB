/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-31-indices-estatisticas.sql
  Objetivo     : Clustered/Non-clustered Indexes, FULLTEXT, EXPLAIN, ANALYZE e OPTIMIZE
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Optimization and Indexes
*******************************************************************************/

-- 1. Setup do ambiente de testes
CREATE DATABASE IF NOT EXISTS stackoverflow;
USE stackoverflow;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id INT NOT NULL,
    creation_date DATETIME,
    displayname VARCHAR(256),
    down_votes INT,
    last_access_date DATETIME,
    location VARCHAR(256),
    reputation INT,
    up_votes INT,
    views INT
);

-- Injeção de massa de dados genérica e corporativa para testes
INSERT INTO users (id, creation_date, displayname, down_votes, last_access_date, location, reputation, up_votes, views) VALUES
(1, '2023-01-15 10:00:00', 'usuarioteste_01', 0, '2023-01-20 15:30:00', 'New York, NY', 100, 5, 20),
(2, '2023-02-10 09:15:00', 'usuarioteste_02', 2, '2023-03-05 14:00:00', 'Corvallis, OR', 250, 15, 100),
(3, '2023-03-22 11:45:00', 'usuarioteste_03', 1, '2023-04-10 08:20:00', 'New York, NY', 50, 2, 10),
(4, '2023-04-05 16:30:00', 'usuarioteste_04', 5, '2023-04-25 18:00:00', 'Los Angeles, CA', 500, 30, 250),
(5, '2009-06-28 10:00:00', 'usuarioteste_05', 0, '2010-01-01 10:00:00', 'New York, NY', 10, 1, 5),
(5000, '2015-05-15 12:00:00', 'usuarioteste_5000', 10, '2023-01-01 10:00:00', 'Chicago, IL', 1500, 100, 1000);

-- Adicionando mais alguns registros simulados para cardinalidade
INSERT INTO users (id, creation_date, displayname, location, reputation) 
SELECT id + 10000, NOW(), CONCAT('usuarioteste_', id + 10000), 'Seattle, WA', 10 FROM users;
INSERT INTO users (id, creation_date, displayname, location, reputation) 
SELECT id + 20000, NOW(), CONCAT('usuarioteste_', id + 20000), 'Austin, TX', 20 FROM users;

-- 2. Consultas básicas sem índices
SELECT * FROM users ORDER BY displayname DESC, location ASC, reputation DESC;

-- Usando EXPLAIN para análise de queries
EXPLAIN SELECT * FROM users WHERE id = 5000;

-- 3. Criação de Índice Clustered (Primary Key)
ALTER TABLE users ADD PRIMARY KEY (id);

-- Teste após criação da PK
EXPLAIN SELECT id FROM users ORDER BY id;
EXPLAIN SELECT * FROM users WHERE id = 5000;

-- 4. Índice Non-Clustered Simples
SELECT * FROM users WHERE displayname = 'usuarioteste_01';
CREATE INDEX idx_users_displayname ON users(displayname);
EXPLAIN SELECT * FROM users WHERE displayname = 'usuarioteste_01';

-- 5. Índice Non-Clustered Composto
-- Drop do índice simples anterior
DROP INDEX idx_users_displayname ON users;
CREATE INDEX idx_users_displayname_location ON users(displayname, location);

-- Consultas utilizando o índice composto (Ordem dos campos no WHERE não importa, mas no CREATE sim)
EXPLAIN SELECT * FROM users WHERE displayname = 'usuarioteste_01' AND location = 'New York, NY';
EXPLAIN SELECT * FROM users WHERE location = 'New York, NY' AND displayname = 'usuarioteste_01';
-- Abaixo fará Full Table Scan, pois location não é o primeiro campo do índice
EXPLAIN SELECT * FROM users WHERE location = 'Corvallis, OR';

-- 6. Otimização de Funções de Agregação
EXPLAIN SELECT AVG(reputation), MAX(reputation), MIN(reputation) FROM users;
CREATE INDEX idx_users_reputation ON users(reputation);
EXPLAIN SELECT AVG(reputation), MAX(reputation), MIN(reputation) FROM users;

-- 7. Operador LIKE
-- Utiliza o índice (Range Scan)
EXPLAIN SELECT displayname FROM users WHERE displayname LIKE 'usuario%';
-- Full Table Scan (Curinga no início)
EXPLAIN SELECT displayname FROM users WHERE displayname LIKE '%teste%';

-- 8. Uso do EXPLAIN ANALYZE (MySQL 8.0+)
-- EXPLAIN ANALYZE executa a consulta real para mostrar o tempo e custo efetivos
EXPLAIN ANALYZE SELECT * FROM users WHERE displayname = 'usuarioteste_01';

-- 9. Índices em colunas de Data
ALTER TABLE users MODIFY COLUMN creation_date DATE;
CREATE INDEX idx_users_creation_date ON users(creation_date);

-- O uso do índice vai depender da cardinalidade e do filtro aplicado.
EXPLAIN ANALYZE SELECT * FROM users WHERE creation_date = '2009-06-28';
EXPLAIN ANALYZE SELECT * FROM users WHERE creation_date >= '2023-01-01' AND creation_date <= '2023-12-31';

-- 10. Forçar índice vs Estatísticas (Não recomendado em produção a não ser em casos extremos)
EXPLAIN SELECT * FROM users FORCE INDEX (idx_users_creation_date) WHERE creation_date >= '2023-01-01' AND creation_date <= '2023-12-31';

-- Atualização manual de estatísticas de índices (Cardinalidade)
ANALYZE TABLE users;

-- 11. Índice Único (Unique Index)
CREATE UNIQUE INDEX idx_users_unique_displayname ON users (displayname);
SHOW INDEXES FROM users;
DROP INDEX idx_users_unique_displayname ON users;

-- 12. Índice FULLTEXT
CREATE FULLTEXT INDEX idx_fulltext_location ON users(location);

-- Comparação LIKE vs MATCH AGAINST
EXPLAIN SELECT * FROM users WHERE location LIKE '%New York%';
EXPLAIN SELECT * FROM users WHERE MATCH (location) AGAINST ('New York');

-- Manutenção e Otimização da Tabela
OPTIMIZE TABLE users;
