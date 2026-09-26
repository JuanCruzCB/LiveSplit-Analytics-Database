from pydantic import BaseModel, ConfigDict


class LocalDatabaseConfig(BaseModel):
    model_config = ConfigDict(coerce_numbers_to_str=True)  # pyright: ignore[reportUnannotatedClassAttribute]

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
