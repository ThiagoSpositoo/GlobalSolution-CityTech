#!/usr/bin/env bash

# Executado apenas na primeira inicializacao do volume pelo container Oracle.
sqlplus -s /nolog <<SQL
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
CONNECT ${APP_USER}/"${APP_USER_PASSWORD}"@//localhost:1521/XEPDB1
@/opt/citytech/oracle/install.sql
EXIT SUCCESS
SQL
