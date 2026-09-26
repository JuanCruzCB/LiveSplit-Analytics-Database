class SplitsFileStructureError(Exception):
    """
    Raised when a splits file has an unexpected structure.
    """


class SplitsFilesComparisonError(Exception):
    """
    Raised when a splits file has a structure that cannot be properly
    compared with the rest of the splits files.
    """
