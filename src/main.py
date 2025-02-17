import time
from contextlib import contextmanager
import argparse

from drive import download_splits
from db import (
    query_chapter_golds,
    query_chapter_golds_by_doors,
    query_doorsplit_golds,
    query_section_golds,
    query_section_golds_by_chapters,
    query_section_golds_by_doors,
    query_best_paces,
    query_rng_patterns,
    query_resets,
    query_general_stats,
    update_runners_tables,
    update_global_tables,
)
from sheet import (
    open_sheet,
    copy_doorsplits_to_sheet,
    copy_chapters_to_sheet,
    copy_sections_to_sheet,
    copy_paces_to_sheet,
    copy_rng_patterns_to_sheet,
    copy_general_stats_to_sheet,
    copy_resets_to_sheet,
    copy_graphs_to_sheet,
)
from graphs import graph_village, graph_castle, graph_island
from excel import make_excels
from constants import TIME_FORMAT, SPLITS_RUNNERS
from timing import execution_times


def parse_args():
    parser = argparse.ArgumentParser(description="Process splits.")
    parser.add_argument(
        "--download", action="store_true", help="Download splits from drive"
    )
    parser.add_argument(
        "--update_tables", action="store_true", help="Update database tables"
    )
    return parser.parse_args()


@contextmanager
def measure_total_time():
    start_time = time.time()
    yield
    execution_time = time.time() - start_time
    execution_time_formatted = time.strftime(TIME_FORMAT, time.gmtime(execution_time))
    execution_times["The whole script"] = execution_time_formatted


def main(download_drive: bool, update_tables: bool) -> None:
    if download_drive:
        files = download_splits()
    else:
        files = SPLITS_RUNNERS

    if update_tables:
        update_runners_tables(files=files)
        update_global_tables()

    df_doorsplit_golds = query_doorsplit_golds()
    df_chapter_golds = query_chapter_golds()
    df_chapter_golds_by_doors = query_chapter_golds_by_doors()
    df_section_golds = query_section_golds()
    df_section_golds_by_chapters = query_section_golds_by_chapters()
    df_section_golds_by_doors = query_section_golds_by_doors()
    df_best_paces = query_best_paces()
    df_rng_patterns = query_rng_patterns()
    df_general_stats = query_general_stats()
    df_resets = query_resets()

    excel_files = make_excels(
        gold_dfs=[
            ("Doorsplit golds", df_doorsplit_golds),
            ("Chapter golds", df_chapter_golds),
            ("Chapter golds by doors", df_chapter_golds_by_doors),
            ("Section golds", df_section_golds),
            ("Section golds by chapters", df_section_golds_by_chapters),
            ("Section golds by doors", df_section_golds_by_doors),
            ("Best paces", df_best_paces),
            ("RNG Patterns", df_rng_patterns),
            ("General Stats", df_general_stats),
            ("Resets", df_resets),
        ]
    )

    spreadsheet = open_sheet()
    copy_doorsplits_to_sheet(spreadsheet=spreadsheet, doorsplits=excel_files[0])
    copy_chapters_to_sheet(
        spreadsheet=spreadsheet,
        chapters=excel_files[1],
        chapters_by_doors=excel_files[2],
    )
    copy_sections_to_sheet(
        spreadsheet=spreadsheet,
        sections=excel_files[3],
        sections_by_chapters=excel_files[4],
        sections_by_doors=excel_files[5],
    )
    copy_paces_to_sheet(spreadsheet=spreadsheet, paces=excel_files[6])
    copy_rng_patterns_to_sheet(spreadsheet=spreadsheet, rng_patterns=excel_files[7])
    copy_general_stats_to_sheet(spreadsheet=spreadsheet, general_stats=excel_files[8])
    copy_resets_to_sheet(spreadsheet=spreadsheet, resets=excel_files[9])

    """
    url_village_graph = graph_village(excel=excel_files[9])
    url_castle_graph = graph_castle(excel=excel_files[9])
    url_island_graph = graph_island(excel=excel_files[9])

    copy_graphs_to_sheet(
        spreadsheet=spreadsheet,
        url_village_graph=url_village_graph,
        url_castle_graph=url_castle_graph,
        url_island_graph=url_island_graph,
    )
    """


if __name__ == "__main__":
    args = parse_args()
    with measure_total_time():
        main(download_drive=args.download, update_tables=args.update_tables)

    for func_name, exec_time in execution_times.items():
        print(f"{func_name} took {exec_time}")
