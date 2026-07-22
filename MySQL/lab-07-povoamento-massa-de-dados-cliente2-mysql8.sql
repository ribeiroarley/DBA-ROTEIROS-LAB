/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-07-povoamento-massa-de-dados-cliente2-mysql8.sql
  Objetivo     : Roteiro DML para carga inicial e povoamento de massa de dados 
                 no schema 'arley_cliente2' (Customer, Supplier, Product, Order e 
                 OrderItem) mantendo integridade referencial no MySQL 8.x.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / INSERT Statement & Data Manipulation
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SELEÇÃO DO SCHEMA E AJUSTE TEMPORÁRIO DE CHECAGENS
--------------------------------------------------------------------------------

USE arley_cliente2;

-- Desabilitar temporariamente as verificações de chave estrangeira para otimização da carga
SET FOREIGN_KEY_CHECKS = 0;

-- Limpar dados das tabelas mantendo as DDLs intactas
TRUNCATE TABLE orderitem;
TRUNCATE TABLE `order`;
TRUNCATE TABLE product;
TRUNCATE TABLE supplier;
TRUNCATE TABLE customer;

-- Reabilitar as verificações de chave estrangeira
SET FOREIGN_KEY_CHECKS = 1;


--------------------------------------------------------------------------------
-- PARTE 2: CARGA DE DADOS NA TABELA 'CUSTOMER'
--------------------------------------------------------------------------------

