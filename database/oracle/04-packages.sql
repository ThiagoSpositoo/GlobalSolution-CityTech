WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET DEFINE OFF

CREATE OR REPLACE PACKAGE pkg_citytech_reports AS
    FUNCTION fn_occurrence_count(p_status IN VARCHAR2 DEFAULT NULL) RETURN NUMBER;

    PROCEDURE pr_category_summary(
        p_category_id IN RAW,
        p_total OUT NUMBER,
        p_active OUT NUMBER
    );
END pkg_citytech_reports;
/

CREATE OR REPLACE PACKAGE BODY pkg_citytech_reports AS
    FUNCTION fn_occurrence_count(p_status IN VARCHAR2 DEFAULT NULL) RETURN NUMBER IS
        v_total NUMBER;
        v_status VARCHAR2(20 CHAR) := UPPER(TRIM(p_status));
    BEGIN
        IF p_status IS NOT NULL AND v_status NOT IN (
            'ABERTA', 'EM_TRIAGEM', 'EM_ANDAMENTO', 'RESOLVIDA', 'ENCERRADA', 'CANCELADA'
        ) THEN
            RAISE_APPLICATION_ERROR(-20020, 'Status de ocorrencia invalido.');
        END IF;

        SELECT COUNT(*)
          INTO v_total
          FROM occurrences
         WHERE p_status IS NULL OR status = v_status;

        RETURN v_total;
    END fn_occurrence_count;

    PROCEDURE pr_category_summary(
        p_category_id IN RAW,
        p_total OUT NUMBER,
        p_active OUT NUMBER
    ) IS
        v_category_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_category_count FROM categories WHERE id = p_category_id;
        IF v_category_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20021, 'Categoria nao encontrada.');
        END IF;

        SELECT COUNT(*),
               NVL(SUM(CASE WHEN status IN ('ABERTA', 'EM_TRIAGEM', 'EM_ANDAMENTO') THEN 1 ELSE 0 END), 0)
          INTO p_total, p_active
          FROM occurrences
         WHERE category_id = p_category_id;
    END pr_category_summary;
END pkg_citytech_reports;
/

CREATE OR REPLACE PACKAGE pkg_citytech_operations AS
    FUNCTION fn_pending_outbox RETURN NUMBER;

    PROCEDURE pr_outbox_summary(
        p_pending OUT NUMBER,
        p_failed OUT NUMBER,
        p_oldest_pending OUT TIMESTAMP WITH TIME ZONE
    );
END pkg_citytech_operations;
/

CREATE OR REPLACE PACKAGE BODY pkg_citytech_operations AS
    FUNCTION fn_pending_outbox RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total FROM outbox_events WHERE published_at IS NULL;
        RETURN v_total;
    END fn_pending_outbox;

    PROCEDURE pr_outbox_summary(
        p_pending OUT NUMBER,
        p_failed OUT NUMBER,
        p_oldest_pending OUT TIMESTAMP WITH TIME ZONE
    ) IS
    BEGIN
        SELECT COUNT(*),
               NVL(SUM(CASE WHEN last_error IS NOT NULL THEN 1 ELSE 0 END), 0),
               MIN(occurred_at)
          INTO p_pending, p_failed, p_oldest_pending
          FROM outbox_events
         WHERE published_at IS NULL;
    END pr_outbox_summary;
END pkg_citytech_operations;
/

PROMPT Dois packages, duas funcoes e dois procedimentos compilados.
