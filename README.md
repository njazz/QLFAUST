# QLFAUST

QuickLook plugin for FAUST Programming Language

## Features
- Syntax highlighting for **FAUST DSP code**.
- Supports highlighting for:
  - **Keywords**: `process`, `let`, `import`, `component`, `where`, `letrec`, etc.
  - **Data types**: `int`, `float`.
  - **Strings**: Strings enclosed in double quotes.
  - **Numbers**: Integer and floating-point numbers.
  - **Faust Composition Operators**: `:<`, `:>`, `~`, `:`
  - **Mathematical operators**: `+`, `-`, `*`, `/`, etc.
  - **Comments**: Both line (`//`) and block (`/* */`) comments.
- **Monospaced font** for easy reading of Faust code.
- Distinct color coding for each type of code element (e.g., keywords, strings, operators, comments).

Current version: 0.0.1

macOS 12+

## ROADMAP
- [ ] Implement support for additional Faust library functions.
- [ ] Add line numbering to the preview.
- [ ] Refactor to support custom themes for syntax highlighting.
- [ ] Improve performance when handling large Faust files.
- [ ] libfaust integration

---
FAUST Programming language:
https://github.com/grame-cncm/faust
