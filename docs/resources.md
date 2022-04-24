---
hide:
  - navigation
---

# Resources 

## Source

[https://adaptivecloud.dev/primate/primate][source]

## Issues

You can submit bug reports or feature requests via our [issue tracker][issues].

## Writing modules

If you have an idea for a module that would be useful, feel free to implement
it.

We don't currently have an official mechanism for adding modules on top of
Primate, so your best go right now would be writing a new store (they are
[notoriously easy to replace][stores]). Make sure you
extend `Primate.Store`, as Primate checks that every instanced store derives
from it, but otherwise just experiment around. The Store API isn't set in stone
yet anyway.

A reference for writing a store is the built-in [MemoryStore][MemoryStore].

We recommend writing first a ad-hoc store as part of an app, and if it turns out
good, publishing it as a module.

[MemoryStore]:
https://adaptivecloud.dev/primate/primate/blob/master/source/server/store/Memory.js
[stores]: /guide/data/stores#ad-hoc-stores
[source]: https://adaptivecloud.dev/primate/primate
[issues]: https://adaptivecloud.dev/primate/primate/issues
