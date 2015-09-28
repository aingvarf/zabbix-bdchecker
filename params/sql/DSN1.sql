# The name of this file should be the same as DSN name in databases.yml

TEST: select 1 from dual

# multiline sql
SYSDATE: !
  select sysdate
  from dual
