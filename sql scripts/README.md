- We can use `XMLPARSE` and `pg_read_file` to read XML data like LiveSplit files (.lss), also `xmltable` and `xpath` to extract things out of XML data:

```sql
SELECT XMLPARSE(DOCUMENT pg_read_file('splits.lss')) AS xml_data;
```
