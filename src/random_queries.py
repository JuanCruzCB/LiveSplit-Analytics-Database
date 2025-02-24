from pathlib import Path

import pandas as pd

from re4database_manager import RE4DatabaseManager
from constants import DATE_FORMAT


def query_data(db_manager: RE4DatabaseManager, excel_name: str, query: str) -> None:
    df = db_manager.query_db(query=query)
    try:
        df["date_started"] = pd.to_datetime(df["date_started"], errors="coerce")
        df["date_started"] = df["date_started"].dt.strftime(DATE_FORMAT)
    except:
        pass
    df.to_excel(
        Path(__file__).parent.parent / "excels" / f"{excel_name}.xlsx",
        index=False,
    )


def export_table_names(db_manager: RE4DatabaseManager) -> None:
    df = db_manager.query_db(
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


db_manager = RE4DatabaseManager()

export_table_names()
query_data(
    "debug",
    """SELECT * FROM notepad_splits_sawken""",
)
