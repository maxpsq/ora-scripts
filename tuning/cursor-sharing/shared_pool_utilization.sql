ttitle 'Shared Pool Utilization'
spool sql_garbage
select 1 nopr,
to_char(a.inst_id) inst_id,
a.users users,
to_char(a.garbage,'9,999,999,999') garbage,
to_char(b.good,'9,999,999,999') good,
to_char((b.good/(b.good+a.garbage))*100,'9,999,999.999') good_percent
from (select
  a.inst_id,
  b.username users,
  sum(a.sharable_mem+a.persistent_mem) Garbage,
  to_number(null) good
from
   sys.gv_$sqlarea a,
   dba_users b
where
  see code depot for full script
  (a.parsing_user_id = b.user_id and a.executions<=1)
group by a.inst_id, b.username
union
select distinct
  c.inst_id,
  b.username users,
  to_number(null) garbage,
  sum(c.sharable_mem+c.persistent_mem) Good
from
   dba_users b,
   sys.gv_$sqlarea c
where
  (b.user_id=c.parsing_user_id and c.executions>1)
group by c.inst_id, b.username
) a, (select
  a.inst_id,
  b.username users,
  sum(a.sharable_mem+a.persistent_mem) Garbage,
  to_number(null) good
from
   sys.gv_$sqlarea a,
   dba_users b
where
  (a.parsing_user_id = b.user_id and a.executions<=1)
group by a.inst_id,b.username
union
select distinct
  c.inst_id,
  b.username users,
  to_number(null) garbage,
  sum(c.sharable_mem+c.persistent_mem) Good
from
   dba_users b,
   sys.gv_$sqlarea c
where
  (b.user_id=c.parsing_user_id and c.executions>1)
group by c.inst_id, b.username
) b
where a.users=b.users
and a.inst_id=b.inst_id
and a.garbage is not null and b.good is not null
union
select 2 nopr,
'-------' inst_id,'-------------' users,'--------------' garbage,'--------------' good,
'--------------' good_percent from dual
union
select 3 nopr,
to_char(a.inst_id,'999999'),
to_char(count(a.users)) users,
to_char(sum(a.garbage),'9,999,999,999') garbage,
to_char(sum(b.good),'9,999,999,999') good,
to_char(((sum(b.good)/(sum(b.good)+sum(a.garbage)))*100),'9,999,999.999') good_percent
from (select
  a.inst_id,
  b.username users,
  sum(a.sharable_mem+a.persistent_mem) Garbage,
  to_number(null) good
from
   sys.gv_$sqlarea a,
   dba_users b
where
  (a.parsing_user_id = b.user_id and a.executions<=1)
group by a.inst_id,b.username
union
select distinct
  c.inst_id,
  b.username users,
  to_number(null) garbage,
  sum(c.sharable_mem+c.persistent_mem) Good
from
   dba_users b,
   sys.gv_$sqlarea c
where
  (b.user_id=c.parsing_user_id and c.executions>1)
group by c.inst_id,b.username
) a, (select
  a.inst_id,
  b.username users,
  sum(a.sharable_mem+a.persistent_mem) Garbage,
  to_number(null) good
from
   sys.gv_$sqlarea a,
   dba_users b
where
  (a.parsing_user_id = b.user_id and a.executions<=1)
group by a.inst_id,b.username
union
select distinct
  c.inst_id,
  b.username users,
  to_number(null) garbage,
  sum(c.sharable_mem+c.persistent_mem) Good
from
   dba_users b,
   sys.gv_$sqlarea c
where
  (b.user_id=c.parsing_user_id and c.executions>1)
group by c.inst_id, b.username
) b
where a.users=b.users
and a.inst_id=b.inst_id
and a.garbage is not null and b.good is not null
group by a.inst_id
order by 1,2 desc
/
spool off
ttitle off
set pages 22
