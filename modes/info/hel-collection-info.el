;;; hel-collection-info.el --- Hel bindings for Info -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup info
  (:initial-state Info-mode normal)
  (:keymap Info-mode-map
    (:bind :state emacs
      "i"     'hel-normal-state)
    (:bind :state normal
      "C-j"   'Info-next
      "C-k"   'Info-prev
      "z j"   'Info-forward-node
      "z k"   'Info-backward-node
      "z u"   'Info-up
      "z d"   'Info-directory
      "z ~"   'Info-directory ;; "~" is for "home"
      ;;
      "z h"   'Info-history
      "u"     'Info-history-back
      "U"     'Info-history-forward
      "C-<i>" 'Info-history-forward
      "C-o"   'Info-history-back
      ;;
      "g t"   'Info-toc
      "g i"   'Info-index ;; imenu
      "g I"   'Info-virtual-index
      "g m"   'Info-menu
      ;;
      "z i"   'Info-index
      "z I"   'Info-virtual-index
      ;;
      "M-h"   'Info-help
      ;; <local-leader>
      "," (define-keymap
            "t" 'Info-toc
            "i" 'Info-index
            "I" 'Info-virtual-index
            "m" 'Info-menu
            "h" 'Info-history
            "u" 'Info-history-back
            "U" 'Info-history-forward)
      "<escape>" 'undefined)))

(hel-advice-add 'Info-next-reference :before 'hel-deactivate-mark-a)
(hel-advice-add 'Info-prev-reference :before 'hel-deactivate-mark-a)

(provide 'hel-collection-info)
;;; hel-collection-info.el ends here
