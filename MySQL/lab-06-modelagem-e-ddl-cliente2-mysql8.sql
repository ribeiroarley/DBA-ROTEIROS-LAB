/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-06-modelagem-e-ddl-cliente2-mysql8.sql
  Objetivo     : Roteiro DDL otimizado para o schema 'arley_cliente2'.
                 Criação de tabelas de fornecedores, produtos, clientes, pedidos e
                 itens de pedidos com suporte total à engine InnoDB, chaves primárias,
                 chaves estrangeiras, visibilidade de índices e padrão utf8mb4 no MySQL 8.x.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Data Definition Language (DDL)
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: CRIAÇÃO E CONFIGURAÇÃO DO SCHEMA DE TRABALHO
--------------------------------------------------------------------------------

-- Garantir a remoção prévia para execução idempotente
DROP DATABASE IF EXISTS arley_cliente2;

-- Criar schema utilizando o padrão Unicode de 4 bytes e collation modernas
CREATE DATABASE arley_cliente2
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

USE arley_cliente2;


--------------------------------------------------------------------------------
-- PARTE 2: CRIAÇÃO DAS TABELAS INDEPENDENTES (DOMÍNIOS PRINCIPAIS)
--------------------------------------------------------------------------------

-- Tabela de Fornecedores (Supplier)
CREATE TABLE IF NOT EXISTS supplier (
  id INT NOT NULL AUTO_INCREMENT,
  companyname VARCHAR(40) NOT NULL,
  contactname VARCHAR(50) NULL,
  contacttitle VARCHAR(40) NULL,
  city VARCHAR(40) NULL,
  country VARCHAR(40) NULL,
  phone VARCHAR(30) NULL,
  fax VARCHAR(30) NULL,
  PRIMARY KEY (id),
  INDEX idx_supplier_companyname (companyname ASC) VISIBLE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabela de Clientes (Customer)
CREATE TABLE IF NOT EXISTS customer (
  id INT NOT NULL AUTO_INCREMENT,
  firstname VARCHAR(40) NOT NULL,
  lastname VARCHAR(40) NOT NULL,
  city VARCHAR(40) NULL,
  country VARCHAR(40) NULL,
  phone VARCHAR(20) NULL,
  PRIMARY KEY (id),
  INDEX idx_customer_lastname (lastname ASC) VISIBLE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


--------------------------------------------------------------------------------
-- PARTE 3: CRIAÇÃO DAS TABELAS DEPENDENTES E CHAVES ESTRANGEIRAS
--------------------------------------------------------------------------------

-- Tabela de Produtos (Product - Relacionada a Supplier)
CREATE TABLE IF NOT EXISTS product (
  id INT NOT NULL AUTO_INCREMENT,
  productname VARCHAR(50) NOT NULL,
  supplierid INT NOT NULL,
  unitprice DECIMAL(12,2) NULL DEFAULT 0.00,
  package VARCHAR(30) NULL,
  isdiscontinued TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  INDEX fk_product_supplier1_idx (supplierid ASC) VISIBLE,
  CONSTRAINT fk_product_supplier1
    FOREIGN KEY (supplierid)
    REFERENCES supplier (id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabela de Pedidos (Order - Relacionada a Customer)
CREATE TABLE IF NOT EXISTS `order` (
  id INT NOT NULL AUTO_INCREMENT,
  orderdate DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  ordernumber VARCHAR(10) NULL,
  customerid INT NOT NULL,
  totalamount DECIMAL(12,2) NULL DEFAULT 0.00,
  PRIMARY KEY (id),
  INDEX fk_order_customer1_idx (customerid ASC) VISIBLE,
  CONSTRAINT fk_order_customer1
    FOREIGN KEY (customerid)
    REFERENCES customer (id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabela de Itens de Pedido (OrderItem - Relacionamento entre Order e Product)
CREATE TABLE IF NOT EXISTS orderitem (
  id INT NOT NULL AUTO_INCREMENT,
  orderid INT NOT NULL,
  productid INT NOT NULL,
  unitprice DECIMAL(12,2) NULL DEFAULT 0.00,
  quantity INT NULL DEFAULT 1,
  PRIMARY KEY (id),
  INDEX fk_orderitem_product1_idx (productid ASC) VISIBLE,
  INDEX fk_orderitem_order1_idx (orderid ASC) VISIBLE,
  CONSTRAINT fk_orderitem_product1
    FOREIGN KEY (productid)
    REFERENCES product (id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_orderitem_order1
    FOREIGN KEY (orderid)
    REFERENCES `order` (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


--------------------------------------------------------------------------------
-- PARTE 4: INSPEÇÃO DA ESTRUTURA E INTEGRIDADE REFERENCIAL
--------------------------------------------------------------------------------

-- Listar tabelas do schema ativo
SHOW TABLES FROM arley_cliente2;

-- Consultar Foreign Keys mapeadas no dicionário de dados
SELECT 
  table_name,
  column_name,
  constraint_name,
  referenced_table_name,
  referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema = 'arley_cliente2' AND referenced_table_name IS NOT NULL;


--------------------------------------------------------------------------------
-- PARTE 5: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

/*
-- Descomentar o bloco abaixo para remover os objetos ao concluir os estudos:

USE mysql;
DROP DATABASE IF EXISTS arley_cliente2;
*/