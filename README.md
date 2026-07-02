# s-pixel

[中文文档](README.zh-CN.md)

`s-pixel` is a small Emacs Lisp helper library for building strings whose
spacing, alignment, truncation, and wrapping are measured in pixels instead of
characters.

It is intended for Emacs buffer UI where visual alignment depends on the
selected frame, font, mixed-width text, and `display` text properties.

## Table of Contents

- [Project Status](#project-status)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Core Concepts](#core-concepts)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Internal Helpers](#internal-helpers)
- [Manual Visual Examples](#manual-visual-examples)
- [Development](#development)
- [License](#license)

## Project Status

This repository is a source-only Emacs Lisp utility package.  It currently ships
manual visual examples in `s-pixel-tests.el`, not an automated ERT test suite.

The functions are small and intentionally direct.  Public functions are defined
in `s-pixel.el`; implementation helpers and tokenizer experiments are defined
in `s-pixel-utils.el`.

## Features

- Create horizontal spacing with Emacs `display` text properties.
- Add left and right padding by pixel width.
- Align text inside a fixed pixel-width slot.
- Keep the visible left or right part of a string when it is too wide.
- Remove pixels from the left or right side of a string.
- Wrap text by pixel width through `ekp-pixel-justify`.
- Split mixed Latin/CJK text into visual units with internal tokenizer helpers.

## Requirements

- Emacs with `string-pixel-width` support.  Emacs 27.1 or newer is recommended.
- [`s.el`](https://github.com/magnars/s.el), used by `s-pixel-pad`.
- `ekp`, used by `s-pixel-wrap` and required by `s-pixel.el`.
- A graphical Emacs frame for reliable pixel measurements.

Pixel measurement uses the selected frame and the current font.  Results can
differ between GUI and terminal frames, between fonts, and after font changes.

## Installation

Clone or place this repository somewhere on your machine, then add it to
`load-path`:

```elisp
(add-to-list 'load-path "/path/to/s-pixel")
(require 's-pixel)
```

Load the internal utility helpers only when you need them directly:

```elisp
(require 's-pixel-utils)
```

## Core Concepts

`s-pixel` works with rendered width.  The width of a string is measured with
`string-pixel-width`, and extra spacing is represented as a propertized space:

```elisp
(propertize " " 'display '(space :width (20)))
```

The library expects pixel arguments to describe horizontal width in pixels.
`total-pixel` arguments must be greater than or equal to the rendered width of
the input string for functions that preserve the entire string.

Functions that truncate content do so at character boundaries.  They do not
split a rendered character.

## Quick Start

```elisp
;; Add 20 pixels before the string and 50 pixels after it.
(s-pixel-pad "happy hacking emacs" 20 50)

;; Make the rendered string occupy 400 pixels, left aligned by default.
(s-pixel-reach "happy hacking emacs" 400)

;; Center or right-align text inside a 400 pixel slot.
(s-pixel-align "happy hacking emacs" 400 'center)
(s-pixel-align "happy hacking emacs" 400 'right)

;; Keep the visible prefix that fits within 50 pixels, then pad to 50 pixels.
(s-pixel-left "happy hacking emacs" 50)

;; Keep the visible suffix that fits within 50 pixels, then pad to 50 pixels.
(s-pixel-right "happy hacking emacs" 50)
```

## API Reference

### `s-pixel-spacing`

```elisp
(s-pixel-spacing pixel)
```

Return a string that renders as horizontal spacing with width `pixel`.

When `pixel` is `0`, return an empty string.  Otherwise return a single space
with a `display` property of `(space :width (pixel))`.  This is the low-level
building block used by padding and alignment helpers.

### `s-pixel-pad`

```elisp
(s-pixel-pad s prefix-pixel &optional suffix-pixel)
```

Return `s` with `prefix-pixel` pixels of spacing before it and `suffix-pixel`
pixels of spacing after it.

When `suffix-pixel` is omitted, no suffix padding is added.  The original
content of `s` is preserved.

### `s-pixel-reach`

```elisp
(s-pixel-reach s total-pixel &optional side offset)
```

Return `s` padded so its rendered width reaches `total-pixel`.

`side` controls where `offset` is measured from and must be `left` or `right`.
It defaults to `left`.  `offset` defaults to `0`.

Positive offsets are counted from `side`.  Negative offsets are counted backward
from the opposite side.  The resulting offset is clamped so `s` remains inside
`total-pixel`.

This function signals an error when `s` is wider than `total-pixel`, or when
`side` is unsupported.

### `s-pixel-align`

```elisp
(s-pixel-align s total-pixel &optional align)
```

Return `s` padded to `total-pixel` and positioned by `align`.

`align` must be `left`, `center`, or `right`.  It defaults to `left`.  This
function signals an error when `s` is wider than `total-pixel`, or when `align`
is unsupported.

### `s-pixel-center`

```elisp
(s-pixel-center s total-pixel)
```

Return `s` centered inside `total-pixel` pixels.

This is a convenience wrapper around:

```elisp
(s-pixel-align s total-pixel 'center)
```

### `s-pixel-wrap`

```elisp
(s-pixel-wrap s pixel)
```

Wrap `s` so each line fits within `pixel` pixels.

This delegates the wrapping algorithm to `ekp-pixel-justify`, so exact line
breaks depend on the installed `ekp` implementation and the current frame font.

### `s-pixel-floor`

```elisp
(s-pixel-floor s pixel)
```

Return the longest prefix of `s` whose rendered width is at most `pixel`.

If the complete string fits, return `s`.  If the first rendered character is
wider than `pixel`, return an empty string.

### `s-pixel-left`

```elisp
(s-pixel-left s pixel)
```

Return a string that occupies `pixel` pixels while keeping the left side of `s`.

If `s` is wider than `pixel`, truncate the right side at a character boundary.
The result is padded on the right so it renders as `pixel` pixels wide.

### `s-pixel-right`

```elisp
(s-pixel-right s pixel)
```

Return a string that occupies `pixel` pixels while keeping the right side of
`s`.

If `s` is wider than `pixel`, truncate the left side at a character boundary.
The result is padded on the left so it renders as `pixel` pixels wide.

### `s-pixel-chop-left`

```elisp
(s-pixel-chop-left s pixel)
```

Return `s` with up to `pixel` rendered pixels removed from the left side.

When `pixel` is greater than or equal to the rendered width of `s`, return an
empty string.

### `s-pixel-chop-right`

```elisp
(s-pixel-chop-right s pixel)
```

Return `s` with up to `pixel` rendered pixels removed from the right side.

When `pixel` is greater than or equal to the rendered width of `s`, return an
empty string.

## Internal Helpers

The following functions are implementation details.  They use the double-hyphen
Emacs Lisp naming convention and may change without notice.

### `s-pixel--smart-offset`

```elisp
(s-pixel--smart-offset s total-pixel offset-pixel)
```

Return the start offset for `s` inside `total-pixel`.

`offset-pixel` is measured inside the remaining space after `s` is accounted
for.  Positive values are counted from the start.  Negative values are counted
backward from the end.  The returned value is clamped so `s` stays inside
`total-pixel`.

### `s-pixel--align-offset`

```elisp
(s-pixel--align-offset s total align)
```

Return the start offset for `s` inside `total` pixels using `align`.

`align` must be `left`, `center`, or `right`.

### `s-pixel--cjk-char-p`

```elisp
(s-pixel--cjk-char-p char)
```

Return non-nil when `char` belongs to a CJK-related Unicode range.

The covered ranges include common CJK ideographs, CJK extensions A and B, CJK
punctuation, kana, Hangul, and CJK compatibility ideographs.

### `s-pixel--split`

```elisp
(s-pixel--split string)
```

Split `string` into visual text units.

Latin text is grouped by word, CJK text is grouped by character, and punctuation
is attached to the previous unit.  Whitespace between units is skipped.

## Manual Visual Examples

`s-pixel-tests.el` contains manual examples for visual inspection.  Load the
file in a graphical Emacs frame, then run:

```elisp
(s-pixel-tests-run)
```

The test file includes a small standalone `pop-buffer-insert` helper, so it does
not depend on the author's private Emacs configuration.

## Development

Use the smallest relevant batch load checks while editing:

```sh
emacs --batch -L . -l s-pixel-utils.el --eval "(message \"s-pixel-utils loaded\")"
emacs --batch -L . -l s-pixel.el --eval "(message \"s-pixel loaded\")"
```

Because the main package depends on `s.el` and `ekp`, the second command
requires those libraries to be available on Emacs' `load-path`.

## License

No license file is currently included in this repository.
