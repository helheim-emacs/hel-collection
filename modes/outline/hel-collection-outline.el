;;; hel-collection-outline.el --- Hel bindings for outline -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup outline
  (:keymap outline-mode-prefix-map
    (:unbind "/"))

  (:keymap (outline-mode-map
            outline-minor-mode-map)
    (:bind :state normal
      "m h"     'hel-collection-outline-mark-subtree ; "h" is for heading
      "m i h"   'hel-collection-outline-mark-subtree
      "m o"     'hel-collection-outline-mark-subtree ; "o" is for outline
      "m i o"   'hel-collection-outline-mark-subtree)
    (:bind :state (normal emacs)
      "z <tab>"     'outline-cycle
      "z <backtab>" 'outline-cycle-buffer
      "z <return>"  'outline-insert-heading
      "z j"     'outline-next-visible-heading
      "z k"     'outline-previous-visible-heading
      "z C-j"   'outline-forward-same-level
      "z C-k"   'outline-backward-same-level
      "z u"     'hel-collection-outline-up-heading
      "z o"     'hel-collection-outline-open
      "z c"     'outline-hide-subtree
      "z r"     'outline-show-all
      "z m"     'outline-hide-sublevels
      "z 2"     'hel-collection-outline-show-2-sublevels
      "z 3"     'hel-collection-outline-show-3-sublevels
      "z p"     'hel-collection-outline-hide-other ; "p" for path
      "z O"     'outline-show-branches
      "z <"     'outline-promote
      "z >"     'outline-demote
      "z M-h"   'outline-promote
      "z M-l"   'outline-demote
      "z M-j"   'outline-move-subtree-down
      "z M-k"   'outline-move-subtree-up
      "z / s"   'outline-show-by-heading-regexp
      "z / h"   'outline-hide-by-heading-regexp))

  (:keymap outline-navigation-repeat-map
    (:unbind "C-b" "b" "C-f" "f" "C-n" "n" "C-p" "p")
    (:bind
      "j"   'outline-next-visible-heading
      "k"   'outline-previous-visible-heading
      "C-j" 'outline-forward-same-level
      "C-k" 'outline-backward-same-level))

  (:keymap outline-editing-repeat-map
    (:unbind "C-v" "v" "C-^" "^" "C->" "C-<")
    (:bind
      "M-h" 'outline-promote
      "M-l" 'outline-demote
      "M-j" 'outline-move-subtree-down
      "M-k" 'outline-move-subtree-up)))

;;; Commands

(declare-function outline-on-heading-p             "outline")
(declare-function outline-up-heading               "outline")
(declare-function outline-back-to-heading          "outline")
(declare-function outline-previous-visible-heading "outline")
(declare-function outline-end-of-subtree           "outline")
(declare-function outline-show-entry               "outline")
(declare-function outline-show-children            "outline")
(declare-function outline-show-branches            "outline")
(declare-function outline-hide-other               "outline")
(declare-function outline-hide-sublevels           "outline")

(hel-define-advice outline-up-heading (:before (&rest _) push-mark)
  (hel-push-point))

(defun hel-collection-outline-up-heading (count &optional invisible-ok)
  "Move up in the outline hierarchy to the parent heading."
  (interactive "p")
  (hel-disable-multiple-cursors-mode)
  (deactivate-mark)
  (hel-push-point)
  (if (outline-on-heading-p invisible-ok)
      (outline-up-heading count invisible-ok)
    (outline-back-to-heading invisible-ok)
    (cl-decf count)
    (unless (zerop count)
      (outline-up-heading count invisible-ok))))

(put 'hel-collection-outline-up-heading 'repeat-map 'outline-navigation-repeat-map)

(defun hel-collection-outline-open ()
  (interactive)
  (outline-show-entry)
  (outline-show-children))

(defun hel-collection-outline-hide-other ()
  (interactive)
  (outline-hide-other)
  (outline-show-branches))

(defun hel-collection-outline-show-2-sublevels ()
  "Remain 2 top levels of headings visible."
  (interactive)
  (outline-hide-sublevels 2))

(defun hel-collection-outline-show-3-sublevels ()
  "Remain 2 top levels of headings visible."
  (interactive)
  (outline-hide-sublevels 3))

(defun hel-collection-outline-mark-subtree ()
  "Mark the current subtree in an outlined document."
  (interactive)
  (hel-push-point)
  (if (outline-on-heading-p)
      ;; we are already looking at a heading
      (forward-line 0)
    ;; else go back to previous heading
    (outline-previous-visible-heading 1))
  (hel-set-region (point)
                  (progn (outline-end-of-subtree)
                         (unless (eobp) (forward-char))
                         (point))
                  -1)
  (hel-reveal-point-when-on-top))

;;; .
(provide 'hel-collection-outline)
;;; hel-collection-outline.el ends here
