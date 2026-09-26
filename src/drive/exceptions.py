class GoogleDriveFolderNotFoundError(Exception):
    """
    Raised when the Google Drive folder with ID set in the configuration
    YAML file is not found.
    """
