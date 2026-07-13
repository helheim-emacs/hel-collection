;;; hel-collection-isearch.el --- Disable Isearch -*- lexical-binding: t -*-
;;; Commentary:
;;
;; This module unbinds Isearch keys. Isearch doesn't play well with multiple
;; cursors so Hel ships its own search.
;;
;;; Code:

(require 'hel-collection)

(hel-collection-setup isearch
  (:keymap global-map
    (:unbind
      "C-s"     ;; `isearch-forward'
      "C-M-s"   ;; `isearch-forward-regexp'
      "C-r"     ;; `isearch-backward'
      "C-M-r")) ;; `isearch-backward-regexp'
  (:keymap search-map
    (:unbind
      "w"       ;; `isearch-forward-word'
      "_"       ;; `isearch-forward-symbol'
      "."       ;; `isearch-forward-symbol-at-point'
      "M-."))   ;; `isearch-forward-thing-at-point'
  (:keymap help-map
    (:unbind "C-s")) ;; `search-forward-help-for-help'
  ;;
  ;; After deleting "M-." from `search-map' there remain an empty keymap:
  ;; `(27 keymap)' which blocks access to "g" and "m" keys from `hel-leader'.
  ;; 27 is ASCII code for ESC. This is about how Emacs works: key sequences
  ;; starts with ESC are accessible via Meta key.
  (cl-callf2 assq-delete-all 27 search-map))

(hel-collection-setup embark
  (:keymap embark-general-map
    (:unbind
      "C-s"   ;; `embark-isearch-forward'
      "C-r")) ;; `embark-isearch-backward'
  (:keymap embark-collect-mode-map
    (:unbind "s"))) ;; `isearch-forward'

(provide 'hel-collection-isearch)
;;; hel-collection-isearch.el ends here
