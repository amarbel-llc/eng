#! /usr/bin/python3

import os
import sys
import pathlib

import alfred
import url_item

chrome_path = "~/Library/Application Support/Google/Chrome/"
abs_path = os.path.realpath(os.path.expanduser(chrome_path))
base_path = pathlib.Path(abs_path)

paths = [p.absolute().as_posix() for p in base_path.glob('*/Bookmarks')]

alfred.pipeline(
        [
            'jq',
            '.. | .children? | arrays | .[] | select(.type == "url")',
            "--compact-output",
            *paths,
            ],
        [
            "jq",
            "-s",
            ".",
            ],
        #jq --stream "if .[0][-3] == \"children\" and ( .[0][-1] == \"url\" or .[0][-1] == \"name\") then .[1] else null end"
        # [
        #     'osascript',
        #     'chrome_bookmarks.scpt',
        #     ],
        chunker = alfred.JSONChunker(
            lambda x: url_item.Item(
                x["name"],
                x["url"],
                ),
            ),
        )
