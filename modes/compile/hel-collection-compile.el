;;; hel-collection-compile.el --- Hel bindings for Compilation -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup compile
  (:keymap (compilation-minor-mode-map
            compilation-mode-map)
    (:unbind "g")
    (:bind
      "o"    'compilation-display-error

      "g o"  'compile-goto-error
      "g r"  'recompile ; revert

      "n"    'next-error-no-select
      "N"    'previous-error-no-select
      "C-j"  'next-error-no-select
      "C-k"  'previous-error-no-select

      "}"    'compilation-next-file
      "{"    'compilation-previous-file
      "] p"  'compilation-next-file
      "[ p"  'compilation-previous-file
      "z j"  'compilation-next-file
      "z k"  'compilation-previous-file))
  ;;
  (:keymap compilation-mode-map
    (:bind
      "g f"  'next-error-follow-minor-mode
      "Z Q"  'kill-compilation)))

(provide 'hel-collection-compile)
;;; hel-collection-compile.el ends here
