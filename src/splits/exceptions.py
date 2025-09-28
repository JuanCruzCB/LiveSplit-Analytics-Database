class GoogleDriveFolderNotFoundError(Exception):
    """
    Raised when the Google Drive folder with ID set in the configuration
    YAML file is not found.
    """


class SplitsFileStructureError(Exception):
    """
    Raised when a splits file has an unexpected structure.
    """
