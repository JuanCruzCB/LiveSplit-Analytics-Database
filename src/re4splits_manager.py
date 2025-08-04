from datetime import UTC, datetime
from pathlib import Path

from defusedxml.ElementTree import parse


class SplitsFileParseError(Exception):
    """Raised when a splits file cannot be parsed as expected."""


class RE4SplitsManager:
    CURRENTLY_ALLOWED_SPLITS = (
        "splits luis.lss",
        "splits joker.lss",
        "splits mateo.lss",
        "splits arcadan.lss",
        "splits richy.lss",
        "splits derek.lss",
        "splits nevs.lss",
        "splits otaku.lss",
        "splits pocho.lss",
        "splits missing.lss",
    )

    def __init__(
        self,
        splits_output_folder: Path,
        my_splits_file: Path,
    ) -> None:
        self._splits_output_folder = splits_output_folder
        self._my_splits_file = my_splits_file

    @property
    def splits_output_folder(self) -> Path:
        return self._splits_output_folder

    def get_splits_names(self) -> dict[str, datetime]:
        """
        Checks the local folder containing the splits of the runners and
        returns a dict where each key is the splits file name and the value is
        that splits last modification time.
        """
        self._check_splits_folder_existence()

        local_splits = {
            splits_file.stem: datetime.fromtimestamp(
                splits_file.stat().st_mtime, tz=UTC
            )
            for splits_file in self._splits_output_folder.glob(pattern="*.lss")
        }

        local_splits[self._my_splits_file.stem] = datetime.fromtimestamp(
            self._my_splits_file.stat().st_mtime, tz=UTC
        )

        return local_splits

    def clean_splits(self) -> None:
        """
        Go through each of the splits files and clean them to
        allow the SQL script to parse them safely.

        To clean them, first remove all data of the Icon tags, then
        remove any commas from any split name, then ???
        """
        self._check_splits_folder_existence()

        for splits_file in self._splits_output_folder.glob(pattern="*.lss"):
            splits_are_dirty = False
            print(f"Checking '{splits_file.name}'...", end="")
            splits_file_tree = parse(splits_file)
            root = splits_file_tree.getroot()

            if root is None:
                msg = f"An unexpected error ocurred while inspecting '{splits_file.name}'."
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
                print(" Splits are dirty, cleaning them...", end="")
                splits_file_tree.write(
                    splits_file,
                    encoding="utf-8",
                    xml_declaration=True,
                )
            print()

    def _check_splits_folder_existence(self):
        if not self._splits_output_folder.exists():
            msg = "The output folder for the splits of other runners does not exist."
            raise FileNotFoundError(msg)
