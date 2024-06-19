#!/usr/bin/env python3

import urllib.request
import contextlib
import argparse
import datetime


def poll_radio(url):
    request = urllib.request.Request(url, headers = {
        'User-Agent' : 'User-Agent: VLC/2.0.5 LibVLC/2.0.5',
        'Icy-MetaData' : '1',
        'Range' : 'bytes=0-',
    })
    # the connection will be close on exit from with block
    with contextlib.closing(urllib.request.urlopen(request)) as response:

        meta_interval = int(response.getheader("icy-metaint"))
        print(":::::::::::::::::::::::::::::::::::::::::::::")
        for h in response.getheaders():
            print(f"{h[0]}: {h[1]}")
        print(".............................................")


        while True:
            response.read(meta_interval) # throw away the data until the meta interval

            length = ord(response.read(1)) * 16 # length is encoded in the stream
            if length > 0:
                metadata = response.read(length)
                print(datetime.datetime.now(), ":", metadata)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description = "Read ICY metadata from stream.")

    parser.add_argument(
        'url',
        metavar='URL',
        type=str,
        nargs=1,
        help='stream URL')

    args = parser.parse_args()

    try:
        poll_radio(args.url[0])
    except KeyboardInterrupt:
        exit(0)
