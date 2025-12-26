#! /usr/bin/python3

import os
import sys
import re
import glob
import subprocess
import babel.dates
from datetime import datetime, time, timedelta
from pathlib import PurePosixPath

import alfred

class Item(dict):
    def __init__(self, lines):
        dict.__init__(self)
        print(lines, file = sys.stderr)

        title = "not set"
        ts = ""
        uid = ""
        formatted_date = ""
        subtitle = "not set"
        arg = "not set"
        zettel_id = "not set"
        error = None
        search_matches = []

        try:
            match_dict = head_match.groupdict()
            title = match_dict['title']
            zettel_id = match_dict['ts']
            arg = lines[0]
            uid = f"zettel.{zettel_id}"
            zettel_date = datetime.fromtimestamp(int(zettel_id))
            formatted_date = babel.dates.format_date(zettel_date, locale='en_US')
            search_matches.append(title)
            search_matches.append(formatted_date)
            search_matches.append(match_dict['type'] or '')
        except AttributeError as e:
            print('"' + lines[0] + '"', file = sys.stderr)
            title = lines[0]
            error = str(e)

        # subtitle = ' '.join([f'#{m}' for m in tail_matches])

        self["title"] = title
        self["uid"] = uid
        # todo add type to match
        self["match"] = alfred.match_terms(' '.join(search_matches))
        self["arg"] = arg

        if error is None:
            self["subtitle"] = f"{formatted_date}"
        else:
            self["subtitle"] = error

# zettel_path = os.path.realpath(os.path.expanduser(os.environ['ZETTEL_PATH']))
print(zettel_path, file=sys.stderr)
command = os.path.join(zettel_path, "1622033013.awk")

print(subprocess.check_output([command] + glob.glob(f"{zettel_path}/*")),
file=sys.stderr)

# alfred.pipeline(
#         [command] + glob.glob(f"{zettel_path}/*"),
#         chunker = alfred.PandocYamlChunker
#         )
