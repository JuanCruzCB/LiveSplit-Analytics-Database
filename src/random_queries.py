from db import query_db
from pathlib import Path
import pandas as pd


def query_data(excel_name: str, query: str) -> None:
    df = query_db(query=query)
    try:
        df["date_started"] = pd.to_datetime(df["date_started"], errors="coerce")
        df["date_started"] = df["date_started"].dt.strftime("%d/%m/%Y")
    except:
        pass
    df.to_excel(
        Path(__file__).parent.parent / "excels" / f"{excel_name}.xlsx",
        index=False,
    )


def export_table_names() -> None:
    df = query_db(
        query="""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        ORDER BY table_name;
    """
    )
    data = df["table_name"].tolist()
    with open(
        Path(__file__).parent.parent / "info" / "List of relevant tables.txt",
        "w",
    ) as file:
        for table in data:
            if (
                "treatment" not in table
                and "cleaned" not in table
                and "info" not in table
                and "notepad" not in table
            ):
                file.write(f"{table}\n")


export_table_names()
query_data(
    "debug",
    """SELECT * FROM notepad_splits_sawken""",
)
