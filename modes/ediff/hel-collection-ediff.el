;;; hel-collection-ediff.el --- Hel bindings for Ediff -*- lexical-binding: t -*-
;;; Commentary:
;;
;; All credit goes to the `evil-collection' package.
;;
;;; Code:

(require 'cl-lib)
(require 'hel-collection)
(require 'hel-core)

(declare-function ediff-scroll-horizontally "ediff")
(declare-function ediff-scroll-vertically   "ediff")
(declare-function ediff-jump-to-difference  "ediff")

(defvar ediff-mode-map)
(defvar ediff-3way-comparison-job)
(defvar ediff-number-of-differences)
(defvar ediff-split-window-function)

;;; Config

(setopt ediff-diff-options "-w" ;; turn off whitespace checking
        ediff-split-window-function 'split-window-horizontally
        ediff-window-setup-function 'ediff-setup-windows-plain
        ;; ediff-keep-variants nil
        )

(hel-set-initial-state 'ediff-mode 'emacs)
(add-hook 'ediff-keymap-setup-hook 'hel-collection-ediff-setup-keys)

;;; Keybindings

;;;###autoload
(defun hel-collection-ediff-setup-keys ()
  "Setup Ediff keys.
Run from `ediff-keymap-setup-hook', with `ediff-mode-map' bound to the
keymap of the session being set up."
  (hel-keymap-set ediff-mode-map :state 'emacs
    "d"    'ediff-jump-to-difference
    "H"    'ediff-toggle-hilit
    "j"    'ediff-next-difference
    "k"    'ediff-previous-difference
    "N"    'ediff-previous-difference
    "C-d"  'hel-collection-ediff-scroll-down
    "C-u"  'hel-collection-ediff-scroll-up
    "C-e"  'hel-collection-ediff-scroll-down-1
    "C-y"  'hel-collection-ediff-scroll-up-1
    "g g"  'hel-collection-ediff-first-difference
    "G"    'hel-collection-ediff-last-difference
    "C-z"  'ediff-suspend
    "z l"  'hel-collection-ediff-scroll-right
    "z h"  'hel-collection-ediff-scroll-left
    "u a"  'ediff-restore-diff
    "u b"  'ediff-restore-diff
    "u c"  'ediff-restore-diff)
  (unless (or ediff-3way-comparison-job
              (eq ediff-split-window-function 'split-window-vertically))
    (hel-keymap-set ediff-mode-map :state 'emacs
      "l"  'ediff-copy-A-to-B
      "h"  'ediff-copy-B-to-A))
  ;; (hel-update-active-keymaps)
  (hel-emacs-state))

;;; Help message

;; Idempotent: a second run finds no original key left to replace.
(with-eval-after-load 'ediff
  (let ((messages '(ediff-long-help-message-compare2
                    ediff-long-help-message-compare3
                    ediff-long-help-message-narrow2
                    ediff-long-help-message-word-mode
                    ediff-long-help-message-merge
                    ediff-long-help-message-head
                    ediff-long-help-message-tail))
        (replace '(;;("^" . "  ")
                   ("p,DEL -previous diff " . "  k,N -previous diff ")
                   ("n,SPC -next diff     " . "  j,n -next diff     ")
                   ("    j -jump to diff  " . "    d -jump to diff  ")
                   ("    h -highlighting  " . "    H -highlighting  ")
                   ("  v/V -scroll up/dn  " . "C-u/d -scroll up/dn  ")
                   ("  </> -scroll lt/rt  " . "zh/zl -scroll lt/rt  ")
                   ("  z/q -suspend/quit"   . "C-z/q -suspend/quit"))))
    (dolist (msg messages)
      (cl-loop for (from . to) in replace
               do (setf (symbol-value msg)
                        (replace-regexp-in-string from to (symbol-value msg)))))))

;;; Commands

(defun hel-collection-ediff-scroll-left (&optional arg)
  "Scroll left."
  (interactive "P")
  (let ((last-command-event ?>))
    (ediff-scroll-horizontally arg)))

(defun hel-collection-ediff-scroll-right (&optional arg)
  "Scroll right."
  (interactive "P")
  (let ((last-command-event ?<))
    (ediff-scroll-horizontally arg)))

(defun hel-collection-ediff-scroll-up (&optional arg)
  "Scroll up by half of a page."
  (interactive "P")
  (let ((last-command-event ?V))
    (ediff-scroll-vertically arg)))

(defun hel-collection-ediff-scroll-down (&optional arg)
  "Scroll down by half of a page."
  (interactive "P")
  (let ((last-command-event ?v))
    (ediff-scroll-vertically arg)))

(defun hel-collection-ediff-scroll-down-1 ()
  "Scroll down by a line."
  (interactive)
  (let ((last-command-event ?v))
    (ediff-scroll-vertically 1)))

(defun hel-collection-ediff-scroll-up-1 ()
  "Scroll up by a line."
  (interactive)
  (let ((last-command-event ?V))
    (ediff-scroll-vertically 1)))

(defun hel-collection-ediff-first-difference ()
  "Jump to first difference."
  (interactive)
  (ediff-jump-to-difference 1))

(defun hel-collection-ediff-last-difference ()
  "Jump to last difference."
  (interactive)
  (ediff-jump-to-difference ediff-number-of-differences))

;;; .
(provide 'hel-collection-ediff)
;;; hel-collection-ediff.el ends here
