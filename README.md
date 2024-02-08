# pg_variables - session variables with various types

[![Build Status](https://travis-ci.com/postgrespro/pg_variables.svg?branch=master)](https://travis-ci.com/postgrespro/pg_variables)
[![codecov](https://codecov.io/gh/postgrespro/pg_variables/branch/master/graph/badge.svg)](https://codecov.io/gh/postgrespro/pg_variables)
[![GitHub license](https://img.shields.io/badge/license-PostgreSQL-blue.svg)](https://raw.githubusercontent.com/postgrespro/pg_variables/master/README.md)

## Introduction

The **pg_variables** module provides functions to work with variables of various
types. Created variables live only in the current user session.
By default, created variables are not transactional (i.e. they are not affected
by `BEGIN`, `COMMIT` or `ROLLBACK` statements). This, however, is customizable
by argument `is_transactional` of `pgv_set()`:
```sql
SELECT pgv_set('vars', 'int1', 101);
BEGIN;
SELECT pgv_set('vars', 'int2', 102);
ROLLBACK;

SELECT * FROM pgv_list() order by package, name;
 package | name | is_transactional
---------+------+------------------
 vars    | int1 | f
 vars    | int2 | f
```

But if variable created with flag **is_transactional**:
```sql
BEGIN;
SELECT pgv_set('vars', 'trans_int', 101, true);
SAVEPOINT sp1;
SELECT pgv_set('vars', 'trans_int', 102, true);
ROLLBACK TO sp1;
COMMIT;
SELECT pgv_get('vars', 'trans_int', NULL::int);
 pgv_get
---------
     101
```

You can aggregate variables into packages. This is done to be able to have
variables with different names or to quickly remove the whole batch of
variables. If the package becomes empty, it is automatically deleted.

## License

This module available under the [license](LICENSE) similar to
[PostgreSQL](http://www.postgresql.org/about/licence/).

## Installation

Typical installation procedure may look like this:

    $ cd pg_variables
    $ make USE_PGXS=1
    $ sudo make USE_PGXS=1 install
    $ make USE_PGXS=1 installcheck
    $ psql DB -c "CREATE EXTENSION pg_variables;"

## Module functions

The functions provided by the **pg_variables** module are shown in the tables
below.

To use **pgv_get()** function required package and variable must exists. It is
necessary to set variable with **pgv_set()** function to use **pgv_get()**
function.

If a package does not exists you will get the following error:

```sql
SELECT pgv_get('vars', 'int1', NULL::int);
ERROR:  unrecognized package "vars"
```

If a variable does not exists you will get the following error:

```sql
SELECT pgv_get('vars', 'int1', NULL::int);
ERROR:  unrecognized variable "int1"
```

**pgv_get()** function check the variable type. If the variable type does not
match with the function type the error will be raised:

```sql
SELECT pgv_get('vars', 'int1', NULL::text);
ERROR:  variable "int1" requires "integer" value
```

## Scalar variables functions

Function | Returns
-------- | -------
`pgv_set(package text, name text, value anynonarray, is_transactional bool default false)` | `void`
`pgv_get(package text, name text, var_type anynonarray, strict bool default true)` | `anynonarray`

## Array variables functions

Function | Returns
-------- | -------
`pgv_set(package text, name text, value anyarray, is_transactional bool default false)` | `void`
`pgv_get(package text, name text, var_type anyarray, strict bool default true)` | `anyarray`

`pgv_set` arguments:
- `package` - name of the package, it will be created if it doesn't exist.
- `name` - name of the variable, it will be created if it doesn't exist.
`pgv_set` fails if the variable already exists and its transactionality doesn't
match `is_transactional` argument.
- `value` - new value for the variable. `pgv_set` fails if the variable already
exists and its type doesn't match new value's type.
- `is_transactional` - transactionality of the newly created variable, by
default it is false.

`pgv_get` arguments:
- `package` - name of the existing package. If the package doesn't exist result
depends on `strict` argument: if it is false then `pgv_get` returns NULL
otherwise it fails.
- `name` - name of the the existing variable. If the variable doesn't exist
result depends on `strict` argument: if it is false then `pgv_get` returns NULL
otherwise it fails.
- `var_type` - type of the existing variable. It is necessary to pass it to get
correct return type.
- `strict` - pass false if `pgv_get` shouldn't raise an error if a variable or a
package didn't created before, by default it is true.

## **Deprecated** scalar variables functions

### Integer variables

Function | Returns
-------- | -------
`pgv_set_int(package text, name text, value int, is_transactional bool default false)` | `void`
`pgv_get_int(package text, name text, strict bool default true)` | `int`

### Text variables

Function | Returns
-------- | -------
`pgv_set_text(package text, name text, value text, is_transactional bool default false)` | `void`
`pgv_get_text(package text, name text, strict bool default true)` | `text`

### Numeric variables

Function | Returns
-------- | -------
`pgv_set_numeric(package text, name text, value numeric, is_transactional bool default false)` | `void`
`pgv_get_numeric(package text, name text, strict bool default true)` | `numeric`

### Timestamp variables

Function | Returns
-------- | -------
`pgv_set_timestamp(package text, name text, value timestamp, is_transactional bool default false)` | `void`
`pgv_get_timestamp(package text, name text, strict bool default true)` | `timestamp`

### Timestamp with timezone variables

Function | Returns
-------- | -------
`pgv_set_timestamptz(package text, name text, value timestamptz, is_transactional bool default false)` | `void`
`pgv_get_timestamptz(package text, name text, strict bool default true)` | `timestamptz`

### Date variables

Function | Returns
-------- | -------
`pgv_set_date(package text, name text, value date, is_transactional bool default false)` | `void`
`pgv_get_date(package text, name text, strict bool default true)` | `date`

### Jsonb variables

Function | Returns
-------- | -------
`pgv_set_jsonb(package text, name text, value jsonb, is_transactional bool default false)` | `void`
`pgv_get_jsonb(package text, name text, strict bool default true)` | `jsonb`

## Record variables functions

The following functions are provided by the module to work with collections of
record types.

To use **pgv_update()**, **pgv_delete()** and **pgv_select()** functions
required package and variable must exists. Otherwise the error will be raised.
It is necessary to set variable with **pgv_insert()** function to use these
functions.

**pgv_update()**, **pgv_delete()** and **pgv_select()** functions check the
variable type. If the variable type does not **record** type the error will be
raised.

Function | Returns | Description
-------- | ------- | -----------
`pgv_insert(package text, name text, r record, is_transactional bool default false)` | `void` | Inserts a record to the variable collection. If package and variable do not exists they will be created. The first column of **r** will be a primary key. If exists a record with the same primary key the error will be raised. If this variable collection has other structure the error will be raised.
`pgv_update(package text, name text, r record)` | `boolean` | Updates a record with the corresponding primary key (the first column of **r** is a primary key). Returns **true** if a record was found. If this variable collection has other structure the error will be raised.
`pgv_delete(package text, name text, value anynonarray)` | `boolean` | Deletes a record with the corresponding primary key (the first column of **r** is a primary key). Returns **true** if a record was found.
`pgv_select(package text, name text)` | `set of record` | Returns the variable collection records.
`pgv_select(package text, name text, value anynonarray)` | `record` | Returns the record with the corresponding primary key (the first column of **r** is a primary key).
`pgv_select(package text, name text, value anyarray)` | `set of record` | Returns the variable collection records with the corresponding primary keys (the first column of **r** is a primary key).

### Miscellaneous functions

Function | Returns | Description
-------- | ------- | -----------
`pgv_exists(package text, name text)` | `bool` | Returns **true** if package and variable exists.
`pgv_exists(package text)` | `bool` | Returns **true** if package exists.
`pgv_remove(package text, name text)` | `void` | Removes the variable with the corresponding name. Required package and variable must exists, otherwise the error will be raised.
`pgv_remove(package text)` | `void` | Removes the package and all package variables with the corresponding name. Required package must exists, otherwise the error will be raised.
`pgv_free()` | `void` | Removes all packages and variables.
`pgv_list()` | `table(package text, name text, is_transactional bool)` | Returns set of records of assigned packages and variables.
`pgv_stats()` | `table(package text, allocated_memory bigint)` | Returns list of assigned packages and used memory in bytes.

Note that **pgv_stats()** works only with the PostgreSQL 9.6 and newer.

## Examples

It is easy to use functions to work with scalar and array variables:

```sql
SELECT pgv_set('vars', 'int1', 101);
SELECT pgv_set('vars', 'text1', 'text variable'::text);

SELECT pgv_get('vars', 'int1', NULL::int);
 pgv_get_int
-------------
         101

SELECT SELECT pgv_get('vars', 'text1', NULL::text);
    pgv_get
---------------
 text variable

SELECT pgv_set('vars', 'arr1', '{101,102}'::int[]);

SELECT pgv_get('vars', 'arr1', NULL::int[]);
  pgv_get
-----------
 {101,102}
```

Let's assume we have a **tab** table:

```sql
CREATE TABLE tab (id int, t varchar);
INSERT INTO tab VALUES (0, 'str00'), (1, 'str11');
```

Then you can use functions to work with record variables:

```sql
SELECT pgv_insert('vars', 'r1', tab) FROM tab;

SELECT pgv_select('vars', 'r1');
 pgv_select
------------
 (1,str11)
 (0,str00)

SELECT pgv_select('vars', 'r1', 1);
 pgv_select
------------
 (1,str11)

SELECT pgv_select('vars', 'r1', 0);
 pgv_select
------------
 (0,str00)

SELECT pgv_select('vars', 'r1', ARRAY[1, 0]);
 pgv_select
------------
 (1,str11)
 (0,str00)

SELECT pgv_delete('vars', 'r1', 1);

SELECT pgv_select('vars', 'r1');
 pgv_select
------------
 (0,str00)
```

You can list packages and variables:

```sql
SELECT * FROM pgv_list() order by package, name;
 package | name  | is_transactional
---------+-------+------------------
 vars    | arr1  | f
 vars    | int1  | f
 vars    | r1    | f
 vars    | text1 | f
```

And get used memory in bytes:

```sql
SELECT * FROM pgv_stats() order by package;
 package | allocated_memory
---------+------------------
 vars    |            49152
```

You can delete variables or whole packages:

```sql
SELECT pgv_remove('vars', 'int1');
SELECT pgv_remove('vars');
```

You can delete all packages and variables:
```sql
SELECT pgv_free();
```

If you want variables with support of transactions and savepoints, you should
add flag `is_transactional = true` as the last argument in functions `pgv_set()`
or `pgv_insert()`.
Following use cases describe behavior of transactional variables:

```sql
SELECT pgv_set('pack', 'var_text', 'before transaction block'::text, true);
BEGIN;
SELECT pgv_set('pack', 'var_text', 'before savepoint'::text, true);
SAVEPOINT sp1;
SELECT pgv_set('pack', 'var_text', 'savepoint sp1'::text, true);
SAVEPOINT sp2;
SELECT pgv_set('pack', 'var_text', 'savepoint sp2'::text, true);
RELEASE sp2;
SELECT pgv_get('pack', 'var_text', NULL::text);
    pgv_get
---------------
 savepoint sp2

ROLLBACK TO sp1;
SELECT pgv_get('pack', 'var_text', NULL::text);
     pgv_get
------------------
 before savepoint

ROLLBACK;
SELECT pgv_get('pack', 'var_text', NULL::text);
         pgv_get
--------------------------
 before transaction block
```

If you create a transactional variable after `BEGIN` or `SAVEPOINT` statements
and then rollback to previous state - variable will not be exist:

```sql
BEGIN;
SAVEPOINT sp1;
SAVEPOINT sp2;
SELECT pgv_set('pack', 'var_int', 122, true);
RELEASE SAVEPOINT sp2;
SELECT pgv_get('pack', 'var_int', NULL::int);
pgv_get
---------
     122

ROLLBACK TO sp1;
SELECT pgv_get('pack','var_int', NULL::int);
ERROR:  unrecognized variable "var_int"
COMMIT;
```

You can undo removal of a transactional variable by `ROLLBACK`, but if you remove
a whole package, all regular variables will be removed permanently:

```sql
SELECT pgv_set('pack', 'var_reg', 123);
SELECT pgv_set('pack', 'var_trans', 456, true);
BEGIN;
SELECT pgv_free();
SELECT * FROM pgv_list();
 package | name | is_transactional
---------+------+------------------
(0 rows)

-- Memory is allocated yet
SELECT * FROM pgv_stats();
 package | allocated_memory
---------+------------------
 pack    |            24576

ROLLBACK;
SELECT * FROM pgv_list();
 package |   name    | is_transactional
---------+-----------+------------------
 pack    | var_trans | t
```

If you created transactional variable once, you should use flag `is_transactional`
every time when you want to change variable value by functions `pgv_set()`,
`pgv_insert()` and deprecated setters (i.e. `pgv_set_int()`). If you try to
change this option, you'll get an error:

```sql
SELECT pgv_insert('pack', 'var_record', row(123::int, 'text'::text), true);

SELECT pgv_insert('pack', 'var_record', row(456::int, 'another text'::text));
ERROR:  variable "var_record" already created as TRANSACTIONAL
```

Functions `pgv_update()` and `pgv_delete()` do not require this flag.
