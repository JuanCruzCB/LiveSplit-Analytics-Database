import time
from contextlib import contextmanager

from re4drive_manager import RE4DriveManager
from re4database_manager import RE4DatabaseManager
from re4sheet_manager import RE4SheetManager
from graphs import graph_village, graph_castle, graph_island
from constants import TIME_FORMAT
from timing import execution_times


@contextmanager
def measure_total_time():
    start_time = time.time()
    yield
    execution_time = time.time() - start_time
    seconds = int(execution_time)
    milliseconds = int((execution_time % 1) * 1000)
    execution_time_formatted = TIME_FORMAT.format(seconds, milliseconds)
    execution_times["The whole script"] = execution_time_formatted


def main() -> None:
    with measure_total_time():
        db_manager = RE4DatabaseManager()
        sheet_manager = RE4SheetManager()

        drive_manager = RE4DriveManager()
        splits = drive_manager.download_splits()

        db_manager.update_runners_tables(splits=splits)
        db_manager.update_global_tables()

        df_doorsplit_golds = db_manager.query_doorsplit_golds()
        df_chapter_golds = db_manager.query_chapter_golds()
        df_chapter_golds_by_doors = db_manager.query_chapter_golds_by_doors()
        df_section_golds = db_manager.query_section_golds()
        df_section_golds_by_chapters = db_manager.query_section_golds_by_chapters()
        df_section_golds_by_doors = db_manager.query_section_golds_by_doors()
        df_best_paces = db_manager.query_best_paces()
        df_rng_patterns = db_manager.query_rng_patterns()
        df_general_stats = db_manager.query_general_stats()
        df_resets = db_manager.query_resets()
        df_weekday_data = db_manager.query_weekday_data()

        db_manager.close_connection()

        sheet_manager.copy_doorsplits_to_sheet(doorsplits=df_doorsplit_golds)
        sheet_manager.copy_chapters_to_sheet(
            chapters=df_chapter_golds,
            chapters_by_doors=df_chapter_golds_by_doors,
        )
        sheet_manager.copy_sections_to_sheet(
            sections=df_section_golds,
            sections_by_chapters=df_section_golds_by_chapters,
            sections_by_doors=df_section_golds_by_doors,
        )
        sheet_manager.copy_paces_to_sheet(paces=df_best_paces)
        sheet_manager.copy_rng_patterns_to_sheet(rng_patterns=df_rng_patterns)
        sheet_manager.copy_general_stats_to_sheet(general_stats=df_general_stats)
        sheet_manager.copy_resets_to_sheet(resets=df_resets)
        sheet_manager.copy_weekday_data_to_sheet(weekday_data=df_weekday_data)
        sheet_manager.post_last_update()

        if False:
            url_village_graph = graph_village(excel=excel_files[9])
            url_castle_graph = graph_castle(excel=excel_files[9])
            url_island_graph = graph_island(excel=excel_files[9])

            sheet_manager.copy_graphs_to_sheet(
                url_village_graph=url_village_graph,
                url_castle_graph=url_castle_graph,
                url_island_graph=url_island_graph,
            )

    for func_name, exec_time in execution_times.items():
        print(f"{func_name} took {exec_time}")


if __name__ == "__main__":
    main()
