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

class Item:
    ##############################
    #
    def __init__(self, key, data):
        self.key     = key
        self.json    = data
        self.comment = data.get("comment", "")
        self.localizations = data.get("localizations", "")


    ##############################
    #
    def source_string(self):
        if self._key_exists(["localizations", "en", "variations", "plural"]):
            return self._variations_string("en")

        res = ""
        if self._key_exists(["localizations", "en", "stringUnit"]):
            res = self._get(["localizations", "en", "stringUnit", "value"])
        else:
            res = self.key

        return self._plural_str(res)


    ##############################
    #
    def translation_string(self, lang):
        if self._key_exists(["localizations", lang, "variations", "plural"]):
            return self._variations_string(lang)

        res = self._get(["localizations", lang, "stringUnit", "value"])

        if res == None:
            return None

        return self._plural_str(res)


    ##############################
    #
    def _variations_string(self, lang):
        plural = self.json["localizations"][lang]["variations"]["plural"]

        items = []
        for k, v in plural.items():
            s = v["stringUnit"]["value"]
            s = s.replace("%lld", "{lld}")
            items.append("%s {%s}" % (k, s))

        return "{lld, plural, " + " ".join(items) + "}"


    ##############################
    #
    def _plural_str(self, str):
        if "%lld" in str:
            res = str.replace("%lld", "{lld}")
            return "{lld, plural, one {" + res + "} other {" + res +"}}"

        return str


    ##############################
    #
    def _key_exists(self, key):
        v = self.json
        for k in key:
            v = v.get(k)
            if v == None:
                return False

        return True


    ##############################
    #
    def _get(self, key):
        res = self.json
        for k in key:
            res = res.get(k)
            if res == None:
                return None

        return res


##################################
#
def load_xcstrings(file):
    with open(file) as r:
        xcstrings = json.load(r)

    res = []
    for key, data in xcstrings["strings"].items():
        res.append(Item(key, data))

    return res


##################################
#
def extract_source(in_file, out_dir):
    name = os.path.splitext(os.path.basename(file))[0]
    out_file = f"{TMP_DIR}/{name}.json"

    xcstrings = load_xcstrings(in_file)

    res = {}
    for xcs in xcstrings:
        res[xcs.key] = {
            "string": xcs.source_string(),
            "context": xcs.comment,
            "developer_comment": xcs.comment,
        }

    with open(out_file, 'w', encoding='utf-8') as f:
        json.dump(res, f, ensure_ascii=False, indent=4)



##################################
#
def extract_lang(in_file, out_dir, lang):
    name = os.path.splitext(os.path.basename(file))[0]
    os.makedirs(f"{out_dir}/{lang}", exist_ok=True)
    out_file = f"{out_dir}/{lang}/{name}.json"

    xcstrings = load_xcstrings(in_file)

    res = {}
    for xcs in xcstrings:
        str = xcs.translation_string(lang)

        if str == None:
            continue

        res[xcs.key] = {
            "string": xcs.translation_string(lang),
            "context": xcs.comment,
            "developer_comment": xcs.comment,
        }

    with open(out_file, 'w', encoding='utf-8') as f:
        json.dump(res, f, ensure_ascii=False, indent=4)


##################################
#
def push_source():
    args = [
        "tx",
        "push",
        "--source",
    ]

    subprocess.run(args)


##################################
#
def push_lang(lang):
    args = [
        "tx",
        "push",
        "--translation",
        "--languages",
        lang,
    ]

    subprocess.run(args)


##################################
#
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
            pass

    except KeyboardInterrupt:
        sys.exit(0)

    except Error as err:
        sys.exit(err)
        sys.exit(1)
