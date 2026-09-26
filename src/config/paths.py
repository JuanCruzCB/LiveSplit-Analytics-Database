from pathlib import Path

PROJECT_DIR = Path(__file__).parent.parent.parent
CONFIG_DIR = PROJECT_DIR / "config"
YAML_CONFIG_FILE = CONFIG_DIR / "config.yaml"
LAST_UPDATES_FILE = CONFIG_DIR / "last_table_updates.json"
OUTPUT_DIR = PROJECT_DIR / "output"
