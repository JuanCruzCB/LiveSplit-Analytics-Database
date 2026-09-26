from pathlib import Path

from pydantic import BaseModel, field_validator


class OtherRunnersConfig(BaseModel):
    names: list[str]
    splits_folder: Path

    @field_validator("names")
    @classmethod
    def _no_separators(cls, v: list[str]) -> list[str]:
        for name in v:
            if any(c in name for c in ",-_ "):
                msg = (
                    "The runner names cannot have commas, hyphens, "
                    "underscores or spaces."
                )
                raise ValueError(msg)
        return v

    @field_validator("splits_folder")
    @classmethod
    def _must_be_absolute_and_exist(cls, v: Path) -> Path:
        if not v.is_absolute():
            msg = f"The splits_folder path must be absolute, got: {v}"
            raise ValueError(msg)
        if not v.exists():
            msg = f"The folder {v} does not exist."
            raise ValueError(msg)
        return v
