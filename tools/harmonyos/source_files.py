"""List all tracked and untracked Dart source files, excluding ignored build caches."""
import argparse
import json
import subprocess
from pathlib import Path


def dart_sources(member: str) -> list[str]:
    output = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard", "--", member],
        check=True, capture_output=True, encoding="utf-8",
    ).stdout
    return sorted({name for name in output.split("\0") if name.endswith(".dart") and Path(name).is_file()})


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("member")
    print(json.dumps(dart_sources(parser.parse_args().member)))
