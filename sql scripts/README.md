- Use `XMLPARSE` and `pg_read_file` to read XML data like LiveSplit files (.lss), also `xmltable` and `xpath` to extract things out of XML data:

```sql
SELECT XMLPARSE(DOCUMENT pg_read_file('splits.lss')) AS xml_data;
```

- Inspect the schema itself to see metadata about tables and columns:

```sql
SELECT COLUMN_NAME
FROM information_schema.columns
WHERE TABLE_NAME = 'my_table_name'
ORDER BY ORDINAL_POSITION;
```

- Delete and recreate the public schema (useful for testing/debugging):

```sql
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
```

- Get the total size of the DB:

```sql
SELECT pg_size_pretty(pg_database_size(current_database())) AS db_size;
```

- Get the size of each table in the DB:

```sql
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

- Find all columns of one or more datatypes:

```sql
SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND data_type IN ('date', 'timestamp with time zone')
ORDER BY
    table_name,
    ordinal_position;
```

- Create a table and load data from a `.txt` file where each line will correspond to one row in the table:

```sql
CREATE TABLE cfg_default_split_names(split_index SERIAL PRIMARY KEY, split_name TEXT);

COPY cfg_default_split_names(split_name)
FROM '/path/to/file.txt'
WITH (FORMAT text);
```
