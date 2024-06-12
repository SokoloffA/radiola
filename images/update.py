#!/usr/bin/env python3
# v 0.1

import sys
import os
from xml.dom import minidom


SOURCE_SVG = "source.svg"

OUT_IMAGES = {
    "../Radiola/Assets.xcassets/StatusBar/StatusBarPause.imageset/StatusBarPause.svg":         ["Stick", "Unmute Left", "Pause Right"],
    "../Radiola/Assets.xcassets/StatusBar/StatusBarPlay.imageset/StatusBarPlay.svg":           ["Unmute Left", "Play Right"],
    "../Radiola/Assets.xcassets/StatusBar/StatusBarPauseMute.imageset/StatusBarPauseMute.svg": ["Stick", "Mute Left", "Pause Right"],
    "../Radiola/Assets.xcassets/StatusBar/StatusBarPlayMute.imageset/StatusBarPlayMute.svg":   ["Mute Left", "Play Right"],
}

#######################################

class Error(Exception):
    pass

def create_svg(in_file, out_file, layers):
    print(f"  •  {out_file}")

    xml = minidom.parse(in_file)

    unused = layers

    svg=xml.getElementsByTagName('svg')[0]
    for g in svg.getElementsByTagName('g'):
        if (g.getAttribute("inkscape:groupmode") != "layer"):
            continue

        if not g.getAttribute("inkscape:label") in layers:
            g.parentNode.removeChild(g)
            continue

        unused.remove(g.getAttribute("inkscape:label"))
        style = g.getAttribute("style").split(";")

        if "display:none" in style:
            style.remove("display:none")

        if style == []:
            g.removeAttribute("style")
        else:
            g.setAttribute("style", ";".join(style))

    if unused != []:
        raise Error(f"Unknown layers {unused}" )


    out = open(out_file, "w")
    xml.writexml(out)
    out.close()

if __name__ == "__main__":

    try:
        for out in OUT_IMAGES:
            create_svg(SOURCE_SVG, out, OUT_IMAGES[out])

    except Error as err:
        print("Error: %s" % err, file=sys.stderr)
