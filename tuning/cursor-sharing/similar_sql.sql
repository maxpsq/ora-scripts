
/**
It turns out that ORACLE 10g introduced a couple of new columns in v$sql view
(as well as some related views) that can help pinpoint literal SQLs more precisely.
The two new columns are: force_matching_signature and exact_matching_signature.

The same value in exact_matching_signature column marks SQLs that ORACLE considers
the same after making some cosmetic adjustments to it (removing white space,
uppercasing all keywords etc). As the name implies, this is what happens when
parameter cursor_sharing is set to EXACT.

Consequently, the same value in force_matching_signature (excluding 0)
marks SQLs that ORACLE will consider the same when it replaces all literals
with binds (that is, if cursor_sharing=FORCE).

Obviously, if we have multiple SQLs that produce the same force_matching_signature
we have a strong case for literal laden SQL that needs to undergo our further scrutiny.
Of course, we need to remember to filter out SQLs
where force_matching_signature = exact_matching_signature as these do NOT have
any literals (however, if we have many of those – this can become interesting
as well – why do we have many versions of the same “non literal” SQL ?)
*/
SELECT sql.force_matching_signature, COUNT(1)
  FROM v$sql sql
 WHERE sql.force_matching_signature > 0
   AND sql.force_matching_signature <> sql.exact_matching_signature
 GROUP BY sql.force_matching_signature
 HAVING COUNT(1) > 10
 ORDER BY COUNT(1) DESC
/
