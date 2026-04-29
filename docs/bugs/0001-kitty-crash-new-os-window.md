---
date: 2026-04-24
app: kitty 0.46.2
os: macOS 15.7.5 (ARM64)
status: unresolved
---

# kitty crash on new-os-window command

## Summary

kitty 0.46.2 crashes with SIGSEGV when running the `new-os-window` command.
No newer release available as of 2026-04-24 (0.46.2 is latest).

## Exception

```
Exception Type:  EXC_BAD_ACCESS (SIGSEGV)
Exception Code:  KERN_INVALID_ADDRESS at 0x0000000000000010
```

Null pointer dereference — attempted to read 16 bytes into a nil object.

## Crash location

Thread 0 (main thread) crashed in `objc_msgSend` sending the selector
`setCollectionBehavior:` — an `NSWindow` API used to configure whether a
window appears on all Spaces. The window object was nil or already deallocated
at the time of the call.

Relevant stack frames:

```
0  libobjc.A.dylib       objc_msgSend + 32          (selector: setCollectionBehavior:)
1  libdispatch.dylib     _dispatch_call_block_and_release + 32
...
15 kitty.glfw-cocoa.so   glfwRunMainLoop + 104
16 kitty.fast_data_types.so
```

## Theory

During new OS window creation, kitty's macOS GLFW backend dispatches a block
that calls `setCollectionBehavior:` on a window object that has gone nil (race
condition or lifecycle issue in the window creation path).

## No matching upstream issue found

Searched kovidgoyal/kitty for SIGSEGV + new-window + setCollectionBehavior.
Closest open issue was #8437 (crash on new window with `input_delay 0`) but
that has a different trigger and stack.

## Next steps

- Check if `input_delay` setting has any effect on reproduction
- Consider filing upstream with this crash report if reproducible
