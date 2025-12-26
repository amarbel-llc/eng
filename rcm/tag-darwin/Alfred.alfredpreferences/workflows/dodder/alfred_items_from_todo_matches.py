#! /usr/bin/python3

import os
import sys
import re
from datetime import datetime
from pathlib import PurePosixPath

import alfred
import babel.dates

grep_pattern = re.compile(r'^(.*?):\d+:\d+:(.*)')
archive_file_pattern = re.compile(r'^\d+')
text_todo_pattern = re.compile(r'#todo: ')

class Item(dict):
    def __init__(self, c):
        dict.__init__(self)

        match =  grep_pattern.match(c)

        raw_path = match.group(1)
        path = PurePosixPath(raw_path)
        item_text = match.group(2)

        title = text_todo_pattern.sub('', item_text)
        file_title = archive_file_pattern.sub('', path.name)
        uid_match = archive_file_pattern.match(path.name)
        uid = ""
        formatted_date = ""
        zettel_id = ""

        if uid_match:
            zettel_id = uid_match.group()
            uid = f"archive.{zettel_id}"
            zettel_date = datetime.strptime(zettel_id, "%Y%m%d%H%M")
            formatted_date = babel.dates.format_datetime(zettel_date, locale='en_US')

        with open(raw_path) as f:
            url = f.readline().strip()

        self["title"] = title
        self["subtitle"] = f"{formatted_date}, {file_title}"
        self["uid"] = uid
        self["match"] = title + " " + file_title
        self["arg"] = f"thearchive://match/{zettel_id}"

alfred.pipeline(
        [
            "ag",
            "--vimgrep",
            '#todo(?![\w-])',
            os.environ["ZETTEL_PATH"],
            ],
        [
            "ag",
            "-v",
            '@done',
            ],
        item_class = Item
        )
