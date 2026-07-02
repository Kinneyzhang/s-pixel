;;; s-pixel.el --- Pixel-width string helpers  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 kinney

;; Author: kinney
;; Maintainer: kinney
;; Version: 0.1.0
;; Keywords: strings, convenience
;; Package-Requires: ((emacs "27.1") (s "1.12.0") (ekp "0"))
;; License: GPL-3.0-or-later

;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;; This library provides small helpers for composing Emacs strings whose visual
;; width is controlled in pixels.  It uses `string-pixel-width' for measurement
;; and `display' text properties for spacing, so results follow the selected
;; frame and font.
;;
;; The public functions are useful when building aligned buffer UI where
;; character counts are not accurate enough, especially with mixed-width text.

;;; Code:

(require 's)
(require 'ekp)

(defun s-pixel-spacing (pixel)
  "Return display spacing with width PIXEL.

When PIXEL is 0, return an empty string instead of a display-space
property.  For non-zero PIXEL, return a propertized space whose
`display' property is `(space :width (PIXEL))'.

The returned string is intended for horizontal padding in graphical
Emacs frames."
  (if (= pixel 0)
      ""
    (propertize " " 'display `(space :width (,pixel)))))

(defun s-pixel-pad (s prefix-pixel &optional suffix-pixel)
  "Return S padded with pixel spacing on both sides.

PREFIX-PIXEL is the padding width before S.  Optional SUFFIX-PIXEL is
the padding width after S; when omitted, no suffix padding is added.

The content of S is preserved.  Only display-space strings are added
around it."
  (s-wrap s (s-pixel-spacing prefix-pixel)
          (s-pixel-spacing (or suffix-pixel 0))))

(defun s-pixel--smart-offset (s total-pixel offset-pixel)
  "Return S offset from the start of TOTAL-PIXEL.

OFFSET-PIXEL is interpreted inside the remaining space after S.  A
positive value is counted from the start; a negative value is counted
backward from the end.  The returned offset is clamped to the range that
keeps S inside TOTAL-PIXEL.

Signal an error when the pixel width of S is greater than TOTAL-PIXEL."
  (let ((str-pixel (string-pixel-width s)))
    (when (> str-pixel total-pixel)
      (error "Pixel width of string is %s; it must not be greater\
 than total-pixel %s" str-pixel total-pixel))
    (let ((rest-pixel (- total-pixel str-pixel)))
      (cond ((>= offset-pixel 0) (min offset-pixel rest-pixel))
            ((< offset-pixel 0) (max 0 (+ offset-pixel rest-pixel)))))))

(defun s-pixel--align-offset (s total align)
  "Return the start offset for S inside TOTAL pixels using ALIGN.

ALIGN must be one of `left', `center', or `right'.  Signal an error for
any other ALIGN value, or when S is wider than TOTAL pixels."
  (pcase align
    ('left (s-pixel--smart-offset s total 0))
    ('right (s-pixel--smart-offset
             s total (- total (string-pixel-width s))))
    ('center (s-pixel--smart-offset
              s total (/ (- total (string-pixel-width s)) 2)))
    (_ (error "Invalid value of ALIGN: %S" align))))

(defun s-pixel-reach (s total-pixel &optional side offset)
  "Return S padded until its pixel width reaches TOTAL-PIXEL.

TOTAL-PIXEL must be greater than or equal to the pixel width of S.

Optional SIDE controls which side OFFSET is counted from, and must be
`left' or `right'.  When SIDE is omitted, it defaults to `left'.
Optional OFFSET defaults to 0.

When OFFSET is positive, count it from SIDE.  When OFFSET is negative,
count it backward from the opposite side.

Signal an error when S is wider than TOTAL-PIXEL, or when SIDE is not
`left' or `right'."
  (let* ((side (or side 'left))
         (offset (s-pixel--smart-offset s total-pixel (or offset 0)))
         (rest-pixel (- total-pixel (string-pixel-width s)))
         left-pixel)
    (pcase side
      ('left (setq left-pixel offset))
      ('right (setq left-pixel (- rest-pixel offset)))
      (_ (error "Invalid value of SIDE: %S" side)))
    (s-pixel-pad s left-pixel (- rest-pixel left-pixel))))

(defun s-pixel-align (s total-pixel &optional align)
  "Return S padded to TOTAL-PIXEL and positioned by ALIGN.

ALIGN must be one of `left', `center', or `right'.  When omitted, ALIGN
defaults to `left'.  TOTAL-PIXEL must be greater than or equal to the
pixel width of S.

Signal an error when S is wider than TOTAL-PIXEL, or when ALIGN is not
one of the supported alignment symbols."
  (let ((offset (s-pixel--align-offset
                 s total-pixel (or align 'left))))
    (s-pixel-reach s total-pixel 'left offset)))

(defun s-pixel-center (s total-pixel)
  "Return S centered inside TOTAL-PIXEL pixels.

This is equivalent to calling `s-pixel-align' with ALIGN set to
`center'.  Signal an error when S is wider than TOTAL-PIXEL."
  (s-pixel-align s total-pixel 'center))

(defun s-pixel-wrap (s pixel)
  "Wrap string S so each line fits within PIXEL width.

This delegates to `ekp-pixel-justify'.  The exact wrapping result
depends on that implementation and on the current frame font."
  (ekp-pixel-justify s pixel))

(defun s-pixel-floor (s pixel)
  "Return the longest prefix of S whose pixel width is at most PIXEL.

If S already fits in PIXEL, return S.  If the first rendered character
is wider than PIXEL, return an empty string."
  (if (<= (string-pixel-width s) pixel)
      s
    (let (new-s (curr-pixel 0))
      ;; Walk by rendered character width so mixed-width strings are truncated
      ;; at the last complete character that still fits.
      (catch 'break
        (dolist (char (split-string s "" t))
          (let ((char-pixel (string-pixel-width char)))
            (if (> char-pixel pixel)
                (throw 'break "")
              (if (> (+ curr-pixel char-pixel) pixel)
                  (throw 'break new-s)
                (setq curr-pixel (+ curr-pixel char-pixel))
                (setq new-s (concat new-s char))))))))))

(defun s-pixel-left (s pixel)
  "Return S left-aligned in PIXEL pixels, truncating the right side.

If S is wider than PIXEL, keep the longest prefix that fits.  The result
is padded on the right so its rendered width reaches PIXEL."
  ;; Keep the rendered prefix that fits, then fill the remaining width with a
  ;; display-space property so the final string still occupies PIXEL pixels.
  (let* ((part-s (s-pixel-floor s pixel))
         (part-pixel (string-pixel-width part-s)))
    (concat part-s (s-pixel-spacing (- pixel part-pixel)))))

(defun s-pixel-right (s pixel)
  "Return S right-aligned in PIXEL pixels, truncating the left side.

If S is wider than PIXEL, keep the longest suffix that fits.  The result
is padded on the left so its rendered width reaches PIXEL."
  ;; Reuse `s-pixel-floor' by reversing S, which turns suffix truncation into
  ;; prefix truncation, then reverse the surviving text back into place.
  (let* ((part-s (s-pixel-floor (reverse s) pixel))
         (part-s (reverse part-s))
         (part-pixel (string-pixel-width part-s)))
    (concat (s-pixel-spacing (- pixel part-pixel)) part-s)))

(defun s-pixel-chop-left (s pixel)
  "Return S with up to PIXEL pixels removed from the left side.

When PIXEL is greater than or equal to the rendered width of S, return
an empty string."
  ;; Chopping the left side leaves a right-side segment with this remaining
  ;; rendered width; `s-pixel-right' handles the suffix selection.
  (let ((right-pixel (- (string-pixel-width s)
                        (min (string-pixel-width s) pixel))))
    (s-pixel-right s right-pixel)))

(defun s-pixel-chop-right (s pixel)
  "Return S with up to PIXEL pixels removed from the right side.

When PIXEL is greater than or equal to the rendered width of S, return
an empty string."
  ;; Chopping the right side leaves a left-side segment with this remaining
  ;; rendered width; `s-pixel-left' handles the prefix selection.
  (let ((left-pixel (- (string-pixel-width s)
                       (min (string-pixel-width s) pixel))))
    (s-pixel-left s left-pixel)))

(provide 's-pixel)

;;; s-pixel.el ends here
