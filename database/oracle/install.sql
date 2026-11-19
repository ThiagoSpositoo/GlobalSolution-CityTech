WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET DEFINE OFF

@@01-schema.sql
@@02-seed.sql
@@03-blocks.sql
@@04-packages.sql
@@05-triggers.sql

PROMPT Instalacao Oracle CityTech concluida.
