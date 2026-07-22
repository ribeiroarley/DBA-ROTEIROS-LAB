/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-05-modelagem-e-ddl-cliente-new-mysql8.sql
  Objetivo     : Roteiro DDL gerado a partir do modelo 'CLIENTE_NEW' (MySQL Workbench).
                 Estrutura completa de tabelas de vendas/pedidos, clientes, produtos e 
                 itens com relacionamentos N:M, chaves estrangeiras, motores InnoDB 
                 e collation utf8mb4_0900_ai_ci para MySQL 8.x.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Data Definition Language (DDL)
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: CRIAÇÃO E CONFIGURAÇÃO DO SCHEMA DE TRABALHO
--------------------------------------------------------------------------------

-- Garantir idempotência na criação do schema
DROP DATABASE IF EXISTS arley_cliente_new;

-- Criar schema com padrão moderno UTF-8 de 4 bytes
CREATE DATABASE arley_cliente_new
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

USE arley_cliente_new;


--------------------------------------------------------------------------------
-- PARTE 2: CRIAÇÃO DAS TABELAS INDEPENDENTES (DOMÍNIOS PRINCIPAIS)
--------------------------------------------------------------------------------

-- Tabela de Clientes
CREATE TABLE IF NOT EXISTS customer (
  id INT NOT NULL AUTO_INCREMENT,
  firstname VARCHAR(40) NOT NULL,
  lastname VARCHAR(40) NOT NULL,
  city VARCHAR(40) NULL,
  country VARCHAR(40) NULL,
  phone VARCHAR(20) NULL,
  PRIMARY KEY (id),
  INDEX idx_customer_lastname (lastname ASC) VISIBLE,
  INDEX idx_customer_country (country ASC) VISIBLE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabela de Fornecedores (Suppliers)
CREATE TABLE IF NOT EXISTS supplier (
  id INT NOT NULL AUTO_INCREMENT,
  companyname VARCHAR(40) NOT NULL,
  contactname VARCHAR(50) NULL,
  contacttitle VARCHAR(30) NULL,
  city VARCHAR(40) NULL,
  country VARCHAR(40) NULL,
  phone VARCHAR(30) NULL,
  fax VARCHAR(30) NULL,
  PRIMARY KEY (id),
  INDEX idx_supplier_companyname (companyname ASC) VISIBLE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


--------------------------------------------------------------------------------
-- PARTE 3: CRIAÇÃO DAS TABELAS DEPENDENTES E RELACIONAMENTOS
--------------------------------------------------------------------------------

-- Tabela de Produtos (Atrelada ao Fornecedor)
CREATE TABLE IF NOT EXISTS product (
  id INT NOT NULL AUTO_INCREMENT,
  productname VARCHAR(50) NOT NULL,
  supplierid INT NOT NULL,
  unitprice DECIMAL(12,2) NULL DEFAULT 0.00,
  package VARCHAR(30) NULL,
  isdiscontinued TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  INDEX idx_product_supplierid (supplierid ASC) VISIBLE,
  INDEX idx_product_productname (productname ASC) VISIBLE,
  CONSTRAINT fk_product_supplier
    FOREIGN KEY (supplierid)
    REFERENCES supplier (id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabela de Pedidos (Orders - Atrelada ao Cliente)
CREATE TABLE IF NOT EXISTS `order` (
  id INT NOT NULL AUTO_INCREMENT,
  orderdate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ordernumber VARCHAR(10) NULL,
  customerid INT NOT NULL,
  totalamount DECIMAL(12,2) NULL DEFAULT 0.00,
  PRIMARY KEY (id),
  INDEX idx_order_customerid (customerid ASC) VISIBLE,
  INDEX idx_order_orderdate (orderdate ASC) VISIBLE,
  CONSTRAINT fk_order_customer
    FOREIGN KEY (customerid)
    REFERENCES customer (id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabela de Itens do Pedido (OrderItem - Relacionamento Pedido x Produto)
CREATE TABLE IF NOT EXISTS orderitem (
  id INT NOT NULL AUTO_INCREMENT,
  orderid INT NOT NULL,
  productid INT NOT NULL,
  unitprice DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  quantity INT NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  INDEX idx_orderitem_orderid (orderid ASC) VISIBLE,
  INDEX idx_orderitem_productid (productid ASC) VISIBLE,
  CONSTRAINT fk_orderitem_order
    FOREIGN KEY (orderid)
    REFERENCES `order` (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_orderitem_product
    FOREIGN KEY (productid)
    REFERENCES product (id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


--------------------------------------------------------------------------------
-- PARTE 4: INSPEÇÃO DE ESTRUTURAS E METADADOS
--------------------------------------------------------------------------------

-- Listar todas as tabelas criadas no schema
SHOW TABLES FROM arley_cliente_new;

-- Exibir relacionamentos de chave estrangeira configurados
SELECT 
  table_name,
  column_name,
  constraint_name,
  referenced_table_name,
  referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema = 'arley_cliente_new' AND referenced_table_name IS NOT NULL;


--------------------------------------------------------------------------------
-- PARTE 5: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

/*
-- Descomentar o bloco abaixo para remover os objetos ao concluir os estudos:

USE mysql;
DROP DATABASE IF EXISTS arley_cliente_new;
*/