/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-40-mysql-linux-objetos-comandos.sql
  Objetivo     : Laboratório prático de DDL, DML, Views, Procedures, Triggers e Eventos no Linux
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

-- 1. DDL (Criação de Database e Tabelas)

CREATE DATABASE IF NOT EXISTS banco_teste 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_0900_ai_ci;

USE banco_teste;

CREATE TABLE IF NOT EXISTS supplier (
  id INT NOT NULL,
  companyname VARCHAR(40) NULL,
  contactname VARCHAR(50) NULL,
  contacttitle VARCHAR(40) NULL,
  city VARCHAR(40) NULL,
  country VARCHAR(40) NULL,
  phone VARCHAR(30) NULL,
  fax VARCHAR(30) NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS product (
  id INT NOT NULL,
  productname VARCHAR(50) NULL,
  supplierid INT NOT NULL,
  unitprice DECIMAL(12,2) NULL,
  package VARCHAR(30) NULL,
  isdiscontinued BIT NULL,
  PRIMARY KEY (id),
  INDEX fk_product_supplier_idx (supplierid ASC) VISIBLE,
  CONSTRAINT fk_product_supplier
    FOREIGN KEY (supplierid)
    REFERENCES supplier (id)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS customer (
  id INT NOT NULL,
  firstname VARCHAR(40) NULL,
  lastname VARCHAR(40) NULL,
  city VARCHAR(40) NULL,
  country VARCHAR(40) NULL,
  phone VARCHAR(20) NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS `order` (
  id INT NOT NULL,
  orderdate DATETIME NULL,
  ordernumber VARCHAR(10) NULL,
  customerid INT NOT NULL,
  totalamount DECIMAL(12,2) NULL,
  PRIMARY KEY (id),
  INDEX fk_order_customer_idx (customerid ASC) VISIBLE,
  CONSTRAINT fk_order_customer
    FOREIGN KEY (customerid)
    REFERENCES customer (id)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS orderitem (
  id INT NOT NULL,
  orderid INT NOT NULL,
  productid INT NOT NULL,
  unitprice DECIMAL(12,2) NULL,
  quantity INT NULL,
  PRIMARY KEY (id),
  INDEX fk_orderitem_product_idx (productid ASC) VISIBLE,
  INDEX fk_orderitem_order_idx (orderid ASC) VISIBLE,
  CONSTRAINT fk_orderitem_product
    FOREIGN KEY (productid)
    REFERENCES product (id)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT fk_orderitem_order
    FOREIGN KEY (orderid)
    REFERENCES `order` (id)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS produto_auditoria (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_produto INT NOT NULL,
    productname VARCHAR(50) NOT NULL,
    data_modificacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    acao VARCHAR(10) NOT NULL
);

-- 2. DML (Inserts)

INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES 
(1, 'usuario_teste', 'Silva', 'Sao Paulo', 'Brazil', '11-5555-0001'),
(2, 'teste', 'Oliveira', 'Madrid', 'Spain', '91-555-0002'),
(3, 'usuarioteste', 'Souza', 'London', 'UK', '256-555-0003'),
(4, 'teste_user', 'Santos', 'Berlin', 'Germany', '030-555-0004');

INSERT INTO supplier (id, companyname, contactname, city, country, phone) VALUES 
(1, 'Tech Supplies', 'usuario_teste', 'London', 'UK', '56-555-1111'),
(2, 'Global Foods', 'teste', 'New Orleans', 'USA', '100-555-2222'),
(3, 'Euro Parts', 'usuarioteste', 'Madrid', 'Spain', '91-555-3333');

INSERT INTO product (id, productname, supplierid, unitprice, package, isdiscontinued) VALUES 
(1, 'Produto A', 1, 18.00, 'Caixa com 10', 0),
(2, 'Produto B', 1, 19.00, 'Caixa com 24', 0),
(3, 'Produto C', 2, 22.00, 'Pacote 5kg', 0),
(4, 'Produto D', 3, 10.00, 'Unidade', 0);

INSERT INTO `order` (id, orderdate, customerid, totalamount, ordernumber) VALUES 
(1, '2023-01-01', 1, 100.00, 'ORD001'),
(2, '2023-01-02', 2, 250.00, 'ORD002'),
(3, '2023-01-03', 3, 150.00, 'ORD003');

INSERT INTO orderitem (id, orderid, productid, unitprice, quantity) VALUES 
(1, 1, 1, 18.00, 2),
(2, 1, 4, 10.00, 6),
(3, 2, 2, 19.00, 10),
(4, 2, 3, 22.00, 2),
(5, 3, 1, 18.00, 5);

-- 3. VIEWS

CREATE OR REPLACE VIEW vw_customer_madrid AS
SELECT * 
FROM customer 
WHERE city = 'Madrid';

-- 4. STORED PROCEDURES

DELIMITER $$

CREATE PROCEDURE sp_get_products_by_supplier(IN p_supplierid INT)
BEGIN
    SELECT 
        id, 
        productname, 
        unitprice 
    FROM product 
    WHERE supplierid = p_supplierid;
END$$

DELIMITER ;

-- 5. TRIGGERS

DELIMITER $$

CREATE TRIGGER trg_after_product_insert
AFTER INSERT ON product
FOR EACH ROW
BEGIN
    INSERT INTO produto_auditoria (id_produto, productname, acao)
    VALUES (NEW.id, NEW.productname, 'INS');
END$$

DELIMITER ;

-- 6. DCL (Criação de Usuários e Privilégios)

CREATE USER IF NOT EXISTS 'usuarioteste'@'%' IDENTIFIED BY 'SenhaSegura!123'; 

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE 
ON banco_teste.* 
TO 'usuarioteste'@'%';

FLUSH PRIVILEGES;

-- 7. EVENTS (Agendador do MySQL)

SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE EVENT evt_inseredados1minuto
ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 MINUTE 
DO
BEGIN
    INSERT INTO customer (id, firstname, lastname, city, country, phone)
    VALUES (999, 'usuarioteste', 'teste', 'Berlin', 'Germany', '000-0000000');
END$$

DELIMITER ;
