# The name of this file should be the same as DSN name in databases.yml

# Symbols ? are placeholders for parameters, which are applied according there order in request
# For example:
#   name='param'  => name=?
#   name=param    => name=? 
#   name in ('par1','par2') => name in (?)

TEST: select 1 from dual

# multiline sql
SYSDATE: !
  select sysdate - ?
  from dual
