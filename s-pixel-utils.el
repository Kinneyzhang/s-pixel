;;; s-pixel-utils.el --- Utility helpers for s-pixel  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 kinney

;; Author: kinney
;; Maintainer: kinney
;; Version: 0.1.0
;; Keywords: strings, convenience
;; Package-Requires: ((emacs "27.1"))
;; License: GPL-3.0-or-later

;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;; Internal helpers used while experimenting with pixel-aware text wrapping.
;; The tokenizer keeps CJK characters as individual units and groups Latin text
;; by word so callers can reason about visual chunks more naturally.  These
;; functions are internal implementation helpers and may change without notice.

;;; Code:

(defun s-pixel--cjk-char-p (char)
  "Return non-nil if CHAR belongs to a CJK-related Unicode range.

CHAR is an Emacs character code.  The covered ranges include common CJK
ideographs, CJK extensions A and B, CJK punctuation, kana, Hangul, and
CJK compatibility ideographs."
  (or
   ;; CJK unified ideographs, basic block.
   (<= #x4E00 char #x9FFF)
   ;; CJK extension A.
   (<= #x3400 char #x4DBF)
   ;; CJK extension B.  These code points are outside the BMP.
   (and (<= #x20000 char) (<= char #x2A6DF))
   ;; CJK symbols and punctuation.
   (<= #x3000 char #x303F)
   ;; Japanese kana.
   (<= #x3040 char #x30FF)
   ;; Hangul syllables.
   (<= #xAC00 char #xD7AF)
   ;; CJK compatibility ideographs.
   (<= #xF900 char #xFAFF)))

(defun s-pixel--split (string)
  "Split STRING into visual text units.

Latin text is grouped by word, CJK text is grouped by character, and
punctuation is attached to the previous unit.

Whitespace between units is skipped.  Return the units in their original
order as strings without text properties."
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (let (result)
      (while (not (eobp))
        ;; Ignore spacing between units; callers can decide how to reinsert it.
        (skip-syntax-forward "-")
        (unless (eobp)
          (let ((start (point)))
            (if (s-pixel--cjk-char-p (char-after))
                (forward-char 1)
              (forward-word 1))
            ;; Keep trailing punctuation with the preceding text unit.
            (while (and (not (eobp))
                        (equal (char-syntax (char-after)) ?.))
              (forward-char 1))
            (push (buffer-substring-no-properties start (point))
                  result))))
      (nreverse result))))

;; (defun s-pixel--get-text-properties (str)
;;   "获取字符串STR的所有文本属性区间。
;; 返回值为列表，每个元素为 (START END PROPERTIES)，其中
;; START和END为区间的起始和结束位置，PROPERTIES为该区间的属性。"
;;   (let ((len (length str))
;;         (pos 0) ranges)
;;     (while (< pos len)
;;       (let* ((props (text-properties-at pos str))
;;              (next-pos (next-property-change pos str len)))
;;         (when props
;;           (push (list pos next-pos props) ranges))
;;         (setq pos next-pos)))
;;     (nreverse ranges)))

;; (defun s-pixel--copy-text-properties (from-str to-str)
;;   "Copy the text properties of FROM-STR to TO-STR and return TO-STR."
;;   (when-let ((props (s-pixel--get-text-properties from-str)))
;;     (dolist (prop props)
;;       (setq to-str (apply 'propertize to-str (nth 2 prop)))))
;;   to-str)

(provide 's-pixel-utils)

;;; s-pixel-utils.el ends here
