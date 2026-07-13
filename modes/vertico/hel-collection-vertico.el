;;; hel-collection-vertico.el --- Hel bindings for Vertico -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup vertico
  (:keymap vertico-map
    (:bind :state normal
      "y"     'vertico-save ;; Copy current candidate to kill ring.
      "j"     'vertico-next
      "k"     'vertico-previous
      "g g"   'vertico-first
      "G"     'vertico-last)
    (:bind
      "C-j"   'vertico-next
      "C-k"   'vertico-previous
      "C-S-j" 'vertico-next-group
      "C-S-k" 'vertico-previous-group

      "C-l"   'vertico-insert
      "C-h"   'vertico-directory-up

      ;; Scrolling in Insert state.
      "C-f"   'vertico-scroll-up
      "C-b"   'vertico-scroll-down

      ;; Rebind "}" / "{" and "]p" / "[p" keys
      "<remap> <hel-forward-paragraph>"       'vertico-next-group
      "<remap> <hel-backward-paragraph>"      'vertico-previous-group
      "<remap> <hel-forward-paragraph-end>"   'vertico-next-group
      "<remap> <hel-backward-paragraph-end>"  'vertico-previous-group

      ;; Rebind "C-f" / "C-b" and "C-d" / "C-u" scrolling keys
      "<remap> <hel-smooth-scroll-down>"      'vertico-scroll-up
      "<remap> <hel-smooth-scroll-up>"        'vertico-scroll-down
      "<remap> <hel-smooth-scroll-page-down>" 'vertico-scroll-up
      "<remap> <hel-smooth-scroll-page-up>"   'vertico-scroll-down)))

(provide 'hel-collection-vertico)
;;; hel-collection-vertico.el ends here
