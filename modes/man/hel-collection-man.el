;;; hel-collection-man.el --- Hel bindings for Man -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)
(declare-function Man-update-manpage "man")

(hel-collection-setup man
  (:initial-state Man-mode normal)
  ;; User may also enable `outline-minor-mode' in a Man buffer, so the keys
  ;; should possibly not interfere with it.
  (:keymap Man-mode-map
    (:bind :state normal
      "] ]" 'Man-next-manpage
      "[ [" 'Man-previous-manpage
      "z h" 'Man-previous-manpage ;; left
      "z l" 'Man-next-manpage     ;; right
      "z j" 'Man-next-section     ;; down
      "z k" 'Man-previous-section ;; up
      "z /" 'Man-goto-section     ;; On "z" layer because related to sections.
      "g r" 'Man-follow-manual-reference)) ; go to reference
  ;;
  (add-hook 'Man-mode-hook 'hel-collection-man-mode-h))

(defun hel-collection-man-mode-h ()
  "Make `revert-buffer' refetch the manpage."
  (setq-local revert-buffer-function (lambda (&rest _)
                                       (Man-update-manpage))))

(provide 'hel-collection-man)
;;; hel-collection-man.el ends here
