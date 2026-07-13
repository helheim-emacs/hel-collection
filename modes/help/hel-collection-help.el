;;; hel-collection-help.el --- Hel bindings for Help -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup help
  (:keymap help-map
    ;; Unclatter `help-map' to make `whick-key' useable.
    (:unbind
      "<f1>" "C-h" "?" "<help>" ;; `help-for-help'
      "h"    ; `view-hello-file'
      "C-c"  ; `describe-copying'
      "C-e"  ; `view-external-packages' — irrelevant or outdated information
      "C-o"  ; `describe-distribution'
      "C-q"  ; `help-quick-toggle' — irrelevant to us
      "C-w"  ; `describe-no-warranty'
      "R"    ; `info-display-manual' — moved to "RET"
      "C-n") ; `view-emacs-news' — duplicated on "n"
    (:bind
      "m"   'describe-mode
      "C-d" 'view-emacs-debugging
      "F"   'describe-face
      "M"   'describe-keymap
      "o"   'describe-syntax ;; swap "s" and "o"
      "s"   'helpful-symbol
      "S"   'info-lookup-symbol
      "RET" 'info-display-manual ;; originally `view-order-manuals'
      "d"   'apropos-documentation
      "l"   'view-lossage
      ;; Rebind `b' key from `describe-bindings' to prefix with more binding
      ;; related commands.
      "b" (cons "bindings"
                (define-keymap
                  "b" 'describe-bindings
                  "B" 'embark-bindings ;; alternative for `describe-bindings'
                  "i" 'which-key-show-minor-mode-keymap
                  "m" 'which-key-show-major-mode
                  "t" 'which-key-show-top-level
                  "f" 'which-key-show-full-keymap
                  "k" 'which-key-show-keymap)))))

(provide 'hel-collection-help)
;;; hel-collection-help.el ends here
