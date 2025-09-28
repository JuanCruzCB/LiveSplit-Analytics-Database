import logging
from pathlib import Path

from splits.splits_file import SplitsFile

logger = logging.getLogger(__name__)


class SplitsManager:
    def __init__(
        self,
        splits_output_folder: Path,
        main_runner_splits_file: Path,
        allowed_runners: list[str],
    ) -> None:
        splits_files: list[SplitsFile] = []
        splits_files.append(
            SplitsFile(
                file_path=main_runner_splits_file,
                runner_name=allowed_runners[0],
                is_main_runner=True,
            ),
        )
        for splits_file in splits_output_folder.glob("*.lss"):
            runner_name = splits_file.stem[7:]
            splits_files.append(
                SplitsFile(file_path=splits_file, runner_name=runner_name),
            )

        self._splits_folder = splits_output_folder
        self._splits_files = splits_files
        self._allowed_runners = allowed_runners

    @property
    def splits_folder(self) -> Path:
        """
        Returns the path where all the local splits files are stored.
        """
        return self._splits_folder

    @property
    def splits_files_paths(self) -> list[Path]:
        """
        Returns the path of every splits file.
        """
        return [splits_file.file_path for splits_file in self._splits_files]

    @property
    def splits_files(self) -> list[SplitsFile]:
        """
        Returns the list of all SplitsFile objects.
        """
        return self._splits_files

    @property
    def allowed_runners(self) -> list[str]:
        """
        Returns the list of runner names that are allowed.
        """
        return self._allowed_runners

    def clean_all_splits(self) -> None:
        """
        Cleans all splits files by calling their individual clean methods.
        """
        for splits_file in self._splits_files:
            splits_file.clean()

    def find_splits_file_by_runner_name(self, runner_name: str) -> SplitsFile | None:
        """
        Finds and returns the SplitsFile object that matches the given runner name.

        If no such file exists, returns None.
        """
        return next(
            (
                splits_file
                for splits_file in self._splits_files
                if splits_file.runner_name == runner_name
            ),
            None,
        )
