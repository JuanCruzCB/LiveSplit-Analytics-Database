from pathlib import Path

from pydantic import BaseModel, field_validator

from config.paths import CONFIG_DIR


class SQLScriptsConfig(BaseModel):
    builder: Path
    config: Path

    @field_validator("builder", "config", mode="after")
    @classmethod
    def _resolve_and_check(cls, v: Path) -> Path:
        resolved = (CONFIG_DIR / v).resolve() if not v.is_absolute() else v.resolve()
        if not resolved.exists():
            msg = f"The file {resolved} does not exist."
            raise ValueError(msg)
        return resolved
