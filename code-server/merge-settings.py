#!/usr/bin/env python3
import json
import os
import shutil
import sys


def merge(user, central):
    """Recursively merge central settings into user settings (central has priority)."""
    if isinstance(user, dict) and isinstance(central, dict):
        merged = dict(user)
        for key, value in central.items():
            if key in merged and isinstance(merged[key], dict) and isinstance(value, dict):
                merged[key] = merge(merged[key], value)
            else:
                merged[key] = value
        return merged
    return central


def main():
    if len(sys.argv) < 3:
        sys.exit(f"Usage: {sys.argv[0]} <central_settings.json> <user_settings.json>")

    central_path = sys.argv[1]
    user_path = sys.argv[2]

    if not os.path.exists(central_path):
        return

    # If user_path is a symlink (from earlier versions), remove it
    if os.path.islink(user_path):
        os.unlink(user_path)

    os.makedirs(os.path.dirname(user_path), exist_ok=True)

    # If user settings file doesn't exist, copy central settings directly
    if not os.path.exists(user_path):
        shutil.copy2(central_path, user_path)
        return

    try:
        with open(user_path, "r", encoding="utf-8") as f:
            user_settings = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Warning: could not parse {user_path}: {e}. Leaving it intact.", file=sys.stderr)
        return

    try:
        with open(central_path, "r", encoding="utf-8") as f:
            central_settings = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Warning: could not parse {central_path}: {e}. Leaving user settings intact.", file=sys.stderr)
        return

    merged_settings = merge(user_settings, central_settings)

    # Write to a temp file first so the user's file is never left in a partial state
    temp_path = user_path + f".tmp.{os.getpid()}"
    try:
        with open(temp_path, "w", encoding="utf-8") as f:
            json.dump(merged_settings, f, indent=2)
            f.write("\n")
        os.replace(temp_path, user_path)
    except Exception as e:
        print(f"Warning: could not write merged settings to {user_path}: {e}. Leaving it intact.", file=sys.stderr)
        if os.path.exists(temp_path):
            os.unlink(temp_path)


if __name__ == "__main__":
    main()
