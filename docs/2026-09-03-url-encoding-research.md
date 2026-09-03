# Research: shrinking `matrix.md` / shortening the generated URLs

**Date:** 2026-09-03
**Status:** research only — no decision made, no code changed
**Context:** `matrix.md` has grown to 873 KB. The concern is that the matrix
becomes too large to render / publish as more Clang releases are added. The
`pxy.fi` short-URL scheme was introduced for exactly this reason and we control
both ends of it (`diags.pl` `_shorten_url` and the Go proxy
`pxy-redirect-ow-function` `assembleTargetURL`).

---

## 1. The concrete size ceiling

| Surface | Threshold | Behaviour above it |
|---|---|---|
| GitHub repo front-page README | **512,000 bytes** | silently truncated, no warning |
| GitHub `.md` blob view (opening the file) | ~512 KB | "Sorry about that, but we can't show files that are this big right now" — no render |
| GitHub REST Markdown API | **400 KB** | request rejected outright |
| GitHub Pages / Jekyll (kramdown) | no hard byte cap | 900 KB table becomes multi-MB HTML; slow page, but it does build |

The TIL matrix is inlined into `til/clang/diagnostic_flags.md`, which is served
both through github.com's blob view (subject to the limits above) and through
GitHub Pages. This matches the origin story in this repo's README ("the Markdown
rendering broke on the GitHub website").

**Current state:** `matrix.md` is 873 KB — already ~1.7x past the 512 KB line.
Each new Clang release adds roughly one column ≈ ~50 KB.

**Target:** under **400 KB** to be safe on every surface (512 KB is the bare
minimum), and ideally restructure so future growth stops mattering.

Sources:
- <https://github.com/isaacs/github/issues/1610> (512,000-byte README truncation, confirmed by byte count)
- <https://github.com/github/markup/issues/1449> (blob-view render failure on large Markdown)
- <https://docs.github.com/en/rest/reference/markdown> (400 KB REST API limit)
- <https://github.com/Franck-Dernoncourt/github-max-file-size> (compilation of GitHub size limits)

---

## 2. Where the 873 KB actually goes (measured against the real corpus)

Parsed from the committed `matrix.md`:

- **20 version columns** (Clang 4 … 23) x **1,241 flag rows** → **18,266 populated cells**.
- **92.2 % of the file is link-destination text.** The table scaffolding
  (title, header row, separator, row labels, `-` for empty cells, `|`
  separators, newlines) is only **68.5 KB** total.
- Per-cell breakdown of `[X](https://pxy.fi/<major>/<anchor>)|`:

  | Part | Bytes | Share of file |
  |---|---|---|
  | anchor text (`wsome-flag`, mean 22.5 ch, max 65) | 388 KB | **44 %** |
  | `https://pxy.fi/` prefix | 274 KB | **31 %** |
  | `[X](` … `)\|` wrapper | 110 KB | 13 % |
  | version number + `/` | 51 KB | 6 % |

