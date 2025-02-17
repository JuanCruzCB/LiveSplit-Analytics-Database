from pandas import DataFrame
from pathlib import Path
from decorators import measure_time


@measure_time
def make_excels(gold_dfs: list[DataFrame]) -> list[Path]:
    excel_paths: list[Path] = []
    for name, gold_df in gold_dfs:
        excel_path = Path(__file__).parent.parent / "excels" / f"{name}.xlsx"
        gold_df.to_excel(
            excel_writer=excel_path,
            index=False,
        )
        excel_paths.append(excel_path)
        print(f"Created excel file {name} succesfully!")
    return excel_paths
