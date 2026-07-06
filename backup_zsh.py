#!/usr/bin/env python3
import os
import shutil
import tarfile
from pathlib import Path
from datetime import datetime
from typing import List

# --- CONFIGURATION ---
# Define what constitutes your "Terminal State"
# Use the current working directory to find dotfiles
CWD = Path.cwd()
TARGETS = [
    Path.home() / ".zshrc",
    CWD / "dotfiles/functions",  # Use current working directory
]
BACKUP_DIR = Path.home() / ".zsh_backups"
MAX_BACKUPS = 5  # Keep only the 5 most recent "preened" backups
# ---------------------

def create_backup() -> None:
    """Archives the target configuration files into a timestamped tar.gz."""
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    archive_name = BACKUP_DIR / f"zsh_state_{timestamp}.tar.gz"

    print(f"🦆 Packing the pond... Creating backup at {archive_name}")

    try:
        with tarfile.open(archive_name, "w:gz") as tar:
            for target in TARGETS:
                if target.exists():
                    # arcname ensures we don't store the full absolute path in the archive
                    tar.add(target, arcname=target.name)
                    print(f"📦 Added: {target.name}")
                else:
                    print(f"⚠️  Warning: {target} not found, skipping.")

        print(f"✔ Backup successfully stored. Quack!")
    except Exception as e:
        print(f"❌ Error during backup: {e}")
        exit(1)

def preen_backups() -> None:
    """Removes older backups, keeping only the most recent MAX_BACKUPS."""
    print("🧹 Preening old backups...")

    # Get all .tar.gz files in the backup directory
    backups: List[Path] = sorted(
        BACKUP_DIR.glob("zsh_state_*.tar.gz"),
        key=os.path.getmtime,
        reverse=True
    )

    if len(backups) > MAX_BACKUPS:
        to_delete = backups[MAX_BACKUPS:]
        for old_file in to_delete:
            try:
                old_file.unlink()
                print(f"🗑️  Removed old backup: {old_file.name}")
            except OSError as e:
                print(f"❌ Failed to delete {old_file.name}: {e}")
    else:
        print("✨ Pond is already clean. No old backups to remove.")

if __name__ == "__main__":
    create_backup()
    preen_backups()
    print("\nAll set! Your terminal state is safe and sound. Quack!")
