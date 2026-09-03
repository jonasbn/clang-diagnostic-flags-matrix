# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single Perl script (`diags.pl`) that scrapes the Clang `DiagnosticsReference.html`
page for each LLVM release, extracts the command-line diagnostic flags (any link text
starting with `-`), and prints a Markdown matrix to STDOUT: one column per Clang
version, one row per flag, with a linked `X` where that flag exists in that version.
The generated output lives in `matrix.md` and feeds jonasbn's TIL collection.

There is no test suite, linter config, or CI.

## Commands

```bash
carton                                    # install deps from cpanfile / cpanfile.snapshot into local/
carton exec -- perl diags.pl > matrix.md  # regenerate the matrix (makes ~20 HTTP requests to releases.llvm.org)
```

Dependencies (`cpanfile`): Mojolicious (`Mojo::UserAgent` + `Mojo::DOM`), IO::Socket::SSL.
`local/` is carton's install tree; it is gitignored but committed here.

## The recurring maintenance task

Nearly every commit adds a new Clang release. To do that:

1. Add one entry to the `%urls` hash in `diags.pl` — key is the full semver string
   (e.g. `'23.1.0'`), value is the `https://releases.llvm.org/<version>/tools/clang/docs/DiagnosticsReference.html` URL.
2. Regenerate `matrix.md` with the command above and commit both files.

## Architecture notes / gotchas

- **Version-dependent DOM selector** (`_parse_result`): the LLVM docs HTML changed
  structure at major version 11. Flags are matched with `li > a` for major < 11 and
  `li > p > a` for major >= 11. A new major version that changes the markup again
  needs a new branch here.
- **Anchor generation is a heuristic** (marked `HACK`): the per-flag URL anchor is
  built as `lc` of the flag name minus its leading `-`. It breaks silently if LLVM's
  anchor naming diverges from that.
- **URL shortening** (`_shorten_url`, toggled by `$use_short_url`): full
  `releases.llvm.org/.../DiagnosticsReference.html#anchor` URLs are rewritten to
  `https://pxy.fi/<major>/<anchor>`. This keeps `matrix.md` small enough that GitHub's
  Markdown renderer doesn't choke. `pxy.fi` is a redirect proxy (repo:
  `jonasbn/pxy-redirect`) that reverses the translation.
- **`$use_emoji`** (default off): switches cell markers between `X`/`-` and ✅/❌.
- **Sorting** is by major version number only (`($a =~ m/^(\d+)\./)[0] <=> ...`),
  not full semver.
- Known data quirk carried in `%urls`: the `9.0.0` key points at the `10.0.0` URL.
- `prototypes/` holds throwaway scripts (major-number extraction, URL shortening,
  version sorting) that were prototyped separately and folded into `diags.pl`. They
  are not part of the pipeline.
