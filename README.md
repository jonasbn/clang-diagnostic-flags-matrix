# clang diagnostic flags matrix generator

A simple script to generate a matrix of clang diagnostic flags.

[![Better Uptime Badge](https://betteruptime.com/status-badges/v1/monitor/otgy.svg)](https://status.pxy.fi/?utm_source=status_badge)

## Introduction

I created this application to support a _today I learned_ (TIL) note on what diagnostic flags are available in which version. The matrix is published:

- [My TIL collection GitHub website][tilgh] (_recommended_)
- [My TIL collection: GitHub pages site][tilghp]

The matrix does not contain information for all versions of clang and the matrix may contain errors if the code is not working as expected.

The URL do not point directly to the [llvm releases documentation site][LLVM], they point to a proxy. The reason for this was that the Markdown rendering broke on the GitHub website.

In order to cut the size of the matrix, I introduced the use of a proxy, which takes a short form of the URL translates to the full URL.

Example:

- `https://pxy.fi/5/rsanitize-address`

It emitted by the clang diagnostic flags matrix generator (`diag.pl`). Parsed from:

- `https://releases.llvm.org/5.0.0/tools/clang/docs/DiagnosticsReference.html#rsanitize-address`

As part of the data collection fase.

The proxy reverts this translation and redirects to the proper page. I have published a [blog post](https://dev.to/jonasbn/challenges-solutions-and-more-challenges-and-more-solutions-4j3f), giving some more details.

## Usage

```bash
carton exec -- perl diag.pl > matrix.md
```

## Installation

All requiresments are listed in the `cpanfile`, so installation can be performed easilyusing `carton`:

```bash
carton
```

A generated version of the matrix is [available][tilghp].

## Resources and References

- [My TIL collection: clang diagnostic flags][tilgh] (GitHub)
- [My TIL collection: clang diagnostic flags][tilghp] (website)
- [pxy-redirect][pxy-redirect]
- [llvm releases documentation site][LLVM]
- [pxy.fi]

[LLVM]: https://releases.llvm.org/
[pxy.fi]: https://pxy.fi/
[pxy-redirect]: https://github.com/jonasbn/pxy-redirect
[tilgh]: https://github.com/jonasbn/til/blob/master/clang/diagnostic_flags.md
[tilghp]: http://jonasbn.github.io/til/clang/diagnostic_flags.html
