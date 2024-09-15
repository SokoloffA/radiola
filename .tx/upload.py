#!/usr/bin/env python3

import os
import sys
import shutil
import json
import glob
import subprocess
import xml.dom.minidom as minidom

TMP_DIR = "./tmp"

class Error(Exception):
    pass

def find_xcstrings_files(dir):
    res = []
    for f in glob.glob("*.xcstrings", root_dir=dir):
        res.append(f"{dir}/{f}")
    return res

def extract_source(in_file, out_file):

    with open(in_file) as r:
        xcstrings = json.load(r)

    data = {}
    for key, value in xcstrings["strings"].items():

        if value.get("extractionState") == "stale":
            continue

        try:
            src = value["localizations"]["en"]["stringUnit"]["value"]
        except KeyError:
            src = key

        context = value.get("comment", "")

        item ={
            "string": src,
            "context": context,
            "developer_comment": context,
        }
        data[key] = item


    with open(out_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)


def push_source():
    args = [
        "tx",
        "push",
        "--source",
    ]

    subprocess.run(args)


if __name__ == "__main__":
    try:
        xcstrings_files = find_xcstrings_files("..")
        for file in xcstrings_files:
            name = os.path.splitext(os.path.basename(file))[0]
            json_file = f"{TMP_DIR}/{name}.json"
            extract_source(file, json_file)

        push_source()

    except KeyboardInterrupt:
        sys.exit(0)

    except Error as err:
        sys.exit(err)
        sys.exit(1)
