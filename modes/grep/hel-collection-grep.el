;;; hel-collection-grep.el --- Hel bindings for grep -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

;; `grep-mode-map' is inherited from `compilation-minor-mode-map'
(hel-collection-setup grep
  (:keymap grep-mode-map
    (:bind
      "i"   'wgrep-change-to-wgrep-mode
      "g f" 'next-error-follow-minor-mode)))

(hel-collection-setup wgrep
  (:keymap wgrep-mode-map
    (:bind :state normal
      "<escape>" 'wgrep-exit
      "Z Z"      'wgrep-finish-edit
      "Z Q"      'wgrep-abort-changes)
    (:bind
      "<remap> <save-buffer>" 'wgrep-finish-edit)))

(provide 'hel-collection-grep)
;;; hel-collection-grep.el ends here
