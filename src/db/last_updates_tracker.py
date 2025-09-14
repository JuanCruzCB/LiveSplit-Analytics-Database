import json
from datetime import UTC, datetime
from pathlib import Path


class LastUpdatesTracker:
    """
    Tracks the last time each file has been updated from a predefined set of files.
    The tracking is loaded to and from a JSON file.
    """

    DATE_TIME_FORMAT = "%d/%m/%Y %H:%M:%S"
    DEFAULT_TIMESTAMP = "1/1/2000 00:00:00"

    def __init__(self, storage_file: Path, default_files: list[Path]) -> None:
        self._storage_file = storage_file
        self._default_data = dict.fromkeys(
            default_files,
            datetime.strptime(self.DEFAULT_TIMESTAMP, self.DATE_TIME_FORMAT).astimezone(
                UTC
            ),
        )

    def is_first_file_equal_to(self, file: Path) -> bool:
        """
        Checks whether the given file is the same as the first
        file on the JSON file.
        """
        last_updates = self.load_last_updates()
        first_file = next(iter(last_updates))
        return first_file == file

    def set_timestamp_now(self, file: Path) -> None:
        """
        Set the current UTC timestamp for a given file
        and save the update to the JSON file.
        """
        last_updates = self.load_last_updates()
        last_updates[file] = datetime.now().astimezone(UTC)
        self.save_last_updates(last_updates)

    def get_timestamp(self, file: Path) -> datetime:
        """
        Get the last update timestamp for a given file.
        """
        return self.load_last_updates()[file]

    def load_last_updates(self) -> dict[Path, datetime]:
        """
        Load the last update timestamps from the storage file.

        - If the storage file does not exist, it'll be created with default timestamps.
        - If the storage file exists, it'll be read and parsed.
        - In either case, a dictionary with the data is returned.
        """
        if not self._storage_file.exists():
            self.save_last_updates(self._default_data)
            return self._default_data

        with self._storage_file.open(mode="r") as json_file:
            raw_data = json.load(fp=json_file)
            return {
                Path(file): datetime.strptime(modtime, self.DATE_TIME_FORMAT).replace(
                    tzinfo=UTC
                )
                for file, modtime in raw_data.items()
            }

    def save_last_updates(self, updates: dict[Path, datetime]) -> None:
        """
        Save the given update timestamps to the JSON file.
        """
        serializable_dict = {
            str(file): modtime.strftime(self.DATE_TIME_FORMAT)
            for file, modtime in updates.items()
        }
        with self._storage_file.open(mode="w") as json_file:
            json.dump(obj=serializable_dict, fp=json_file, indent=4)
