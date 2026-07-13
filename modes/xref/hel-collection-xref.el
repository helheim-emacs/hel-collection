;;; hel-collection-xref.el --- Hel bindings for xref -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup xref
  (:keymap xref--xref-buffer-mode-map
    (:bind
      "o"    'xref-show-location-at-point
      "Q"    'xref-quit-and-pop-marker-stack

      "C-j"  'xref-next-line
      "C-k"  'xref-prev-line

      "}"    'xref-next-group
      "{"    'xref-prev-group
      "] p"  'xref-next-group
      "[ p"  'xref-prev-group
      "z j"  'xref-next-group
      "z k"  'xref-prev-group)))

(provide 'hel-collection-xref)
;;; hel-collection-xref.el ends here
