import logging
from datetime import UTC, datetime
from pathlib import Path

from defusedxml.ElementTree import parse

from splits.exceptions import SplitsFileStructureError

logger = logging.getLogger(__name__)


class SplitsFile:
    def __init__(
        self,
        file_path: Path,
        runner_name: str,
    ) -> None:
        self._validate_file_path_exists(file_path)
        self._validate_file_path_structure(file_path)
        self._validate_file_path_is_file(file_path)
        self._validate_file_path_extension(file_path)

        self._file_path = file_path
        self._runner_name = runner_name

    @staticmethod
    def _validate_file_path_exists(file_path: Path) -> None:
        """
        Checks whether the splits file exists in the filesystem.
        """
        if not file_path.exists():
            msg = f"Splits file does not exist: '{file_path}'."
            logger.exception(msg)
            raise FileNotFoundError(msg)

    @staticmethod
    def _validate_file_path_structure(file_path: Path) -> None:
        """
        Checks whether the splits file contains a valid XML structure.
        """
        tree = parse(file_path)
        if tree.getroot() is None:
            msg = f"Invalid XML structure in splits file: '{file_path}'."
            logger.exception(msg)
            raise SplitsFileStructureError(msg)

    @staticmethod
    def _validate_file_path_is_file(file_path: Path) -> None:
        """
        Checks whether the path is a file and not a directory.
        """
        if not file_path.is_file():
            msg = f"Path is not a file: '{file_path}'."
            logger.exception(msg)
            raise ValueError(msg)

    @staticmethod
    def _validate_file_path_extension(file_path: Path) -> None:
        """
        Checks whether the file has a .lss (LiveSplitSplits) extension.
        """
        if file_path.suffix.lower() != ".lss":
            msg = f"Splits file must have a .lss extension: '{file_path}'."
            logger.exception(msg)
            raise ValueError(msg)

    @property
    def file_path(self) -> Path:
        """
        Returns the file path of the splits file.
        """
        return self._file_path

    @property
    def runner_name(self) -> str:
        """
        Returns the name of the runner that is associated with the splits file.
        """
        return self._runner_name

    def clean(self) -> None:
        """
        Cleans the splits file by:
        1. Removing Icons (if they exist) from all splits.
        2. Replacing commas in split names with pipes.

        This ensures compatibility with the database and avoids issues
        with data parsing.
        """
        tree = parse(self._file_path)
        root = tree.getroot()

        # 1. Remove all existing data inside each Icon tag
        for icon in root.findall(".//Icon"):  # type: ignore  # noqa: PGH003
            if len(icon) > 0 or icon.text:
                msg = "Removing an icon from splits file: '%s'.", self._file_path
                logger.warning(msg)
                icon.clear()

        # 2. Replace commas in split names with pipes
        for name in root.findall(".//Name"):  # type: ignore  # noqa: PGH003
            if name.text is not None and "," in name.text:
                msg = (
                    "Replacing commas (,) with pipes (|) in splits file: '%s'.",
                    self._file_path,
                )
                logger.warning(msg)
                name.text = name.text.replace(",", "|")

        tree.write(
            self._file_path,
            encoding="utf-8",
            xml_declaration=True,
        )

    def get_last_modified_datetime(self) -> datetime:
        """
        Returns the date and time when the splits file was last modified, in
        UTC timezone.
        """
        return datetime.fromtimestamp(
            self._file_path.stat().st_mtime,
            tz=UTC,
        )

    def is_outdated(self, last_mod_dt: datetime) -> bool:
        """
        Checks whether this splits file is outdated compared to the given
        datetime, in UTC timezone.
        """
        return self.get_last_modified_datetime() < last_mod_dt

    def get_number_of_splits(self) -> int:
        """
        Returns the number of splits in the splits file.
        """
        tree = parse(self._file_path)
        split_names = list(tree.getroot().iter("Name"))  # type: ignore
        return len(split_names)
