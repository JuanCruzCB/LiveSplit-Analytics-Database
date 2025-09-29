class GoogleDriveFolderNotFoundError(Exception):
    """
    Raised when the Google Drive folder with ID set in the configuration
    YAML file is not found.
    """


class SplitsFileStructureError(Exception):
    """
    Raised when a splits file has an unexpected structure.
    """


class SplitsFilesComparisonError(Exception):
    """
    Raised when a splits file has a structure that cannot be properly
    compared with the rest of the splits files.
    """
