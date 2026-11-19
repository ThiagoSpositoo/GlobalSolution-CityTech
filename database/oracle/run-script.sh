#!/usr/bin/env bash

script_name="${1:-06-tests.sql}"
case "$script_name" in
    01-schema.sql|02-seed.sql|03-blocks.sql|04-packages.sql|05-triggers.sql|06-tests.sql|07-reports.sql|install.sql)
        ;;
    *)
        echo "Script Oracle nao permitido: $script_name" >&2
        exit 2
        ;;
esac

sqlplus -s /nolog <<SQL
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
CONNECT ${APP_USER}/"${APP_USER_PASSWORD}"@//localhost:1521/XEPDB1
@/opt/citytech/oracle/${script_name}
EXIT SUCCESS
SQL
