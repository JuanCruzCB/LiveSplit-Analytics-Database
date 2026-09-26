from pydantic import BaseModel


class LocalDatabaseConfig(BaseModel):
    dbname: str
    user: str
    host: str
    password: str
    port: str

    def to_dict(self) -> dict[str, str]:
        """
        Returns the database configuration as a dictionary.
        """
        return self.model_dump()
