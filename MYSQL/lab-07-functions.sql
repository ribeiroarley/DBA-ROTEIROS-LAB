/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-07-functions.sql
  Objetivo     : Criacao de funcoes escalares personalizadas (UDF)
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/

USE teste;

DELIMITER //

DROP FUNCTION IF EXISTS fn_calcular_desconto //

CREATE FUNCTION fn_calcular_desconto(p_valor DECIMAL(10,2), p_percentual DECIMAL(5,2)) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_resultado DECIMAL(10,2);
    SET v_resultado = p_valor - (p_valor * (p_percentual / 100));
    RETURN v_resultado;
END //

DELIMITER ;

-- Consulta de teste
-- SELECT fn_calcular_desconto(100.00, 10.00) as valor_com_desconto;

-- CLEANUP
DROP FUNCTION IF EXISTS fn_calcular_desconto;
-- DROP DATABASE IF EXISTS teste;
