from pathlib import Path  # noqa: INP001

SQL_SCRIPT = Path(__file__).parent / "splits_database_builder.sql"

with SQL_SCRIPT.open() as f:
    sql_script = f.readlines()

table_names = [
    line.strip().replace("DROP TABLE IF EXISTS", "").replace(";", "")
    for line in sql_script
    if "DROP TABLE IF EXISTS" in line
]

for table in table_names:
    if "_runner" not in table and "indexed" not in table:
        msg = f"The table '{table}' has a bad name."
        raise ValueError(msg)

    full_content = SQL_SCRIPT.read_text()
    references = full_content.count(table) - 2
    match references:
        case 0:
            print(f"⚠️ Table {table} has NO references.")
        case 1:
            print(f"✅ Table {table} is referenced 1 time.")
        case _:
            print(f"✅ Table {table} is referenced {references} times.")