INSERT INTO customer (id, firstname, lastname, city, country, phone) VALUES
(1, 'Maria', 'Anfefeefeders', 'Berlin', 'Germany', '030-0074321'),
(2, 'Ana', 'Truefeejillo', 'México D.F.', 'Mexico', '(56) 555-4729'),
(3, 'Antonio', 'Moreddno', 'México D.F.', 'Mexico', '(56) 555-3932'),
(4, 'Thomas', 'Hadddrdy', 'London', 'UK', '(256) 555-7788'),
(5, 'Christina', 'Beddfrglund', 'Luleå', 'Sweden', '0921-12 34 65'),
(6, 'Hanna', 'Moos', 'Mannhddddseim', 'Germany', '0621-08460'),
(7, 'Frédérique', 'Citgggdeseaux', 'Strasbourg', 'France', '88.60.15.31'),
(8, 'Martín', 'Sommfefer', 'Madrid', 'Spain', '(91) 555 22 82'),
(9, 'Laurence', 'Lefefebihan', 'Marseille', 'France', '91.24.45.40'),
(10, 'Elizabeth', 'Lifefessncoln', 'Tsawassen', 'Canada', '(604) 555-4729'),
(11, 'Victoria', 'Ashscceworth', 'London', 'UK', '(256) 555-1212'),
(12, 'Patricio', 'Siggrmpson', 'Buenos Aires', 'Argentina', '(1) 135-5555'),
(13, 'Francisco', 'Chggrggrang', 'México D.F.', 'Mexico', '(5) 555-3392'),
(14, 'Yang', 'Waggrng', 'Bern', 'Switzerland', '0452-076545'),
(15, 'Pedro', 'Afddronso', 'Sao Paulo', 'Brazil', '(11) 555-7647'),
(16, 'Elizabeth', 'Brvvdown', 'London', 'UK', '(256) 555-2282'),
(17, 'Sven', 'Ottffvflieb', 'Aachen', 'Germany', '0241-039123'),
(18, 'Janine', 'Labvvfrune', 'Nantes', 'France', '40.67.88.88'),
(19, 'Ann', 'Devfvfon', 'London', 'UK', '(256) 555-0297'),
(20, 'Roland', 'Menffvdel', 'Graz', 'Austria', '7675-3425'),
(21, 'Aria', 'Crvvvuz', 'Sao Paulo', 'Brazil', '(11) 555-9857'),
(22, 'Diego', 'Roffvel', 'Madrid', 'Spain', '(91) 555 94 44'),
(23, 'Martine', 'Radcddvvncé', 'Lille', 'France', '20.16.10.16'),
(24, 'Maria', 'Lavfvfrsson', 'Bräcke', 'Sweden', '0695-34 67 21'),
(25, 'Peter', 'Frvfvanken', 'München', 'Germany', '089-0877310'),
(26, 'Carine', 'Scvffhmitt', 'Nantes', 'France', '40.32.21.21'),
(27, 'Paolo', 'Accfffffcorti', 'Torino', 'Italy', '011-4988260'),
(28, 'Lino', 'Roccccdriguez', 'Lisboa', 'Portugal', '(1) 354-2534'),
(29, 'Eduardo', 'Saavvvvedra', 'Barcelona', 'Spain', '(93) 203 4560'),
(30, 'José', 'Pedvvro Freyre', 'Sevilla', 'Spain', '(95) 555 82 82'),
(31, 'André', 'Fovvvdnseca', 'Campinas', 'Brazil', '(11) 555-9482'),
(32, 'Howard', 'Snyddder', 'Eugene', 'USA', '(503) 555-7555'),
(33, 'Manuel', 'Pervveira', 'Caracas', 'Venezuela', '(2) 283-2951'),
(34, 'Mario', 'Ponvvdtes', 'Rio de Janeiro', 'Brazil', '(21) 555-0091'),
(35, 'Carlos', 'Hevvddrnández', 'San Cristóbal', 'Venezuela', '(5) 555-1340'),
(36, 'Yoshi', 'Latvvddimer', 'Elgin', 'USA', '(503) 555-6874'),
(37, 'Patricia', 'McKvdvdvenna', 'Cork', 'Ireland', '2967 542'),
(38, 'Helen', 'Benvvddvnett', 'Cowes', 'UK', '(198) 555-8888'),
(39, 'Philip', 'Crfffamer', 'Brandenburg', 'Germany', '0555-09876'),
(40, 'Daniel', 'Toccenini', 'Versailles', 'France', '30.59.84.10'),
(41, 'Annette', 'Roccccculet', 'Toulouse', 'France', '61.77.61.10'),
(42, 'Yoshi', 'Tanncccamuri', 'Vancouver', 'Canada', '(604) 555-3392'),
(43, 'John', 'Stecccel', 'Walla Walla', 'USA', '(509) 555-7969'),
(44, 'Renate', 'Mcdessner', 'Frankfurt a.M.', 'Germany', '069-0245984'),
(45, 'Jaime', 'Yorccdres', 'San Francisco', 'USA', '(415) 555-5938'),
(46, 'Carlos', 'Goccnzález', 'Barquisimeto', 'Venezuela', '(9) 331-6954'),
(47, 'Felipe', 'Izccdquierdo', 'I. de Margarita', 'Venezuela', '(8) 34-56-12'),
(48, 'Fran', 'Wilcddson', 'Portland', 'USA', '(503) 555-9573'),
(49, 'Giovanni', 'Rocddvelli', 'Bergamo', 'Italy', '035-640230'),
(50, 'Catherine', 'Decccwey', 'Bruxelles', 'Belgium', '(02) 201 24 67'),
(51, 'Jean', 'Fresccdnière', 'Montréal', 'Canada', '(514) 555-8054'),
(52, 'Alexander', 'Feccduer', 'Leipzig', 'Germany', '0342-023176'),
(53, 'Simon', 'Crowcdther', 'London', 'UK', '(56) 555-7733'),
(54, 'Yvonne', 'Monccddcccada', 'Buenos Aires', 'Argentina', '(1) 135-5333'),
(55, 'Rene', 'Phiccddllips', 'Anchorage', 'USA', '(907) 555-7584'),
(56, 'Henriette', 'Pccddfalzheim', 'Köln', 'Germany', '0221-0644327'),
(57, 'Marie', 'Beccddrtrand', 'Paris', 'France', '(1) 42.34.22.66'),
(58, 'Guillermo', 'Fcddcernández', 'México D.F.', 'Mexico', '(5) 552-3745'),
(59, 'Georg', 'Pipccddps', 'Salzburg', 'Austria', '6562-9722'),
(60, 'Isabel', 'de Caccddstro', 'Lisboa', 'Portugal', '(1) 356-5634'),
(61, 'Bernardo', 'Baccdtista', 'Rio de Janeiro', 'Brazil', '(21) 555-4252'),
(62, 'Lúcia', 'Carccddvalho', 'Sao Paulo', 'Brazil', '(11) 555-1189'),
(63, 'Horst', 'Klccddoss', 'Cunewalde', 'Germany', '0372-035188'),
(64, 'Sergio', 'Gutccddiérrez', 'Buenos Aires', 'Argentina', '(1) 123-5555'),
(65, 'Paula', 'Wccddilson', 'Albuquerque', 'USA', '(505) 555-5939'),
(66, 'Maurizio', 'Moccddroni', 'Reggio Emilia', 'Italy', '0522-556721'),
(67, 'Janete', 'Liccdmeira', 'Rio de Janeiro', 'Brazil', '(21) 555-3412'),
(68, 'Michael', 'Hccddolz', 'Genève', 'Switzerland', '0897-034214'),
(69, 'Alejandra', 'Cacddddmino', 'Madrid', 'Spain', '(91) 745 6200'),
(70, 'Jonas', 'Bccddcergulfsen', 'Stavern', 'Norway', '07-98 92 35'),
(71, 'Jose', 'Paccddccvarotti', 'Boise', 'USA', '(208) 555-8097'),
(72, 'Hari', 'Kumccddar', 'London', 'UK', '(56) 555-1717'),
(73, 'Jytte', 'Pccdcdetersen', 'Kobenhavn', 'Denmark', '31 12 34 56'),
(74, 'Dominique', 'Peccddrrier', 'Paris', 'France', '(1) 47.55.60.10'),
(75, 'Art', 'Braccddunschweiger', 'Lander', 'USA', '(307) 555-4680'),
(76, 'Pascale', 'Caddcdrtrain', 'Charleroi', 'Belgium', '(071) 23 67 22 20'),
(77, 'Liz', 'Nixeeeon', 'Portland', 'USA', '(503) 555-3612'),
(78, 'Liu', 'Weeeong', 'Butte', 'USA', '(406) 555-5834'),
(79, 'Karin', 'Joecesephs', 'Münster', 'Germany', '0251-031259'),
(80, 'Miguel', 'Angdeel Paolino', 'México D.F.', 'Mexico', '(5) 555-2933'),
(81, 'Anabela', 'Domieedngues', 'Sao Paulo', 'Brazil', '(11) 555-2167'),
(82, 'Helvetius', 'Naeddgy', 'Kirkland', 'USA', '(206) 555-8257'),
(83, 'Palle', 'Ibsedden', 'Århus', 'Denmark', '86 21 32 43'),
(84, 'Mary', 'Savdedeley', 'Lyon', 'France', '78.32.54.86'),
(85, 'Paul', 'Heeeddeenriot', 'Reims', 'France', '26.47.15.10'),
(86, 'Rita', 'Müleddler', 'Stuttgart', 'Germany', '0711-020361'),
(87, 'Pirkko', 'Koseddekitalo', 'Oulu', 'Finland', '981-443655'),
(88, 'Paula', 'Pareeddente', 'Resende', 'Brazil', '(14) 555-8122'),
(89, 'Karl', 'Jabloedednski', 'Seattle', 'USA', '(206) 555-4112'),
(90, 'Matti', 'Kartdeetunen', 'Helsinki', 'Finland', '90-224 8858'),
(91, 'Zbyszek', 'Piesddeedtrzeniewicz', 'Warszawa', 'Poland', '(26) 642-7012');


