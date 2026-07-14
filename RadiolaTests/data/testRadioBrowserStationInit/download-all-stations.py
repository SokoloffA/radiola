#!/usr/bin/env python3

import json
import os
import urllib.request

API_URL = "http://de1.api.radio-browser.info/json/stations?limit=999999"
INPUT_FILE = "radio-browser.stations.json.tmp"
OUTPUT_PREFIX = "tmp_"
DIGITS = 5

def download(url: str, dest: str) -> None:
    print(f"Downloading {url} ...")
    req = urllib.request.Request(url, headers={"User-Agent": "split-stations/1.0"})
    with urllib.request.urlopen(req) as resp, open(dest, "wb") as f:
        total = int(resp.headers.get("Content-Length", 0))
        downloaded = 0
        chunk = 1024 * 256  # 256 KB
        while True:
            block = resp.read(chunk)
            if not block:
                break
            f.write(block)
            downloaded += len(block)
            if total:
                pct = downloaded * 100 // total
                print(f"\r  {downloaded // 1024 // 1024} MB / {total // 1024 // 1024} MB ({pct}%)", end="", flush=True)
    print(f"\nSaved to {dest}")


def split(src: str) -> None:
    print(f"Loading {src} ...")
    with open(src, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        print("Error: the root element is not an array.")
        return

    total = len(data)
    print(f"Total stations: {total}")

    for idx, obj in enumerate(data, start=1):
        filename = f"{OUTPUT_PREFIX}{idx:0{DIGITS}d}.json"
        with open(filename, "w", encoding="utf-8") as out:
            json.dump(obj, out, indent=2, ensure_ascii=False)
        if idx % 1000 == 0 or idx == total:
            print(f"  Processed {idx} of {total}")

    print("Done.")



def main():
    if not os.path.exists(INPUT_FILE):
        download(API_URL, INPUT_FILE)
    else:
        print(f"File {INPUT_FILE!r} already exists, skipping download.")

    split(INPUT_FILE)



# def main():
#     with open(INPUT_FILE, 'r', encoding='utf-8') as f:
#         data = json.load(f)

#     if not isinstance(data, list):
#         print("Error: the root element is not an array.")
#         return

#     total = len(data)

#     for idx, obj in enumerate(data, start=1):
#         filename = f"{OUTPUT_PREFIX}{idx:0{DIGITS}d}.json"
#         with open(filename, 'w', encoding='utf-8') as out:
#             json.dump(obj, out, indent=2, ensure_ascii=False)
#         #if idx % 1000 == 0:
#         print(f"Processed {idx} of {total}")

#     print("Done.")

if __name__ == "__main__":
    main()
