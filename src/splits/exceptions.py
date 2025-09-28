class GoogleDriveFolderNotFoundError(Exception):
    pass


class SplitsFileStructureError(Exception):
    """Raised when a splits file has an unexpected structure."""
