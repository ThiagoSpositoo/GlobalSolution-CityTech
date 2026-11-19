WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Bloco 1: decisao sobre ocorrencias criticas em aberto
DECLARE
    v_critical_open NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_critical_open
      FROM occurrences
     WHERE priority = 'CRITICA'
       AND status NOT IN ('ENCERRADA', 'CANCELADA');

    IF v_critical_open = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Sem ocorrencias criticas pendentes.');
    ELSIF v_critical_open <= 2 THEN
        DBMS_OUTPUT.PUT_LINE('Atencao: ' || v_critical_open || ' ocorrencia(s) critica(s) pendente(s).');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ALERTA: fila critica acima do limite: ' || v_critical_open);
    END IF;
END;
/

PROMPT Bloco 2: cursor e repeticao por categoria
DECLARE
    CURSOR c_category_summary IS
        SELECT c.code,
               COUNT(o.id) total,
               SUM(CASE WHEN o.status IN ('ABERTA', 'EM_TRIAGEM', 'EM_ANDAMENTO') THEN 1 ELSE 0 END) active_total
          FROM categories c
          LEFT JOIN occurrences o ON o.category_id = c.id
         GROUP BY c.code
         ORDER BY c.code;
BEGIN
    FOR item IN c_category_summary LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(item.code, 16) || ' total=' || item.total || ' ativas=' || item.active_total
        );
    END LOOP;
END;
/
