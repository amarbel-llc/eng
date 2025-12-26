#! /usr/bin/env /Users/sasha/Zettelkasten/1630272875.js

const lib = require("~/Zettelkasten/1630272891.js");

function main(argv) {
  const things = Application("Things3");
  things.includeStandardAdditions = true

  const inbox = things.lists.byName(argv[1]);
  const todos = inbox.toDos();

  // for (const l of lists) {
  //   lib.log(l.name() + "\n");
  // }

  // const todos = things.toDos.id();
  // let names = [];
  // const output = [];

  for (const t of todos) {
    const a = t.area();
    let area = "";

    if (a != null) {
      area = a.name();
    }

    lib.log(JSON.stringify({
      id: t.id(),
      name: t.name(),
      area: area,
      notes: t.notes(),
      tags: t.tagNames().split(","),
    }));
    lib.log("\n");
  }

  //when iterating via for..in, arrays are 1-indexed
  //when accessing via [] syntax, arrays are 0-indexed
  // lib.log("[");
  // lib.log(output);
  // lib.log("]");
}

exports.main = main;

