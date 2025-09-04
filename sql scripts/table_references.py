from pathlib import Path  # noqa: INP001

sql = Path(__file__).parent.parent / "sql scripts" / "splits_database_builder.sql"

with sql.open() as f:
    sql_script = f.readlines()

full_content = sql.read_text()

table_names = []
for line in sql_script:
    if "DROP TABLE IF EXISTS" in line:
        table_names.append(
            line.strip().replace("DROP TABLE IF EXISTS", "").replace(";", "")
        )

for table in table_names:
    if "_runner" not in table and "indexed" not in table:
        msg = f"The table '{table}' has a bad name."
        raise ValueError(msg)

    references = full_content.count(table) - 2
    if references == 0:
        print(f"⚠️ Table {table} has NO references.")

    elif references == 1:
        print(f"✅ Table {table} is referenced 1 time.")

    else:
        print(f"✅ Table {table} is referenced {references} times.")
