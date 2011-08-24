Rubber
======
Notes for nerds
---
* * *

Rubber is a note taking app optimized for use with a combination of mathematical markup, code, and text. It aims to make taking notes in lectures for engineering courses markedly easier by adding assorted niceties and removing sources of note taking friction. Specifically, Rubber:

* Autosuggests word completions automatically, like code completion in an IDE
* Allows math to be instantly rendered inline from LaTeX or ASCII math markup
* Supports inline syntax highlighting for code
* Preserves indentation levels and offers keyboard shortcuts for indenting/dedenting
* Automatically inserts matching brackets after the insertion point for easy nesting of parenthetical remarks
* Uses columns and nice typography to make reading notes easier and more pleasant
* Takes advantage of new technologies in Mac OS X Lion, including document versioning and autosave, fullscreen mode, sandboxing, XPC, and ARC

Additional planned features include:

* Keyboard shortcuts for scrolling/navigation
* Support for many Emacs keyboard shortcuts
* Support for iCloud
* Ability to compile and run inline code
* Support for external editors for inline code

Building Rubber
---------------
* * *
Rubber is mostly self-contained, but the source-highlight library depends on the C++ Boost library. This is easily obtained with [Homebrew](https://github.com/mxcl/homebrew "Homebrew") by running `brew install boost`. After installing it, you should be able to open and build Rubber in Xcode without any problems.

System Requirements
-------------------
* * *
Rubber takes advantage of many Mac OS X Lion features, and consequently requires OS X 10.7 or newer to run.

License
-------
* * *
Rubber is made available under the terms of the BSD license, with the exception of the hilite XPC service. Due to its dependency on the source-highlight library, the hilite XPC service is licensed under the GPLv3.