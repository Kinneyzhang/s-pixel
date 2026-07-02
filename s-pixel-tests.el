;;; s-pixel-tests.el --- Manual visual examples for s-pixel  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 kinney

;; Author: kinney
;; Maintainer: kinney
;; Version: 0.1.0
;; Keywords: strings, convenience
;; License: GPL-3.0-or-later

;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;; This file is a set of interactive examples rather than an automated ERT test
;; suite.  Load this file in a graphical Emacs frame and run
;; `s-pixel-tests-run' to inspect how padding, alignment, truncation, and
;; wrapping render with the current font.

;;; Code:

(require 's-pixel)

(defvar pop-buffer-insert-buffer "*s-pixel examples*"
  "Buffer name used by `pop-buffer-insert' for manual s-pixel examples.")

(defun pop-buffer-insert (height &rest strings)
  "Insert STRINGS into `pop-buffer-insert-buffer' and display it.

HEIGHT is the preferred maximum window height, in lines, when the
examples are evaluated interactively.  In batch mode the buffer is only
updated and returned.

This is a small standalone version of the helper used in the author's
Emacs configuration.  It intentionally avoids private modes, keymaps,
window-configuration state, and other user-specific dependencies."
  (declare (indent defun))
  (let ((buffer (get-buffer-create pop-buffer-insert-buffer)))
    ;; Reuse one buffer for every example block so evaluating a form replaces
    ;; the previous visual output instead of creating throwaway buffers.
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (apply #'insert strings)))
    (unless noninteractive
      (let ((window (display-buffer buffer)))
        (when (window-live-p window)
          (fit-window-to-buffer window height))))
    buffer))

(defun s-pixel-tests-run ()
  "Display manual visual examples for `s-pixel'.

The examples measure strings with `string-pixel-width', so they require
a graphical frame with a usable font."
  (interactive)
  (unless (display-graphic-p)
    (user-error "s-pixel visual examples require a graphical frame"))
  (pop-buffer-insert 5
    (s-pixel-pad "happy hacking emacs" 20 50)
    "\n"
    (s-pixel-pad "happy hacking emacs" 0 50))

  (pop-buffer-insert 10
    (s-pixel-reach "happy hacking emacs" 400)
    "\n"
    (s-pixel-reach "happy hacking emacs" 400 'left)
    "\n"
    (s-pixel-reach "happy hacking emacs" 400 'right)
    "\n"
    (s-pixel-reach "happy hacking emacs" 400 'left 30)
    "\n"
    (s-pixel-reach "happy hacking emacs" 400 'left -30)
    "\n"
    (s-pixel-reach "happy hacking emacs" 400 'right 30)
    "\n"
    (s-pixel-reach "happy hacking emacs" 400 'right -30))

  (pop-buffer-insert 10
    (s-pixel-align "happy hacking emacs" 400)
    "\n"
    (s-pixel-align "happy hacking emacs" 400 'left)
    "\n"
    (s-pixel-align "happy hacking emacs" 400 'center)
    "\n"
    (s-pixel-align "happy hacking emacs" 400 'right))

  (pop-buffer-insert 10
    (s-pixel-center "happy hacking emacs" 500))

  (pop-buffer-insert 10
    (s-pixel-floor "happy hacking emacs" 50)
    "\n"
    (s-pixel-left "happy hacking emacs" 50)
    "\n"
    (s-pixel-right "happy hacking emacs" 50)
    "\n"
    (s-pixel-chop-left "happy hacking emacs" 50)
    "\n"
    (s-pixel-chop-right "happy hacking emacs" 50))

  ;; Measure wrapping with the current frame font.
  (pop-buffer-insert 20
    (progn
      (ekp-clear-caches)
      (s-pixel-wrap
       "Ni-ka Ford has always known that she wanted to be an artist. But she wasn’t sure how to channel that passion until her final year as a studio art major in college. She remembers one day in an art studio when she was looking out the window at a tree. “And I was like, ‘Wow, the branches really look like veins in the body,’” she says. This inspiration led her to notice “a lot of similarities between our bodies and nature” and drew her to the field of medical illustration. Today her work distills medical complexity into illustrations and graphics that appear in journal articles, teaching materials and popular publications." 577))))

(provide 's-pixel-tests)

;;; s-pixel-tests.el ends here
