"""Reject the fullscreen reply regression in the actual HarmonyOS engine HAR."""
import argparse
import hashlib
import json
import re
import tarfile
from pathlib import Path


def inspect(har: Path) -> dict:
    with tarfile.open(har) as archive:
        member = archive.getmember("package/src/main/ets/embedding/engine/systemchannels/PlatformChannel.ets")
        source = archive.extractfile(member).read().decode("utf-8")
    match = re.search(r'case [\'"]SystemChrome\.setEnabledSystemUIMode[\'"]:(.*?)(?=\n\s*case )', source, re.S)
    if match is None or not re.search(r'showSystemUiMode\(mode\);\s*result\.success\(null\);', match[1]):
        raise ValueError("Fullscreen mode request lacks its native completion reply")
    with har.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    return {"har": har.name, "sha256": digest, "fullscreenReply": True, "deviceTested": False}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("har", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    text = json.dumps(inspect(args.har), indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    print(text)
