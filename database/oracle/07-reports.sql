WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET PAGESIZE 100
SET LINESIZE 180
SET FEEDBACK ON
SET DEFINE OFF

COLUMN category_code FORMAT A16
COLUMN category_name FORMAT A24
COLUMN status FORMAT A16
COLUMN priority FORMAT A10

PROMPT Relatorio 1 - ocorrencias por categoria
SELECT c.code AS category_code,
       c.name AS category_name,
       COUNT(o.id) AS occurrence_count
  FROM categories c
  LEFT JOIN occurrences o ON o.category_id = c.id
 GROUP BY c.code, c.name
 ORDER BY c.code;

PROMPT Relatorio 2 - fila nao terminal por prioridade
SELECT priority,
       COUNT(*) AS occurrence_count
  FROM occurrences
 WHERE status NOT IN ('ENCERRADA', 'CANCELADA')
 GROUP BY priority
 ORDER BY CASE priority
              WHEN 'CRITICA' THEN 1
              WHEN 'ALTA' THEN 2
              WHEN 'MEDIA' THEN 3
              WHEN 'BAIXA' THEN 4
          END;

PROMPT Relatorio 3 - categoria e status
SELECT c.code AS category_code,
       o.status,
       COUNT(*) AS occurrence_count
  FROM occurrences o
  JOIN categories c ON c.id = o.category_id
 GROUP BY c.code, o.status
 ORDER BY c.code, o.status;
