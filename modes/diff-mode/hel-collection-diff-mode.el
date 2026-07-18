;;; hel-collection-diff-mode.el --- Hel bindings for Diff mode -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup diff-mode
  (:initial-state 'diff-mode 'normal)
  ;;
  (:keymap diff-mode-shared-map
    (:unbind "k" "K")
    (:bind
      "d"    'diff-hunk-kill   ; "k"
      "D"    'diff-file-kill)) ; "K"
  ;;
  (:keymap diff-mode-map
    (:bind
      "C-j"  'diff-hunk-next
      "C-k"  'diff-hunk-prev)
    (:bind :state normal
      "[ ["  'diff-file-prev
      "] ]"  'diff-file-next
      "g r"  'diff-refresh-hunk
      "g o"  'diff-add-change-log-entries-other-window
      ", +"  'diff-refine-hunk
      ", ~"  'diff-reverse-direction
      ", %"  'diff-apply-buffer
      ", a"  'diff-apply-hunk
      ", A"  'diff-add-change-log-entries-other-window
      ", e"  'diff-ediff-patch
      ", d"  'diff-hunk-kill
      ", n"  'diff-restrict-view
      ", s"  'diff-split-hunk
      ", t"  'diff-test-hunk
      ", o"  'diff-goto-source ;; other-window
      ", w"  'diff-ignore-whitespace-hunk
      ;; unified view is defualt
      ", >"  'diff-unified->context
      ", <"  'diff-context->unified
      ;; "g f"  'next-error-follow-minor-mode
      ))

  (:keymap diff-mode-read-only-map
    (:bind
      "y"    'diff-kill-ring-save
      "u"    'diff-undo
      ", d"  'diff-revert-and-kill-hunk)))

(provide 'hel-collection-diff-mode)
;;; hel-collection-diff-mode.el ends here
