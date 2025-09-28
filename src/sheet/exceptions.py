class SheetNotFoundError(Exception):
    """
    Raised when the Google Sheet with ID set in the configuration
    YAML file is not found.
    """


class UnauthorizedError(Exception):
    """
    Raised when the user is not authorized to access the Google Sheet.
    """