- **The anchor is 100 % redundant with the row label.** Every populated cell in
  a row links to `.../<major>/<same-anchor>`; the anchor is mechanically
  `lc(flag)` minus the leading `-` (with the proxy's existing `+`→`-` handling).
- **1,240 of 1,241 rows are a single contiguous run of `X`** — a flag is
  introduced at some version and then present in every later version. Only one
  row has a gap. This regularity is what makes the aggressive options possible.

Methodology: ad-hoc Perl parse of `matrix.md` (extract version list from the
header row, parse each `` |`flag`| `` row into a presence bit-vector plus its
anchor), then simulate each candidate encoding by re-emitting the file and
measuring the byte length. Scripts were throwaway; the numbers below are
reproducible by re-parsing `matrix.md` the same way.

---

## 3. Dead ends (verified, not assumed)

- **Reference-style Markdown links keyed per URL** — `[X][k]` inline plus a
  `[k]: <url>` definitions block. Result: **955 KB, larger than today.** Every
  (version x flag) URL is unique, so there is no reuse to exploit and the
  definitions block outweighs the inline text it removes.
- **Protocol-relative URLs (`//pxy.fi/…`) on their own** — 762 KB. A real ~13 %
  saving but nowhere near enough; still unrenderable.
- **HTML `<table>` + `<base href="https://pxy.fi/">` with `href="23/wfoo"`** —
  the `<td><a href>…</a></td>` tag overhead roughly cancels the dropped
  `https://pxy.fi/` prefix (net ~neutral, ~800 KB), and a `<base>` element
  inside a Jekyll page would rebase *every* relative link on the whole page.
  Rejected.

---

## 4. Options that work (simulated resulting `matrix.md` size)

| # | Option | Proxy change | Manifest | Per-*version* deep link | Visual grid | Size | vs now | +5 releases |
|---|---|---|---|---|---|---|---|---|
| **E14** | Plain `X`/`-` grid; flag name in each row header is the single link, → newest version that has the flag (anchor form) | none | none | no (latest only) | plain `X` | **135 KB** | 15 % | +12 KB |
| **E14b** | As E14, but the row-header link uses a numeric flag-id | tiny (`id`→`anchor`) | 1,241 entries | no | plain `X` | **110 KB** | 13 % | +12 KB |
| **E16** | Every `X` stays clickable via reference-style links, **one shared definition per row** (→ latest version) | none | none | no (latest only) | every `X` linked | **247 KB** | 28 % | +54 KB |
| **E4** | Per-cell links `//pxy.fi/<major>/<base36-flag-id>` | small (`id`→`anchor`) | 1,241 entries | **yes** | every `X` linked | **411 KB** | 47 % | +100 KB |
| **E5** | Per-cell links, single opaque token `//pxy.fi/<base62>` encoding (row, col) | rewrite (18k lookup table, regenerated every run) | 18,266 entries | **yes** | every `X` linked | **376 KB** | 43 % | +100 KB |
| E7 | Per-cell link to the version's page top (drop the `#anchor`) | handle empty fragment | none | no (page top) | every `X` linked | 356 KB | 41 % | +100 KB |
| E1 | Protocol-relative only (`https://` → `//`) | none | none | yes | every `X` linked | 762 KB | 87 % | +248 KB |
| E4 + split | E4 **and** keep only the recent ~6 versions in `matrix.md`; older ones move to `matrix-archive.md` | small | 1,241 | yes (recent) | every `X` linked | **176 KB** | 20 % | ~flat |

Growth column = extra bytes over 5 more Clang releases from the *existing*
1,241 flags each gaining 5 more `X` cells (new flags add on top of that).
Only E14 / E14b / E16 make growth a non-issue.

---

## 5. Recommendation

**Pivotal question:** does clicking the `X` in (say) the "8" column need to land
on the **8.0.0** doc anchor specifically, or is "take me to this flag's docs"
good enough? The **column header already links to each version's full
`DiagnosticsReference.html`**, so per-cell *per-version* linking is largely
redundant with what is already on the page.

### If per-version deep-linking is dispensable → **E14 / E14b**

Plain `X`/`-` grid; the flag name in each row header becomes the single link,
pointing at the newest version that has the flag.

- **E14: 135 KB, zero proxy change, zero manifest.** One-off change to `diags.pl`
  output only.
- **E14b: 110 KB**, if opaque short IDs are also wanted — adds a tiny
  append-only manifest and a trivial proxy lookup.
- Both flatten growth to ~+12 KB per 5 releases.
- **E16 (247 KB)** is the middle path if every `X` must stay individually
  clickable (all links in a row go to the latest version's doc). Still no proxy
  or manifest work.

### If per-version deep-linking must stay → **E4**

`//pxy.fi/<major>/<base36-id>`, **411 KB** (under 512, not under 400).

- Needs a **1,241-entry `id`→`anchor` map** deployed with the proxy.
- Assign IDs by **first-seen order**, persisted in a `flags.json` committed to
  this repo. The generator reads it, preserves every existing `flag`→`id`, and
  only *appends* new flags. Never re-sort — that keeps old links in the blog
  post and in git history valid. Plain incrementing integers are enough;
  hashids / sqids are not needed.
- Combine with the **recent-versions-in-`matrix.md` + `matrix-archive.md`
  split** to reach ~176 KB and flatten growth.
- **E5** (single opaque token, 376 KB, under 400) is also viable but needs an
  18k-entry lookup table regenerated on every run and produces fully opaque
  URLs — more moving parts, more fragile, and it throws away the README's
  "transparent scheme" selling point.

### Fold in regardless: **E1 (protocol-relative)**

One-line change in `_shorten_url` (`https://pxy.fi/` → `//pxy.fi/`), ~13 %
saving, stacks with any option above.

- Caveat: `//host/path` resolves correctly on github.com and `*.github.io`
  (both HTTPS) but **not** when viewing the raw `.md` over `file://` or on an
  HTTP page. Spot-check one rendered cell before committing to a full regen.

---

## 6. Open items before implementing

1. Confirm the real optimisation target — GitHub blob render (512 KB), the TIL
   Jekyll build, the REST API (400 KB), or just repo tidiness.
2. Decide whether per-version deep-linking is a hard requirement (drives the
   whole choice: E14-family vs E4).
3. If an option needs a manifest, decide where `flags.json` lives and how the
   two repos stay in sync on deploy (they currently deploy independently).
4. The proxy's `9` → `10.0.0` data quirk and the `17`/`18+` minor-version HACKs
   in `assembleTargetURL` carry over unchanged under every option.
