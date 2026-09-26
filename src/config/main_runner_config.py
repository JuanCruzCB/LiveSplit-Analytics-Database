from pathlib import Path

from pydantic import BaseModel, field_validator


class MainRunnerConfig(BaseModel):
    name: str
    splits_file: Path

    @field_validator("name")
    @classmethod
    def _no_separators(cls, v: str) -> str:
        if any(c in v for c in ",-_ "):
            msg = (
                "The main runner name cannot have commas, hyphens, "
                "underscores or spaces."
            )
            raise ValueError(msg)
        return v

    @field_validator("splits_file")
    @classmethod
    def _must_be_absolute_and_exist(cls, v: Path) -> Path:
        if not v.is_absolute():
            msg = f"The splits_file path must be absolute, got: {v}"
            raise ValueError(msg)
        if not v.exists():
            msg = f"The file {v} does not exist."
            raise ValueError(msg)
        return v