--------------------------------------------------------------------------------
-- PARTE 3: CARGA DE DADOS NA TABELA 'SUPPLIER'
--------------------------------------------------------------------------------

INSERT INTO supplier (id, companyname, contactname, city, country, phone, fax) VALUES
(1, 'Exotic Liquids', 'CharlDDDDSotte Cooper', 'London', 'UK', '(56) 555-2222', NULL),
(2, 'New Orleans Cajun Delights', 'ShelDDDSSley Burke', 'New Orleans', 'USA', '(100) 555-4822', NULL),
(3, 'Grandma Kellys Homestead', 'RegEEWina Murphy', 'Ann Arbor', 'USA', '(313) 555-5735', '(313) 555-3349'),
(4, 'Tokyo Traders', 'YosEEEhi Nagase', 'Tokyo', 'Japan', '(03) 3555-5011', NULL),
(5, 'Cooperativa de Quesos Las Cabras', 'AntoEEenio del Valle Saavedra', 'Oviedo', 'Spain', '(98) 598 76 54', NULL),
(6, 'Mayumis', 'Mayueedfemi Ohno', 'Osaka', 'Japan', '(06) 431-7877', NULL),
(7, 'Pavlova, Ltd.', 'Ian Devefeling', 'Melbourne', 'Australia', '(03) 444-2343', '(03) 444-6588'),
(8, 'Specialty Biscuits, Ltd.', 'Peter Wilsefeon', 'Manchester', 'UK', '(161) 555-4448', NULL),
(9, 'PB Knäckebröd AB', 'Lars Peterefeson', 'Göteborg', 'Sweden', '031-987 65 43', '031-987 65 91'),
(10, 'Refrescos Americanas LTDA', 'Carlos Diafefez', 'Sao Paulo', 'Brazil', '(56) 555 4640', NULL),
(11, 'Heli Süßwaren GmbH & Co. KG', 'Petra Winefekler', 'Berlin', 'Germany', '(010) 9984510', NULL),
(12, 'Plutzer Lebensmittelgroßmärkte AG', 'Martin Beefein', 'Frankfurt', 'Germany', '(069) 992755', NULL),
(13, 'Nord-Ost-Fisch Handelsgesellschaft mbH', 'Sven Peteefersen', 'Cuxhaven', 'Germany', '(04721) 8713', '(04721) 8714'),
(14, 'Formaggi Fortini s.r.l.', 'Elio Rosfeesi', 'Ravenna', 'Italy', '(0544) 60323', '(0544) 60603'),
(15, 'Norske Meierier', 'Beate Vilfefeeid', 'Safndvika', 'Norway', '(0)2-953010', NULL),
(16, 'Bigfoot Breweries', 'Cheryl Sayfeeffelor', 'Bend', 'USA', '(503) 555-9931', NULL),
(17, 'Svensk Sjöföda AB', 'Michael Björn', 'Stockholm', 'Sweden', '08-123 45 67', NULL),
(18, 'Aux joyeux ecclésiastiques', 'Guylène Noffedier', 'Paris', 'France', '(1) 03.83.00.68', '(1) 03.83.00.62'),
(19, 'New England Seafood Cannery', 'Robb Merchffeant', 'Boston', 'USA', '(617) 555-3267', '(617) 555-3389'),
(20, 'Leka Trading', 'Chandra Lefeka', 'Singapore', 'Singapore', '555-8787', NULL),
(21, 'Lyngbysild', 'Niels Peteffersen', 'Lyngby', 'Denmark', '43844108', '43844115'),
(22, 'Zaanse Snoepfabriek', 'Dirk Luchffete', 'Zaandam', 'Netherlands', '(12345) 1212', '(12345) 1210'),
(23, 'Karkki Oy', 'Anne Heikkofefffeeffenen', 'Lappeenranta', 'Finland', '(953) 10956', NULL),
(24, 'Gday Mate', 'Wendy Mackenzie', 'Sydney', 'Australia', '(02) 555-5914', '(02) 555-4873'),
(25, 'Ma Maison', 'Jean-Guy Lauzon', 'Montréal', 'Canada', '(514) 555-9022', NULL),
(26, 'Pasta Buttini s.r.l.', 'Giovanni Giudfffici', 'Salerno', 'Italy', '(089) 6547665', '(089) 6547667'),
(27, 'Escargots Nouveaux', 'Marie Delaefemare', 'Montceau', 'France', '85.57.00.07', NULL),
(28, 'Gai pâturage', 'Eliane Noz', 'Annefefecy', 'France', '38.76.98.06', '38.76.98.58'),
(29, 'Forêts érables', 'Chantal Gouffeelet', 'Ste-Hyacinthe', 'Canada', '(514) 555-2955', '(514) 555-2921');


