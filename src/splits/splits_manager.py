import logging
from datetime import UTC, datetime
from pathlib import Path

from defusedxml.ElementTree import parse

from splits.splits_file_parse_error import SplitsFileParseError

logger = logging.getLogger(__name__)


class SplitsManager:
    def __init__(
        self,
        splits_output_folder: Path,
        main_runner_splits_file: Path,
        allowed_runners: list[str],
    ) -> None:
        self._splits_output_folder = splits_output_folder
        self._main_runner_splits_file = main_runner_splits_file
        self._currently_allowed_splits = [
            f"splits {runner}.lss" for runner in allowed_runners
        ]

    @property
    def splits_output_folder(self) -> Path:
        """
        Returns the folder where the splits of the other runners are stored.
        """
        return self._splits_output_folder

    @property
    def currently_allowed_splits(self) -> list[str]:
        """
        Returns the list of split filenames that are currently allowed.
        """
        return self._currently_allowed_splits

    def get_splits(self) -> list[Path]:
        """
        Returns a list with the Path of all splits files, including the
        main runner's splits file.
        """
        return [
            self._main_runner_splits_file,
            *self._splits_output_folder.glob("*.lss"),
        ]

    def get_splits_last_modtime(self) -> dict[Path, datetime]:
        """
        Checks the local folder containing the splits of the runners and
        returns a dict where each key is the splits file name and the value is
        that splits last modification time.
        """
        self._check_splits_folder_existence()

        local_splits = {}

        local_splits[self._main_runner_splits_file] = datetime.fromtimestamp(
            self._main_runner_splits_file.stat().st_mtime,
            tz=UTC,
        )
        for splits_file in self._splits_output_folder.glob(pattern="*.lss"):
            local_splits[splits_file] = datetime.fromtimestamp(
                splits_file.stat().st_mtime,
                tz=UTC,
            )

        return local_splits

    def get_splits_stem_last_modtime(self) -> dict[str, datetime]:
        """
        Checks the local folder containing the splits of the runners and
        returns a dict where each key is the splits file name and the value is
        that splits last modification time.
        """
        self._check_splits_folder_existence()

        local_splits = {}

        local_splits[self._main_runner_splits_file.stem] = datetime.fromtimestamp(
            self._main_runner_splits_file.stat().st_mtime,
            tz=UTC,
        )
        for splits_file in self._splits_output_folder.glob(pattern="*.lss"):
            local_splits[splits_file.stem] = datetime.fromtimestamp(
                splits_file.stat().st_mtime,
                tz=UTC,
            )

        return local_splits

    def clean_splits(self) -> None:
        """
        Go through each of the splits files and clean them to
        allow the SQL script to parse them safely.

        To clean them, first remove all data of the Icon tags, then
        remove any commas from any split name, then ???
        """
        logger.info("Cleaning any dirty split files...")
        self._check_splits_folder_existence()

        for splits_file in self._splits_output_folder.glob(pattern="*.lss"):
            splits_are_dirty = False
            logger.info("Checking '%s'...", splits_file.name)
            splits_file_tree = parse(splits_file)
            root = splits_file_tree.getroot()

            if root is None:
                msg = f"An unexpected error ocurred while inspecting '{splits_file.name}'."
                logger.exception(msg)
                raise SplitsFileParseError(msg)

            # 1. Ensure the splits don't have any icons
            for icon in root.findall(".//Icon"):
                if len(icon) > 0 or icon.text:
                    icon.clear()
                    splits_are_dirty = True

            # 2. Remove commas from split names
            for name in root.findall(".//Name"):
                if name.text is not None and "," in name.text:
                    name.text = name.text.replace(",", "|")
                    splits_are_dirty = True

            if splits_are_dirty:
                logger.info("Splits are dirty, cleaning them...")
                splits_file_tree.write(
                    splits_file,
                    encoding="utf-8",
                    xml_declaration=True,
                )

    def _check_splits_folder_existence(self) -> None:
        if not self._splits_output_folder.exists():
            msg = "The output folder for the splits of other runners does not exist."
            logger.exception(msg)
            raise FileNotFoundError(msg)
