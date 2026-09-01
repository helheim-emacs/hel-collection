;;; hel-collection-tempel.el --- Hel bindings for tempel -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup tempel
  (:after-load
    (:keymap tempel-map
      (:bind :state normal
        "g g"        'tempel-beginning
        "G"          'tempel-end
        "d"          'tempel-kill
        "{"          'tempel-previous
        "}"          'tempel-next
        "<escape>"   'tempel-abort
        "RET"        'tempel-done)
      (:bind :state (normal insert)
        "<tab>"      'tempel-next
        "S-<tab>"    'tempel-previous
        "C-<return>" 'tempel-done
        "M-<return>" 'tempel-done))))

;;; .
(provide 'hel-collection-tempel)
;;; hel-collection-tempel.el ends here
