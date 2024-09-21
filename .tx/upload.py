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
    for f in glob.glob("**/*.xcstrings", root_dir=dir, recursive=True):
        res.append(f"{dir}/{f}")
    return res

def extract_source(in_file, out_dir):
    name = os.path.splitext(os.path.basename(file))[0]
    out_file = f"{TMP_DIR}/{name}.json"

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


def extract_lang(in_file, out_dir, lang):
    name = os.path.splitext(os.path.basename(file))[0]
    os.makedirs(f"{out_dir}/{lang}", exist_ok=True)
    out_file = f"{out_dir}/{lang}/{name}.json"

    with open(in_file) as r:
        xcstrings = json.load(r)

    data = {}
    for key, value in xcstrings["strings"].items():

        try:
            tr = value["localizations"]["ru"]["stringUnit"]
        except KeyError:
            continue

        context = value.get("comment", "")

        item ={
            "string": tr["value"],
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

def push_lang(lang):
    args = [
        "tx",
        "push",
        "--translation",
        "--languages",
        lang,
    ]

    subprocess.run(args)

if __name__ == "__main__":
    try:
        shutil.rmtree(TMP_DIR, ignore_errors=True)
        os.makedirs(TMP_DIR, exist_ok=True)

        xcstrings_files = find_xcstrings_files("..")

        for file in xcstrings_files:
            extract_source(file, TMP_DIR)

            for lang in sys.argv[1:]:
                extract_lang(file, TMP_DIR, lang)

        push_source()

        for lang in sys.argv[1:]:
            push_lang(lang)

    except KeyboardInterrupt:
        sys.exit(0)

    except Error as err:
        sys.exit(err)
        sys.exit(1)
