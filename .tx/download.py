#!/usr/bin/env python3

import os
import sys
import shutil
import json
import glob
import subprocess
import xml.dom.minidom as minidom
from collections import OrderedDict

XCFILES_DIR = "../"
TMP_DIR = "./tmp"


##################################
#
class Error(Exception):
    pass


##################################
#
def find_xcstrings_files(dir):
    res = []
    for f in glob.glob("**/*.xcstrings", root_dir=dir, recursive=True):
        res.append(f"{dir}/{f}")
    return res


##################################
#
def set_deep(d, keys, value):
    for key in keys[:-1]:
        d = d.setdefault(key, {})
    d[keys[-1]] = value


##################################
#
def remove_stale_strings(xcstrings_file):
    with open(xcstrings_file) as r:
        xcstrings = json.load(r)

    remove = []
    for key, value in xcstrings["strings"].items():
        if value.get("extractionState") == "stale":
            remove.append(key)

    for key in remove:
        print(f"Remove stale: {key}")
        del xcstrings["strings"][key]


##################################
#
def parse_icu_plurals(str):
    res = {}
    level = 0
    key = ""
    b = 0
    for i in range(0, len(str)):
        c= str[i]

        if c == '{':
            level += 1
            if level == 1:
                key = str[b:i].strip()
                b = i + 1

        if c == '}':
            level -= 1
            if level == 0:
                res[key] = str[b:i]
                b = i + 1

    return res


##################################
#
def js_to_xscting(str):
    if not str.startswith("{lld, plural,"):
        return {
            "stringUnit" : {
                "state" : "translated",
                "value" : str,
            }
        }


    str = str[len("{lld, plural,"):].strip()[:-1]

    items = parse_icu_plurals(str)


    plural = {}
    for k in sorted(items.keys()):
        str = items.get(k)
        if str == None:
            continue

        str = str.replace("{lld}", "%lld")

        plural[k] = {
            "stringUnit": {
                "state": "translated",
                "value": str
            }
        }

    return {
        "variations" : {
            "plural" : plural
        }
    }


##################################
#
def update_file(lang, xcstrings_file, json_file):
    with open(xcstrings_file) as r:
        xcstrings = json.load(r)

    # merge from json to xcstrings
    with open(json_file) as r:
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

        set_deep(xcstrings, ["strings", key, "localizations", lang], js_to_xscting(tr["string"]))


    with open(xcstrings_file, 'w', encoding='utf-8') as f:
        json.dump(xcstrings, f, ensure_ascii=False, sort_keys=False, indent=2, separators=(',', ' : '))



##################################
#
def pull_translations():
    args = [
        "tx",
        "pull",
        "--all",
        "--force",
    ]

    subprocess.run(args)



##################################
#
if __name__ == "__main__":
    try:
        shutil.rmtree(TMP_DIR, ignore_errors=True)
        pull_translations()
        xcstrings_files = find_xcstrings_files("..")

        for xcstrings_file in xcstrings_files:
            remove_stale_strings(xcstrings_file)

            for lang in glob.glob("*", root_dir=TMP_DIR):

                name = os.path.splitext(os.path.basename(xcstrings_file))[0]
                update_file(lang, xcstrings_file, f"{TMP_DIR}/{lang}/{name}.json")

    except KeyboardInterrupt:
        sys.exit(0)

    except Error as err:
        sys.exit(err)
        sys.exit(1)
