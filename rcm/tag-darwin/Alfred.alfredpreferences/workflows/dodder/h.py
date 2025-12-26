#! /usr/bin/python3

import os
import sys
import sqlite3
import tempfile
import shutil
import pathlib
import re
import urllib.parse
import url_normalize

import alfred
import url_item

chrome_path = "~/Library/Application Support/Google/Chrome/Default/History"
abs_path = os.path.realpath(os.path.expanduser(chrome_path))
base_path = pathlib.Path(abs_path)

f = tempfile.NamedTemporaryFile('wb')
with open(base_path, 'rb') as a:
    shutil.copyfileobj(a, f)

c = sqlite3.connect(f.name)

with alfred.JSONOutputter() as out:
    for row in c.execute("select * from urls;"):
        out.item(url_item.Item(row[2], row[1]))



