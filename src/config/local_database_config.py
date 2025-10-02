import logging
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class LocalDatabaseConfig:
    dbname: str
    user: str
    host: str
    password: int | str
    port: int

    def to_dict(self) -> dict[str, int | str]:
        """
        Returns the database configuration as a dictionary.
        """
        return {
            "dbname": self.dbname,
            "user": self.user,
            "host": self.host,
            "password": self.password,
            "port": self.port,
        }
