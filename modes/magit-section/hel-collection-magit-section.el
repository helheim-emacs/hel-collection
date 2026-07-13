;;; hel-collection-magit-section.el --- Hel bindings for Magit Section -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup magit-section
  (:keymap magit-section-mode-map
    (:unbind "M-1" "M-2" "M-3" "M-4" "C-c TAB" "C-<tab>" "M-<tab>")
    (:bind
      "<tab>"     'magit-section-cycle
      "<backtab>" 'magit-section-cycle-global ;; "S-<tab>"
      "C-j"  'magit-section-forward-sibling
      "C-k"  'magit-section-backward-sibling
      "z j"  'magit-section-forward
      "z k"  'magit-section-backward
      "z u"  'magit-section-up
      "z a"  'magit-section-toggle
      "z c"  'magit-section-hide
      "z o"  'magit-section-show
      "z O"  'magit-section-show-children
      "z m"  'magit-section-show-level-1-all
      "z r"  'magit-section-show-level-4-all
      "1"    'magit-section-show-level-1
      "2"    'magit-section-show-level-2
      "3"    'magit-section-show-level-3
      "4"    'magit-section-show-level-4
      "z 1"  'magit-section-show-level-1-all
      "z 2"  'magit-section-show-level-2-all
      "z 3"  'magit-section-show-level-3-all
      "z 4"  'magit-section-show-level-4-all)))

(provide 'hel-collection-magit-section)
;;; hel-collection-magit-section.el ends here
