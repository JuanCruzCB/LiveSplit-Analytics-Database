class DatabaseError(Exception):
    """
    Base class for all database-related errors.
    """

    def __init__(
        self,
        db_config: dict[str, str | int],
        original_exception: Exception | None = None,
        message: str = "An error occurred with the database.",
    ) -> None:
        super().__init__(message)
        self.message = message
        self.db_config = db_config
        self.original_exception = original_exception

    def __str__(self) -> str:
        """
        Return a string representation of the error.
        """
        config_info = f" (Config: {self.db_config})"
        original_info = (
            f" (Original: {self.original_exception})" if self.original_exception else ""
        )
        return f"{self.message}{config_info}{original_info}"


class NoActiveConnectionError(DatabaseError):
    """
    Raised when attempting to access the database without an existing
    active connection.
    """

    def __init__(
        self,
        db_config: dict[str, str | int],
        original_exception: Exception | None = None,
        message: str = "No active connection to the database.",
    ) -> None:
        super().__init__(
            db_config,
            original_exception,
            message,
        )


class ConnectionError(DatabaseError):  # noqa: A001
    """
    Raised when the database connection fails.
    """

    def __init__(
        self,
        db_config: dict[str, str | int],
        original_exception: Exception,
        message: str = "Failed to connect to the database.",
    ) -> None:
        super().__init__(
            db_config,
            original_exception,
            message,
        )


class QueryExecutionError(DatabaseError):
    """
    Raised when a SQL query fails to execute.
    """

    def __init__(
        self,
        db_config: dict[str, str | int],
        original_exception: Exception,
        message: str = "Failed to execute SQL query.",
    ) -> None:
        super().__init__(
            db_config,
            original_exception,
            message,
        )
