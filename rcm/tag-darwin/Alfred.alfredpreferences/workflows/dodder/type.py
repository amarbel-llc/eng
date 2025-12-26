#! /usr/bin/python3

import os
import sys
import re
import babel.dates
from datetime import datetime, timedelta
from pathlib import PurePosixPath

import alfred

ptn_xargs_header = re.compile(r'==>.*\/(?P<ts>\d+)\s+(?P<title>.*)\.\w+\s+<==')
ptn_tags = re.compile(r'(?:\W|^)#(?P<tag>[-\w_]+)\b')

class Item(dict):
    def __init__(self, lines):
        dict.__init__(self)
        head_match = re.match(ptn_xargs_header, lines[0])
        tail_matches = re.findall(ptn_tags, lines[1])

        url = None

        try:
            url = lines[2]
        except IndexError:
            pass

        title = "not set"
        ts = ""
        uid = ""
        formatted_date = ""
        subtitle = "not set"
        arg = "not set"
        zettel_id = "not set"
        error = None

        try:
            title = head_match.groupdict()['title']
            zettel_id = head_match.groupdict()['ts']
            uid = f"zettel.{zettel_id}"
            zettel_date = datetime.fromtimestamp(int(zettel_id))
            # zettel_date = time.ctime(zettel_id)
            formatted_date = babel.dates.format_date(zettel_date, locale='en_US')
        except AttributeError as e:
            print(lines[0], file = sys.stderr)
            title = lines[0]
            error = str(e)

        subtitle = ' '.join([f'#{m}' for m in tail_matches])

        if url is not None and "kind-pb" in tail_matches:
            arg = url
        else:
            arg = f"thearchive://match/{zettel_id}"

        self["title"] = title
        self["uid"] = uid
        self["match"] = alfred.match_terms(title + " " + lines[1])
        self["arg"] = arg

        if error is None:
            tag_list = ' '.join([f'#{m}' for m in tail_matches])
            if len(tag_list) == 0:
                self["subtitle"] = formatted_date
            else:
                self["subtitle"] = f"{formatted_date}, {tag_list}"
        else:
            self["subtitle"] = error

class Chunker(alfred.Chunker):
    def __init__(self):
        self.acc = []

    def process_line(self, line):
        try:
            line = line.decode("utf-8").strip()
        except AttributeError as e:
            pass

        if len(self.acc) > 0 and self.is_head_line(line):
            self.outputter.item(Item(self.acc))
            self.acc = [line]
        else:
            self.acc.append(line)

    def is_head_line(self, line):
        return line.startswith('==>') and line.endswith('<==')


alfred.pipeline(
        [
            'find',
            os.path.realpath(os.path.expanduser(os.environ['ZETTEL_PATH'])),
            '-type',
            'f',
            '(',
            '-iname',
            '*.md',
            '-o',
            '-iname',
            '*.txt',
            ')',
            '-print0',
            ],
        [
            'xargs',
            '-0',
            'head',
            '-2',
            ],
        chunker = Chunker(),
        )
