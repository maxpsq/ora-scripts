# Cursor sharing

As Oracle developers, we've always been told to use bind variables avoiding the use of literals values in the SQL statements we code.

To get when variable binding comes to the rescue, we need to understand how a SQL statement is processed when issued to the database by an application.

## 1. Understanding SQL processing phases
I put down a brief recap of the phases that make up a SQL statement processing.
* SQL parsing
  1. syntax check
  2. semantic check
  3. <u>shared pool check</u>
* <u>SQL optimization</u>
* <u>SQL row source generation</u>
* SQL execution

I'm not delving into the details of each single phase, but I strongly suggest you to have a read at  [Oracle 12c Release 1 SQL processing](https://docs.oracle.com/database/121/TGSQL/tgsql_sqlproc.htm#TGSQL175) documentation.

For the sake of this article, we're exploring the <u>shared pool check</u> phase.

### 1.1. The shared pool check phase
Generally speaking about software, optimization may consists in many aspects, one of which is avoiding the repetition of intensive computational tasks. That may be achieved by caching tasks results for future reuse.

The <i>shared pool check</i> phase is itself the attempt to skip resource-intensive tasks.

When a SQL statement is submitted, Oracle assigns an ID using a hashing algorithm (`v$sql.sql_id`) on the statement text so that all identical SQL statements share the same SQL_ID.
When the SQL_ID is not found in the <i>shared SQL area</i> then a <i>hard parse</i> will take place: the <i>SQL optimizer</i> will evaluate the <i>execution plans</i> in order to find the one providing the best access to data. Then, the <i>row source generator</i> will get the best <i>execution plan</i> in order to produce the <i>query plan</i>.
The SQL_ID will be then stored together with the <i>execution plans</i> and the <i>query plan</i> within the <i>shared SQL area</i> (the definition "cursor sharing" comes after the goal to maximize the utilization of the <i>shared SQL area</i>).

When a subsequent submission of a previously submitted SQL is issued, will then be possible to perform a <i>soft parse</i> that consists essentially in reusing the <i>execution plan</i> produced by the previous <i>hard parse</i> of the same SQL statement, just looking-up the <i>shared SQL area</i> for the data associated to the same SQL_ID.

========== approfondire ===========
https://ora600tom.wordpress.com/tag/session-cached-cursor/
Hard Parse: Parsing first time, nothing exists to bind peek
Soft Parse :  SQL cursor is existing and executing not the first time.  Under the soft parse, bind peeking will happen and the new  plan will be generated based on the selectivity for that literal.
Session Cached cursor (Softer Soft Parse):   Cursor is existing in the PGA, bind the new value and just execute.  This is the optimal way of an SQL execution – parse once and execute many.  Less CPU, less or no latches – just bind and execute.
=============

### 1.2. How variable binding affects the generation of the SQL_ID
As previously said, the SQL_ID generation is demanded to a hashing algorithm that takes as input the SQL statement text.

Issuing this simple statements
```
begin
  Select last_name from employees where employee_id = 5;
  Select last_name from employees where employee_id = 6;
  Select last_name from employees where employee_id = 7;
end;
```
we'll find this entries in the `v$sql` view
```
```
For each SQL text, was produced a specific SQL_ID. This indicates that a <i>hard parse</i> took place for each one of the statements we submitted.

Let's see how things are changing when we avoid to hard code literals in favor of <i>variable binding</i>
```
declare
  v_cur  sys_refcursor;
  v_stm  varchar2(200 char);
begin
  v_stmt := 'Select last_name
               from employees
              where employee_id = :id';
  for i in 12 .. 14 loop
    open v_cur for v_stmt using i;
    close v_cur;
  end loop;
end;
```
Querying the `v$sql` view, we'll find out we have just one entry for the sql statement. That means that only one <i>hard parse</i> took place at the first loop iteration while <i>soft parsing</i> took place for all subsequent iterations.

### 1.3. Aspects under which cursor sharing improves performance
The activities needed to hard parse a statement and generate an execution plan are CPU intensive and generate recursive SQL against the data dictionary which may result in physical I/O as well. The access to the <i>library cache</i> and <i>data dictionary cache</i>, uses a serialization device called a <i>latch</i> so that their definition does not change during the check. A latch protects shared data structures in the SGA from simultaneous access creating contention among resources that increases SQL execution time.
Furthermore, the statements and parse tree (an internal structure, created by the SQL interpreter while parsing) take up space in the <i>shared pool</i>, a RAM area that is part of the System Global Area (SGA).
Maximizing cursor sharing can thus benefit CPU, I/O and RAM consumption reducing the need of resources.

## 2. Maximize the use of cursor sharing
If you've read up to this point in this article, you should have guessed that in order to benefit of cursor sharing, you must adopt <i>variable binding</i> as a standard to which bind SQL coding since now on. Furthermore, you're likely thinking to the lot of lines of legacy code you have in your application that need to be refactored. We're now exploring some features in the Oracle database that come to help in approaching this demanding task.

### 2.1 Changing cursor sharing default settings
Oracle provides a `cursor_sharing` parameter that can force the use of cursor sharing for equivalent SQL statements.

The `cursor_sharing` parameter may be set to
  - EXACT (default)
  - SIMILAR (removed in 12c)
  - FORCE

When forcing cursor sharing, the SQL statements issued to the database will be rewritten, by:
- substituting literals with bind variables
- uppercasing non literal values ?????
- normalizing white spaces ????????

so that we can get the same SQL_ID from SQL statements wit different text but that are equivalent.

ADD EXAMPLES HERE
CHECK https://docs.oracle.com/database/121/TGSQL/tgsql_cursor.htm#TGSQL-GUID-5154DB60-EB3C-41EF-AF32-226FC54BDA75

ALSO READ ABOUT ADAPTIVE CURSOR SHARING
https://oracle-base.com/articles/11g/adaptive-cursor-sharing-11gr1

	
Setting `cursor_sharing` to `FORCE` is not meant to be a permanent solution because of the following drawbacks:

- It indicates that the application does not use user-defined bind variables, which means that it is open to SQL injection.
- Setting CURSOR_SHARING to FORCE does not fix SQL injection bugs because the database binds values only after any malicious SQL text has already been injected.
- The database must perform extra work during the soft parse to find a similar statement in the shared pool.
- The database removes every literal, which means that it can remove useful information. For example, the database strips out literal values in SUBSTR and TO_DATE functions. The use of system-generated bind variables where literals are more optimal can have a negative impact on execution plans.
- Star transformation is not supported.

For the aforementioned reasons, forcing cursor sharing is meant to be a temporary solution that can improve the performance of your application while refactoring SQL statements to use <i>variable bindings</i>.

### 2.2 The quest for literal SQLs
http://intermediatesql.com/oracle/a-better-way-to-find-literal-sqls-in-oracle-10g/


### 2.3 Bind Peeking
https://ora600tom.wordpress.com/tag/session-cached-cursor/

