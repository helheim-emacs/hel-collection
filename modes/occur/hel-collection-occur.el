;;; hel-collection-occur.el --- Hel bindings for Occur-mode -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup replace
  (:keymap occur-mode-map
    (:bind
      "i"    'occur-edit-mode
      "o"    'occur-mode-display-occurrence           ; default `C-o'
      "g o"  'occur-mode-goto-occurrence-other-window ; default `o'
      "g f"  'next-error-follow-minor-mode

      "n"    'next-error-no-select
      "N"    'previous-error-no-select
      "C-j"  'next-error-no-select
      "C-k"  'previous-error-no-select))

  (:keymap occur-edit-mode-map
    (:bind :state normal
      "g o"  'occur-mode-goto-occurrence-other-window
      "<escape>" 'occur-cease-edit
      "Z Z"  'occur-cease-edit
      "Z Q"  'occur-cease-edit)))

(provide 'hel-collection-occur)
;;; hel-collection-occur.el ends here