--------------------------------------------------------------------------------
-- PARTE 4: CARGA DE DADOS NA TABELA 'PRODUCT'
--------------------------------------------------------------------------------

INSERT INTO product (id, productname, supplierid, unitprice, package, isdiscontinued) VALUES
(1, 'Chai', 1, 18.00, '10 boxes x 20 bags', 0),
(2, 'Chang', 1, 19.00, '24 - 12 oz bottles', 0),
(3, 'Aniseed Syrup', 1, 10.00, '12 - 550 ml bottles', 0),
(4, 'Chef Antons Cajun Seasoning', 2, 22.00, '48 - 6 oz jars', 0),
(5, 'Chef Antons Gumbo Mix', 2, 21.35, '36 boxes', 1),
(6, 'Grandmas Boysenberry Spread', 3, 25.00, '12 - 8 oz jars', 0),
(7, 'Uncle Bobs Organic Dried Pears', 3, 30.00, '12 - 1 lb pkgs.', 0),
(8, 'Northwoods Cranberry Sauce', 3, 40.00, '12 - 12 oz jars', 0),
(9, 'Mishi Kobe Niku', 4, 97.00, '18 - 500 g pkgs.', 1),
(10, 'Ikura', 4, 31.00, '12 - 200 ml jars', 0),
(11, 'Queso Cabrales', 5, 21.00, '1 kg pkg.', 0),
(12, 'Queso Manchego La Pastora', 5, 38.00, '10 - 500 g pkgs.', 0),
(13, 'Konbu', 6, 6.00, '2 kg box', 0),
(14, 'Tofu', 6, 23.25, '40 - 100 g pkgs.', 0),
(15, 'Genen Shouyu', 6, 15.50, '24 - 250 ml bottles', 0),
(16, 'Pavlova', 7, 17.45, '32 - 500 g boxes', 0),
(17, 'Alice Mutton', 7, 39.00, '20 - 1 kg tins', 1),
(18, 'Carnarvon Tigers', 7, 62.50, '16 kg pkg.', 0),
(19, 'Teatime Chocolate Biscuits', 8, 9.20, '10 boxes x 12 pieces', 0),
(20, 'Sir Rodneys Marmalade', 8, 81.00, '30 gift boxes', 0),
(21, 'Sir Rodneys Scones', 8, 10.00, '24 pkgs. x 4 pieces', 0),
(22, 'Gustafs Knäckebröd', 9, 21.00, '24 - 500 g pkgs.', 0),
(23, 'Tunnbröd', 9, 9.00, '12 - 250 g pkgs.', 0),
(24, 'Guaraná Fantástica', 10, 4.50, '12 - 355 ml cans', 1),
(25, 'NuNuCa Nuß-Nougat-Creme', 11, 14.00, '20 - 450 g glasses', 0),
(26, 'Gumbär Gummibärchen', 11, 31.23, '100 - 250 g bags', 0),
(27, 'Schoggi Schokolade', 11, 43.90, '100 - 100 g pieces', 0),
(28, 'Rössle Sauerkraut', 12, 45.60, '25 - 825 g cans', 1),
(29, 'Thüringer Rostbratwurst', 12, 123.79, '50 bags x 30 sausgs.', 1),
(30, 'Nord-Ost Matjeshering', 13, 25.89, '10 - 200 g glasses', 0),
(31, 'Gorgonzola Telino', 14, 12.50, '12 - 100 g pkgs', 0),
(32, 'Mascarpone Fabioli', 14, 32.00, '24 - 200 g pkgs.', 0),
(33, 'Geitost', 15, 2.50, '500 g', 0),
(34, 'Sasquatch Ale', 16, 14.00, '24 - 12 oz bottles', 0),
(35, 'Steeleye Stout', 16, 18.00, '24 - 12 oz bottles', 0),
(36, 'Inlagd Sill', 17, 19.00, '24 - 250 g jars', 0),
(37, 'Gravad lax', 17, 26.00, '12 - 500 g pkgs.', 0),
(38, 'Côte de Blaye', 18, 263.50, '12 - 75 cl bottles', 0),
(39, 'Chartreuse verte', 18, 18.00, '750 cc per bottle', 0),
(40, 'Boston Crab Meat', 19, 18.40, '24 - 4 oz tins', 0),
(41, 'Jacks New England Clam Chowder', 19, 9.65, '12 - 12 oz cans', 0),
(42, 'Singaporean Hokkien Fried Mee', 20, 14.00, '32 - 1 kg pkgs.', 1),
(43, 'Ipoh Coffee', 20, 46.00, '16 - 500 g tins', 0),
(44, 'Gula Malacca', 20, 19.45, '20 - 2 kg bags', 0),
(45, 'Rogede sild', 21, 9.50, '1k pkg.', 0),
(46, 'Spegesild', 21, 12.00, '4 - 450 g glasses', 0),
(47, 'Zaanse koeken', 22, 9.50, '10 - 4 oz boxes', 0),
(48, 'Chocolade', 22, 12.75, '10 pkgs.', 0),
(49, 'Maxilaku', 23, 20.00, '24 - 50 g pkgs.', 0),
(50, 'Valkoinen suklaa', 23, 16.25, '12 - 100 g bars', 0),
(51, 'Manjimup Dried Apples', 24, 53.00, '50 - 300 g pkgs.', 0),
(52, 'Filo Mix', 24, 7.00, '16 - 2 kg boxes', 0),
(53, 'Perth Pasties', 24, 32.80, '48 pieces', 1),
(54, 'Tourtière', 25, 7.45, '16 pies', 0),
(55, 'Pâté chinois', 25, 24.00, '24 boxes x 2 pies', 0),
(56, 'Gnocchi di nonna Alice', 26, 38.00, '24 - 250 g pkgs.', 0),
(57, 'Ravioli Angelo', 26, 19.50, '24 - 250 g pkgs.', 0),
(58, 'Escargots de Bourgogne', 27, 13.25, '24 pieces', 0),
(59, 'Raclette Courdavault', 28, 55.00, '5 kg pkg.', 0),
(60, 'Camembert Pierrot', 28, 34.00, '15 - 300 g rounds', 0),
(61, 'Sirop érables', 29, 28.50, '24 - 500 ml bottles', 0),
(62, 'Tarte au sucre', 29, 49.30, '48 pies', 0),
(63, 'Vegie-spread', 7, 43.90, '15 - 625 g jars', 0),
(64, 'Wimmers gute Semmelknödel', 12, 33.25, '20 bags x 4 pieces', 0),
(65, 'Louisiana Fiery Hot Pepper Sauce', 2, 21.05, '32 - 8 oz bottles', 0),
(66, 'Louisiana Hot Spiced Okra', 2, 17.00, '24 - 8 oz jars', 0),
(67, 'Laughing Lumberjack Lager', 16, 14.00, '24 - 12 oz bottles', 0),
(68, 'Scottish Longbreads', 8, 12.50, '10 boxes x 8 pieces', 0),
(69, 'Gudbrandsdalsost', 15, 36.00, '10 kg pkg.', 0),
(70, 'Outback Lager', 7, 15.00, '24 - 355 ml bottles', 0),
(71, 'Flotemysost', 15, 21.50, '10 - 500 g pkgs.', 0),
(72, 'Mozzarella di Giovanni', 14, 34.80, '24 - 200 g pkgs.', 0),
(73, 'Röd Kaviar', 17, 15.00, '24 - 150 g jars', 0),
(74, 'Longlife Tofu', 4, 10.00, '5 kg pkg.', 0),
(75, 'Rhönbräu Klosterbier', 12, 7.75, '24 - 0.5 l bottles', 0),
(76, 'Lakkalikööri', 23, 18.00, '500 ml', 0),
(77, 'Original Frankfurter grüne Soße', 12, 13.00, '12 boxes', 0),
(78, 'Stroopwafels', 22, 9.75, '24 pieces', 0);


