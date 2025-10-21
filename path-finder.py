#!/usr/bin/env python3
import os
import json
from collections import defaultdict
from dotenv import load_dotenv

# --- Load variables from .env if present ---
load_dotenv()

# Base path relative to project root or from DATA_PATH in .env
data_path = os.getenv("DATA_PATH", "./")
base_dir = os.path.join(data_path, "data", "Delivery")
output_dir = os.path.join("webroot", "idx")

# Dictionary for grouping files by 7-character prefix
shards = defaultdict(dict)

# Walk through all subdirectories under base_dir
for root, _, files in os.walk(base_dir):
    for file in files:
        if file.endswith(".jp2"):
            relative_path = os.path.relpath(root, base_dir)
            key = os.path.splitext(file)[0]  # remove ".jp2"
            shard_key = key[:7]              # e.g. "GB-0517"
            shards[shard_key][key] = relative_path.replace("\\", "/")

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

# Write one JSON file per shard
total_files = 0
for shard_key, entries in shards.items():
    shard_path = os.path.join(output_dir, f"{shard_key}.json")
    with open(shard_path, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2, ensure_ascii=False)
    total_files += len(entries)
    print(f"{shard_path} → {len(entries)} entries")

print(f"\nTotal {total_files} .jp2 files split into {len(shards)} shard(s)")
