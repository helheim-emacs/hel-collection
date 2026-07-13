;;; hel-collection-diff-mode.el --- Hel bindings for Diff mode -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup diff-mode
  (:keymap diff-mode-shared-map
    (:unbind "k" "K")
    (:bind
      "d"    'diff-hunk-kill ; "k"
      "D"    'diff-file-kill ; "K"
      "u"    'diff-undo))
  ;;
  (:keymap diff-mode-map
    (:bind
      "C-j"  'diff-hunk-next
      "C-k"  'diff-hunk-prev
      "g j"  'diff-hunk-next
      "g k"  'diff-hunk-prev
      "[ ["  'diff-file-prev
      "] ]"  'diff-file-next)))

(provide 'hel-collection-diff-mode)
;;; hel-collection-diff-mode.el ends here
