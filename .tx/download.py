#!/usr/bin/env python3

import os
import sys
import shutil
import json
import glob
import subprocess
import xml.dom.minidom as minidom

XCFILES_DIR = "../"
TMP_DIR = "./tmp"

class Error(Exception):
    pass

def update_lang(lang, dir):
    for json_file in glob.glob(f"{dir}/*.json"):
        update_file(lang, json_file)


def set_deep(d, keys, value):
    for key in keys[:-1]:
        d = d.setdefault(key, {})
    d[keys[-1]] = value

def update_file(lang, in_file):
    name = os.path.splitext(os.path.basename(in_file))[0]
    out_file = f"{XCFILES_DIR}/{name}.xcstrings"

    with open(out_file) as r:
        xcstrings = json.load(r)

    # Remove stale strings
    remove = []
    for key, value in xcstrings["strings"].items():
        if value.get("extractionState") == "stale":
            remove.append(key)

    for key in remove:
        print(f"Remove stale: {key}")
        del xcstrings["strings"][key]


    # merge from json to xcstrings
    with open(in_file) as r:
        translations = json.load(r)

    for key, tr in translations.items():
        try:
            value = xcstrings["strings"][key]
        except KeyError:
            continue

        try:
            src = value["localizations"]["en"]["stringUnit"]["value"]
        except KeyError:
            src = key

        if tr["string"] == src:
            continue


        set_deep(xcstrings, ["strings", key, "localizations", lang, "stringUnit", "state"], "translated")
        set_deep(xcstrings, ["strings", key, "localizations", lang, "stringUnit", "value"], tr["string"])


    with open(out_file, 'w', encoding='utf-8') as f:
        json.dump(xcstrings, f, ensure_ascii=False, indent=2, separators=(',', ' : '))


def pull_translations():
    args = [
        "tx",
        "pull",
        "--all",
        "--force",
    ]

    subprocess.run(args)


if __name__ == "__main__":
    try:
        shutil.rmtree(TMP_DIR)
        pull_translations()

        for lang in glob.glob("*", root_dir=TMP_DIR):
            print(f"Update {lang}")
            update_lang(lang, f"{TMP_DIR}/{lang}")

    except KeyboardInterrupt:
        sys.exit(0)

    except Error as err:
        sys.exit(err)
        sys.exit(1)
