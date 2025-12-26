#! /usr/bin/python3

import os
import sys
import re
import pathlib

import alfred
import url_item

alfred.pipeline(
        [
            "./chrome_tabs.js",
            ],
        chunker = alfred.JSONChunker(
            lambda x: url_item.Item(
                x["title"],
                x["url"],
                ),
            ),
        )
