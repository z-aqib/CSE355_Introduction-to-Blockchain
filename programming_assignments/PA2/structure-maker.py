# structure-maker.py
"""
Generates a visually beautiful tree view of the current directory (like `tree` command)
and writes it to structure.txt
"""

from pathlib import Path

DEFAULT_IGNORES = {
    ".git",
    "__pycache__",
    ".venv",
    "venv",
    ".mypy_cache",
    ".pytest_cache",
    ".ruff_cache",
    ".idea",
    ".vscode",
    "dist",
    ".DS_Store",
    "node_modules",
    ".ipynb_checkpoints",
}

ALLOW_HIDDEN = {".gitignore", ".gitattributes", ".gitkeep", ".github", ".husky"}


def is_hidden(p: Path) -> bool:
    # Only treat dot-files/folders as hidden (except allowlist)
    return p.name.startswith(".") and p.name not in ALLOW_HIDDEN


def build_tree(directory: Path, prefix: str = "", ignores=None, max_depth=None, depth=0):
    """Recursively builds the tree structure"""
    if ignores is None:
        ignores = set()

    if max_depth is not None and depth > max_depth:
        return []

    try:
        entries = sorted(
            [e for e in directory.iterdir() if not is_hidden(e) and e.name not in ignores],
            key=lambda x: (x.is_file(), x.name.lower()),
        )
    except PermissionError:
        return [f"{prefix}└── [permission denied]"]

    lines = []
    for idx, entry in enumerate(entries):
        last = idx == len(entries) - 1
        connector = "└── " if last else "├── "
        lines.append(f"{prefix}{connector}{entry.name}")

        if entry.is_dir():
            extension = "    " if last else "│   "
            lines.extend(build_tree(entry, prefix + extension, ignores, max_depth, depth + 1))

    return lines


def main():
    root = Path(".").resolve()
    print(f"Generating beautiful tree for: {root}")
    lines = [f"{root.name}/"] + build_tree(root, "", DEFAULT_IGNORES)
    output_path = root / "file-structure.txt"
    output_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Tree written to: {output_path}")


if __name__ == "__main__":
    main()
    