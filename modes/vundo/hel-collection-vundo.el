;;; hel-collection-vundo.el --- Hel bindings for vundo -*- lexical-binding: t -*-
;;; Code:

(require 'hel-collection)

(hel-collection-setup vundo
  (:after-load
    (:keymap vundo-mode-map
      (:bind
        "h"   'vundo-backward
        "l"   'vundo-forward
        "j"   'vundo-next
        "k"   'vundo-previous
        "C-h" 'vundo-stem-root
        "C-l" 'vundo-stem-end
        "H"   'vundo-stem-root
        "L"   'vundo-stem-end
        "{"   'vundo-stem-root
        "}"   'vundo-stem-end
        "w"   'vundo-next-root
        "s"   'vundo-goto-last-saved
        "z x" 'vundo-save
        "Z Z" 'vundo-confirm
        "Z Q" 'vundo-quit))))

;;; .
(provide 'hel-collection-vundo)
;;; hel-collection-vundo.el ends here
