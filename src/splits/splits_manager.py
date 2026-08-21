import logging
from pathlib import Path

from splits.exceptions import SplitsFilesComparisonError
from splits.splits_file import SplitsFile

logger = logging.getLogger(__name__)


class SplitsManager:
    def __init__(
        self,
        splits_output_folder: Path,
        main_runner_splits_file: Path,
        runner_names: list[str],
    ) -> None:
        self._splits_folder: Path = splits_output_folder
        self._main_runner_splits_file: Path = main_runner_splits_file
        self._runner_names: list[str] = runner_names

    @property
    def splits_folder(self) -> Path:
        """
        Returns the path where all the local splits files are stored.
        """
        return self._splits_folder

    def get_splits_files_paths(self) -> list[Path]:
        """
        Returns the path of every splits file.
        """
        return list(self._splits_folder.glob("*.lss"))

    def get_splits_files(self) -> list[SplitsFile]:
        """
        Returns the list of all SplitsFile objects.
        """
        splits_files: list[SplitsFile] = []
        splits_files.append(
            SplitsFile(
                file_path=self._main_runner_splits_file,
                runner_name=self._runner_names[0],
            ),
        )
        for splits_file in self._splits_folder.glob("*.lss"):
            runner_name = splits_file.stem.replace("splits ", "")
            splits_files.append(
                SplitsFile(file_path=splits_file, runner_name=runner_name),
            )
        return splits_files

    @property
    def runner_names(self) -> list[str]:
        """
        Returns the list of runner names that are allowed.
        """
        return self._runner_names

    def validate_all_splits(self) -> None:
        """
        Validates all splits files by checking that all of them have
        the same number of splits.
        """
        number_of_splits_main = self.get_splits_files()[0].get_number_of_splits()

        for splits_file in self.get_splits_files()[1:]:
            number_of_splits = splits_file.get_number_of_splits()
            if number_of_splits != number_of_splits_main:
                msg = (
                    f"The splits file '{splits_file.file_path}' has a different "
                    f"number of splits ({number_of_splits}) "
                    f"than the main runner's splits file ({number_of_splits_main})."
                )
                logger.error(msg)
                raise SplitsFilesComparisonError(msg)

    def clean_all_splits(self) -> None:
        """
        Cleans all splits files by..

        1. Removing Icons (if they exist) from all splits.
        2. Replacing all commas in split names by pipes.
        """
        for splits_file in self.get_splits_files():
            _ = splits_file.clean()

    def find_splits_file_by_runner_name(self, runner_name: str) -> SplitsFile | None:
        """
        Finds and returns the SplitsFile object that matches the given runner name.

        If no such file exists, returns None.
        """
        return next(
            (
                splits_file
                for splits_file in self.get_splits_files()
                if splits_file.runner_name == runner_name
            ),
            None,
        )