--------------------------------------------------------------------------------
-- PARTE 5: CARGA DE DADOS NA TABELA 'ORDER'
--------------------------------------------------------------------------------

INSERT INTO `order` (id, orderdate, customerid, totalamount, ordernumber) VALUES
(1, '2012-01-01', 78, 1863.40, '542379'),
(2, '2012-01-01', 78, 1863.40, '542379'),
(3, '2012-01-01', 34, 1813.00, '542380'),
(4, '2012-01-01', 84, 670.80, '542381'),
(5, '2012-01-02', 76, 3730.00, '542382'),
(6, '2012-01-03', 34, 1444.80, '542383'),
(7, '2012-01-04', 14, 625.20, '542384'),
(8, '2012-01-01', 68, 2490.50, '542385'),
(9, '2012-01-01', 88, 517.80, '542386'),
(10, '2012-01-03', 35, 1119.90, '542387'),
(11, '2012-01-04', 20, 2018.60, '542388'),
(12, '2012-01-04', 13, 100.80, '542389'),
(13, '2012-01-02', 56, 1746.20, '542390'),
(14, '2012-01-01', 61, 448.00, '542391'),
(15, '2012-01-01', 65, 624.80, '542392'),
(16, '2012-01-01', 20, 2464.80, '542393'),
(17, '2012-01-03', 24, 724.50, '542394'),
(18, '2012-01-07', 7, 1176.00, '542395'),
(19, '2021-01-01', 87, 364.80, '542396'),
(20, '2021-01-01', 25, 4031.00, '542397'),
(21, '2012-01-04', 33, 1101.20, '542398'),
(22, '2020-01-01', 89, 676.00, '542399'),
(23, '2012-01-02', 87, 1376.00, '542400'),
(24, '2012-01-02', 75, 48.00, '542401'),
(25, '2019-01-01', 65, 1456.00, '542402'),
(26, '2012-01-02', 63, 2142.40, '542403'),
(27, '2012-01-02', 85, 538.60, '542404');


