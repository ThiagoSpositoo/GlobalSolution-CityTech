WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

DECLARE
    v_count NUMBER;
    v_before NUMBER;
    v_total NUMBER;
    v_active NUMBER;
    v_pending NUMBER;
    v_failed NUMBER;
    v_oldest TIMESTAMP WITH TIME ZONE;
    v_expected_error BOOLEAN := FALSE;

    PROCEDURE assert_number(p_label VARCHAR2, p_expected NUMBER, p_actual NUMBER) IS
    BEGIN
        IF p_expected <> p_actual THEN
            RAISE_APPLICATION_ERROR(
                -20900,
                p_label || ': esperado=' || p_expected || ', obtido=' || p_actual
            );
        END IF;
        DBMS_OUTPUT.PUT_LINE('OK - ' || p_label || ': ' || p_actual);
    END;
BEGIN
    SELECT COUNT(*) INTO v_count FROM categories;
    assert_number('categorias da amostra', 6, v_count);

    SELECT COUNT(*) INTO v_count FROM occurrences;
    assert_number('ocorrencias da amostra', 12, v_count);

    assert_number('funcao total de ocorrencias', 12, pkg_citytech_reports.fn_occurrence_count());
    assert_number('funcao ocorrencias abertas', 3, pkg_citytech_reports.fn_occurrence_count('ABERTA'));

    pkg_citytech_reports.pr_category_summary(
        HEXTORAW('11111111111111111111111111111111'), v_total, v_active
    );
    assert_number('procedure total da categoria VIAS', 2, v_total);
    assert_number('procedure ativas da categoria VIAS', 2, v_active);

    assert_number('funcao outbox pendente', 1, pkg_citytech_operations.fn_pending_outbox());
    pkg_citytech_operations.pr_outbox_summary(v_pending, v_failed, v_oldest);
    assert_number('procedure outbox pendente', 1, v_pending);
    assert_number('procedure outbox com erro', 0, v_failed);
    IF v_oldest IS NULL THEN
        RAISE_APPLICATION_ERROR(-20901, 'Data da outbox pendente nao retornada.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('OK - procedure retornou a data da outbox mais antiga.');

    SAVEPOINT before_audit_test;
    SELECT COUNT(*) INTO v_before
      FROM occurrence_audit
     WHERE occurrence_id = HEXTORAW('A0000000000000000000000000000001');

    UPDATE occurrences
       SET priority = 'ALTA', version = version + 1
     WHERE id = HEXTORAW('A0000000000000000000000000000001');

    SELECT COUNT(*) INTO v_count
      FROM occurrence_audit
     WHERE occurrence_id = HEXTORAW('A0000000000000000000000000000001');
    assert_number('trigger de auditoria', 1, v_count - v_before);
    ROLLBACK TO before_audit_test;

    BEGIN
        UPDATE status_history
           SET note = 'alteracao proibida'
         WHERE id = HEXTORAW('B0000000000000000000000000000001');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20010 THEN
                v_expected_error := TRUE;
                DBMS_OUTPUT.PUT_LINE('OK - trigger append-only rejeitou UPDATE.');
            ELSE
                RAISE;
            END IF;
    END;
    IF NOT v_expected_error THEN
        RAISE_APPLICATION_ERROR(-20902, 'Trigger append-only nao rejeitou UPDATE.');
    END IF;

    v_expected_error := FALSE;
    BEGIN
        INSERT INTO categories (
            id, code, name, active, created_at, updated_at
        ) VALUES (
            HEXTORAW('99999999999999999999999999999999'), 'INVALIDA', 'Invalida', 2,
            SYSTIMESTAMP, SYSTIMESTAMP
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -2290 THEN
                v_expected_error := TRUE;
                DBMS_OUTPUT.PUT_LINE('OK - check de boolean rejeitou active=2.');
            ELSE
                RAISE;
            END IF;
    END;
    IF NOT v_expected_error THEN
        RAISE_APPLICATION_ERROR(-20903, 'Check de categories.active nao foi aplicado.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('TODOS OS TESTES ORACLE PASSARAM.');
    ROLLBACK;
END;
/

SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN (
    'PKG_CITYTECH_REPORTS', 'PKG_CITYTECH_OPERATIONS',
    'TRG_OCCURRENCES_AUDIT', 'TRG_HISTORY_APPEND_ONLY'
 )
 ORDER BY object_type, object_name;
