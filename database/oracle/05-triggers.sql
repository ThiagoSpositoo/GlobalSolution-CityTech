WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET DEFINE OFF

CREATE OR REPLACE TRIGGER trg_occurrences_audit
AFTER UPDATE OF category_id, priority, status, version OR DELETE ON occurrences
FOR EACH ROW
BEGIN
    IF DELETING THEN
        INSERT INTO occurrence_audit (
            id, occurrence_id, operation,
            old_category_id, new_category_id,
            old_priority, new_priority,
            old_status, new_status,
            old_version, new_version,
            changed_at, changed_by
        ) VALUES (
            seq_occurrence_audit.NEXTVAL, :OLD.id, 'DELETE',
            :OLD.category_id, NULL, :OLD.priority, NULL,
            :OLD.status, NULL, :OLD.version, NULL,
            SYSTIMESTAMP, SYS_CONTEXT('USERENV', 'SESSION_USER')
        );
    ELSE
        INSERT INTO occurrence_audit (
            id, occurrence_id, operation,
            old_category_id, new_category_id,
            old_priority, new_priority,
            old_status, new_status,
            old_version, new_version,
            changed_at, changed_by
        ) VALUES (
            seq_occurrence_audit.NEXTVAL, :OLD.id, 'UPDATE',
            :OLD.category_id, :NEW.category_id, :OLD.priority, :NEW.priority,
            :OLD.status, :NEW.status, :OLD.version, :NEW.version,
            SYSTIMESTAMP, SYS_CONTEXT('USERENV', 'SESSION_USER')
        );
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_history_append_only
BEFORE UPDATE OR DELETE ON status_history
BEGIN
    RAISE_APPLICATION_ERROR(
        -20010,
        'status_history e append-only; registre um novo evento em vez de alterar o existente.'
    );
END;
/

DECLARE
    v_invalid NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_invalid
      FROM user_objects
     WHERE object_name IN ('TRG_OCCURRENCES_AUDIT', 'TRG_HISTORY_APPEND_ONLY')
       AND status <> 'VALID';
    IF v_invalid > 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Um ou mais triggers estao invalidos.');
    END IF;
END;
/

PROMPT Trigger de auditoria e protecao append-only compilados.
