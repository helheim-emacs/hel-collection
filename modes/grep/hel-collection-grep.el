;;; hel-collection-grep.el --- Hel bindings for grep -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup grep
  (:after-load
    ;; `grep-mode-map' is inherited from `compilation-minor-mode-map'
    (:keymap grep-mode-map
      (:bind
        ;; wgrep is the richer editor, so it wins when it is installed.
        ;; `grep-edit-mode' is the built-in fallback, available since
        ;; Emacs 31.
        "i"   (if (fboundp 'wgrep-change-to-wgrep-mode)
                  'wgrep-change-to-wgrep-mode
                'grep-change-to-grep-edit-mode)
        "g f" 'next-error-follow-minor-mode))

    (when (boundp 'grep-edit-mode-map) ; Emacs 31
      (:keymap grep-edit-mode-map
        (:bind :state normal
          "<escape>" 'grep-edit-save-changes
          "Z Z"      'grep-edit-save-changes)
        (:bind
          "<remap> <save-buffer>" 'grep-edit-save-changes)))))

(hel-collection-setup wgrep
  (:after-load
    (:keymap wgrep-mode-map
      (:bind :state normal
        "<escape>" 'wgrep-exit
        "Z Z"      'wgrep-finish-edit
        "Z Q"      'wgrep-abort-changes)
      (:bind
        "<remap> <save-buffer>" 'wgrep-finish-edit))))

(provide 'hel-collection-grep)
;;; hel-collection-grep.el ends here
