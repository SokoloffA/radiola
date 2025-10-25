#!/usr/bin/env python3
# v 0.2

GITHUB_USER = "SokoloffA"
GITHUB_REPO = "radiola"
PROGRAM_NAME = "Radiola"

FEED_FILE = "feed.xml"
FEED_DESCRIPTION = "Most recent updates to "
FEED_LANGUAGE    = "en"
MIN_VERSION = "3.0"

#######################################
URL_TEMPLATE = "https://api.github.com/repos/%s/%s/releases"

import sys
import os
import urllib.request
import json
import re
from xml.dom import minidom
import datetime
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)) + '/libs/')
import markdown


class Error(Exception):
    pass

class Version(tuple):
    def __new__(cls, s):
        parts = tuple(map(int, s.split(".")))
        return super().__new__(cls, parts)


def versiontuple(str):
    return tuple(map(int, (str.split("."))))

class Release:
    def __init__(self, data):
        self.tag = data["tag_name"]
        self.version = self.extractVersion(self.tag)
        self.prerelease = data["prerelease"]
        self.name = PROGRAM_NAME
        self.url = self.getUrl(data)
        self.changeLog = data["body"]
        self.date = datetime.datetime.strptime(data["published_at"], '%Y-%m-%dT%H:%M:%SZ')


    def extractVersion(self, tag):
        s = tag

        res = re.search(r"-beta\d+", s)
        if res:
            s = s[:res.start()]

        PREFIXES = [
            "v",
            "v.",
            f"{GITHUB_REPO}-",
        ]

        for p in sorted(PREFIXES, key=len, reverse = True):
            if s.startswith(p):
                s = s[len(p):]
                break

        if (re.match(r"[\d\.]+$", s)):
            return s

        raise Error(f"Can't extract version from '{tag}' tag")

    def getUrl(self, data):
        for asset in data["assets"]:
            if asset["browser_download_url"].endswith(".dmg"):
                return asset["browser_download_url"]

        return None


def download(url):
    try:
        response = urllib.request.urlopen(url)
        res = response.read().decode('utf-8')
        return json.loads(res)

    except urllib.error.HTTPError as err:
        raise Error("Can't download from %s: %s" % (url, err))


def parse(data):
    releases = []
    for d in data:
        release = Release(d)
        releases.append(release)


    return releases

def write(releases):
    doc = minidom.Document()

    def add(parent, tag):
        node = doc.createElement(tag)
        parent.appendChild(node)
        return node


    def addText(parent, tag, text):
        node = add(parent, tag)
        node.appendChild(doc.createTextNode(text))
        return node


    rss = add(doc, "rss")
    rss.setAttribute("version", "2.0")
    rss.setAttribute('xmlns:sparkle', "http://www.andymatuschak.org/xml-namespaces/sparkle")

    channel = add(rss, "channel")

    add(channel, "title")
    addText(channel, "description", FEED_DESCRIPTION)
    addText(channel, "language", FEED_LANGUAGE)

    min_version = Version(MIN_VERSION)
    for r in releases:

        if  Version(r.version) < min_version:
            continue

        if r.prerelease:
            continue

        if not r.url:
            continue

        description = markdown.markdown(r.changeLog, tab_length=2)

        item = add(channel, "item")
        addText(item, "title", f"{PROGRAM_NAME} {r.version}")
        addText(item, "description", description)
        addText(item, "pubDate", r.date.strftime("%a, %d %b %Y %H:%M:%S +0000"))

        enclosure = add(item, "enclosure")
        enclosure.setAttribute("url", r.url)
        enclosure.setAttribute("sparkle:version", r.version)
        enclosure.setAttribute("length", "0")
        enclosure.setAttribute("type", "application/octet-stream")

        # print(f"<h2>{PROGRAM_NAME} {r.version}</h2")
        # print(description)
        # print("<hr>")

    f =  open(FEED_FILE, "wb")
    f.write(doc.toprettyxml(indent ="  ", encoding="UTF-8"))
    f.close()



if __name__ == "__main__":

    try:
        data = download(URL_TEMPLATE % (GITHUB_USER, GITHUB_REPO))
        releases = parse(data)
        write(releases)

    except Error as err:
        print("Error: %s" % err, file=sys.stderr)