--------------------------------------------------------------------------------
-- PARTE 6: CARGA DE DADOS NA TABELA 'ORDERITEM'
--------------------------------------------------------------------------------

INSERT INTO orderitem (id, orderid, productid, unitprice, quantity) VALUES
(1, 1, 11, 14.00, 12),
(2, 1, 42, 9.80, 10),
(3, 1, 72, 34.80, 5),
(4, 2, 14, 18.60, 9),
(5, 2, 51, 42.40, 40),
(6, 3, 41, 7.70, 10),
(7, 3, 51, 42.40, 35),
(8, 3, 65, 16.80, 15),
(9, 4, 22, 16.80, 6),
(10, 4, 57, 15.60, 15),
(11, 4, 65, 16.80, 20),
(12, 5, 20, 64.80, 40),
(13, 5, 33, 2.00, 25),
(14, 5, 60, 27.20, 40),
(15, 6, 31, 10.00, 20),
(16, 6, 39, 14.40, 42),
(17, 6, 49, 16.00, 40),
(18, 7, 24, 3.60, 15),
(19, 7, 55, 19.20, 21),
(20, 7, 74, 8.00, 21),
(21, 8, 2, 15.20, 20),
(22, 8, 16, 13.90, 35),
(23, 8, 36, 15.20, 25),
(24, 8, 59, 44.00, 30),
(25, 9, 53, 26.20, 15),
(26, 9, 77, 10.40, 12),
(27, 10, 27, 35.10, 25),
(28, 10, 39, 14.40, 6),
(29, 10, 77, 10.40, 15),
(30, 11, 2, 15.20, 50),
(31, 11, 5, 17.00, 65),
(32, 11, 32, 25.60, 6),
(33, 12, 21, 8.00, 10),
(34, 12, 37, 20.80, 1),
(35, 13, 41, 7.70, 16),
(36, 13, 57, 15.60, 50),
(37, 13, 62, 39.40, 15),
(38, 13, 70, 12.00, 21),
(39, 14, 21, 8.00, 20),
(40, 14, 35, 14.40, 20),
(41, 15, 5, 17.00, 12),
(42, 15, 7, 24.00, 15),
(43, 15, 56, 30.40, 2),
(44, 16, 16, 13.90, 60),
(45, 16, 24, 3.60, 28),
(46, 16, 30, 20.70, 60),
(47, 16, 74, 8.00, 36),
(48, 17, 2, 15.20, 35),
(49, 17, 41, 7.70, 25),
(50, 18, 17, 31.20, 30),
(51, 18, 70, 12.00, 20),
(52, 19, 12, 30.40, 12),
(53, 20, 40, 14.70, 50),
(54, 20, 59, 44.00, 70),
(55, 20, 76, 14.40, 15),
(56, 21, 29, 99.00, 10),
(57, 21, 72, 27.80, 4),
(58, 22, 33, 2.00, 60),
(59, 22, 72, 27.80, 20),
(60, 23, 36, 15.20, 30),
(61, 23, 43, 36.80, 25),
(62, 24, 33, 2.00, 24),
(63, 25, 20, 64.80, 6),
(64, 25, 31, 10.00, 40),
(65, 25, 72, 27.80, 24),
(66, 26, 10, 24.80, 24),
(67, 26, 31, 10.00, 15),
(68, 26, 33, 2.00, 20),
(69, 26, 40, 14.70, 60);


--------------------------------------------------------------------------------
-- PARTE 7: AUDITORIA E VALIDAÇÃO DA CARGA
--------------------------------------------------------------------------------

-- Verificar contagem total de registros inseridos por tabela
SELECT 'customer' AS tabela, COUNT(*) AS total FROM customer
UNION ALL
SELECT 'supplier', COUNT(*) FROM supplier
UNION ALL
SELECT 'product', COUNT(*) FROM product
UNION ALL
SELECT 'order', COUNT(*) FROM `order`
UNION ALL
SELECT 'orderitem', COUNT(*) FROM orderitem;


--------------------------------------------------------------------------------
-- PARTE 8: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

/*
-- Descomentar o bloco abaixo para limpar os registros populados:

USE arley_cliente2;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE orderitem;
TRUNCATE TABLE `order`;
TRUNCATE TABLE product;
TRUNCATE TABLE supplier;
TRUNCATE TABLE customer;
SET FOREIGN_KEY_CHECKS = 1;
*/