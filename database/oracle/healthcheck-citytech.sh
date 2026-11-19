#!/usr/bin/env bash

sqlplus -s /nolog >/dev/null <<SQL
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
CONNECT ${APP_USER}/"${APP_USER_PASSWORD}"@//localhost:1521/XEPDB1
DECLARE
    v_categories NUMBER;
    v_objects NUMBER;
    v_invalid NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_categories FROM categories;
    SELECT COUNT(*)
      INTO v_objects
      FROM user_objects
     WHERE object_name IN (
        'PKG_CITYTECH_REPORTS', 'PKG_CITYTECH_OPERATIONS',
        'TRG_OCCURRENCES_AUDIT', 'TRG_HISTORY_APPEND_ONLY'
     )
       AND object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER');
    SELECT COUNT(*)
      INTO v_invalid
      FROM user_objects
     WHERE object_name IN (
        'PKG_CITYTECH_REPORTS', 'PKG_CITYTECH_OPERATIONS',
        'TRG_OCCURRENCES_AUDIT', 'TRG_HISTORY_APPEND_ONLY'
     )
       AND status <> 'VALID';
    IF v_categories < 6 OR v_objects <> 6 OR v_invalid > 0 THEN
        RAISE_APPLICATION_ERROR(-20099, 'Schema CityTech ainda nao esta pronto.');
    END IF;
END;
/
EXIT SUCCESS
SQL
