;;; hel-collection-deadgrep.el --- Hel bindings for Deadgrep -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-lib)
(require 'hel-collection)

(defvar deadgrep--search-term)

(declare-function deadgrep                           "deadgrep")
(declare-function deadgrep-restart                   "deadgrep")
(declare-function deadgrep-search-term               "deadgrep")
(declare-function deadgrep-visit-result              "deadgrep")
(declare-function deadgrep-visit-result-other-window "deadgrep")
(declare-function deadgrep-forward-match             "deadgrep")
(declare-function deadgrep-backward-match            "deadgrep")

;;; Keybindings in Deadgrep buffer

(hel-collection-setup deadgrep
  (:keymap deadgrep-mode-map
    (:unbind "g")
    (:bind
      "i"   'deadgrep-edit-mode

      "a"   'deadgrep-incremental ; "a" for amend
      "g r" 'deadgrep-restart     ; also "C-w r"

      "RET" 'deadgrep-visit-result-other-window

      "o"   'hel-collection-deadgrep-show-result-other-window
      "C-o" 'hel-collection-deadgrep-show-result-other-window

      "n"   'deadgrep-forward-match
      "N"   'deadgrep-backward-match

      "C-j" 'hel-collection-deadgrep-forward-match-show-other-window
      "C-k" 'hel-collection-deadgrep-backward-match-show-other-window

      "}"   'deadgrep-forward-filename
      "{"   'deadgrep-backward-filename
      "] p" 'deadgrep-forward-filename
      "[ p" 'deadgrep-backward-filename

      "z j" 'deadgrep-forward-filename
      "z k" 'deadgrep-backward-filename
      "z u" 'deadgrep-parent-directory))

  (:keymap deadgrep-edit-mode-map
    (:bind :state normal
      "<escape>" 'deadgrep-mode
      "z x" 'deadgrep-mode
      "Z Z" 'deadgrep-mode
      "RET" 'deadgrep-visit-result-other-window

      ;; Commands bound to these keys have no sense for Deadgrep.
      "o"   'undefined
      "O"   'undefined
      "J"   'undefined)))

;;; Hooks and Advices

(add-hook 'deadgrep-mode-hook
          (defun hel-collection--deadgrep-mode-h ()
            ;; TODO: upstream this
            (setq-local revert-buffer-function (lambda (&rest _)
                                                 (deadgrep-restart)))))

(hel-advice-add 'deadgrep-mode :before 'hel-deactivate-mark-a)
(hel-advice-add 'deadgrep-mode :before 'hel-disable-multiple-cursors-mode)

(hel-advice-add 'deadgrep-visit-result              :around 'hel-jump-command-a)
(hel-advice-add 'deadgrep-visit-result-other-window :around 'hel-jump-command-a)

;; TODO: upstream this
(advice-add 'deadgrep             :after 'hel-collection--deadgrep-set-list-buffers-directory-a)
(advice-add 'deadgrep-search-term :after 'hel-collection--deadgrep-set-list-buffers-directory-a)

(defun hel-collection--deadgrep-set-list-buffers-directory-a (&rest _)
  "Set `list-buffers-directory' for search query so it displays nicely in Ibuffer."
  (setq-local list-buffers-directory
              (format "query: %s" deadgrep--search-term)))

;;; Commands

;; o or C-o
(defun hel-collection-deadgrep-show-result-other-window ()
  "Show search result at point in another window."
  (interactive)
  (unless next-error-follow-minor-mode
    (hel-recenter-point-on-jump
      (save-selected-window
        (deadgrep-visit-result-other-window)
        (deactivate-mark)))))

;; C-j
(defun hel-collection-deadgrep-forward-match-show-other-window ()
  "Move point to next search result and show it in another window."
  (interactive)
  (deadgrep-forward-match)
  (hel-collection-deadgrep-show-result-other-window))

;; C-k
(defun hel-collection-deadgrep-backward-match-show-other-window ()
  "Move point to previous search result and show it in another window."
  (interactive)
  (deadgrep-backward-match)
  (hel-collection-deadgrep-show-result-other-window))

;;; .
(provide 'hel-collection-deadgrep)
;;; hel-collection-deadgrep.el ends here
