#! /usr/bin/python3

import json
import os
import sys
import re

from pathlib import PurePosixPath

class PBFile(dict):
    def __init__(self, c):
        dict.__init__(self)

        path = PurePosixPath(c)

        name = path.stem

        pattern = r'^(\d+) pb:'
        title = re.sub(pattern, '', name)
        uid_match = re.match(pattern, name)
        uid = ""

        if uid_match:
            uid = "archive.pb." + uid_match.group(1)

        url = ""

        with open(path) as f:
            url = f.readline().strip()

        self["title"] = title
        self["subtitle"] = ""
        self["uid"] = uid
        self["match"] = name
        self["arg"] = url

items = [PBFile(f.strip()) for f in sys.stdin]

print(json.dumps({'items': items}))
