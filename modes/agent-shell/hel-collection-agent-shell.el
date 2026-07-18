;;; hel-collection-agent-shell.el --- Hel bindings for Agent-shell -*- lexical-binding: t -*-
;;
;; Copyright © 2025-2026 Yuriy Artemyev
;;
;; Author: Yuriy Artemyev <anuvyklack@gmail.com>
;; Maintainer: Yuriy Artemyev <anuvyklack@gmail.com>
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Hel keybindings that integrate it with Agent-shell.
;; https://github.com/xenodium/agent-shell
;;
;;; Code:

(eval-when-compile (require 'dash))
(require 'hel)
(require 'hel-collection)

(declare-function comint-next-prompt "comint")
(declare-function comint-skip-prompt "comint")

(declare-function agent-shell-ui-forward-block           "agent-shell")
(declare-function agent-shell-ui-backward-block          "agent-shell")
(declare-function agent-shell-next-permission-button     "agent-shell")
(declare-function agent-shell-previous-permission-button "agent-shell")
(declare-function agent-shell-ui--block-range            "agent-shell")
(declare-function agent-shell-insert                     "agent-shell")
(declare-function agent-shell--get-files-context         "agent-shell")
(declare-function agent-shell--shell-buffer              "agent-shell")
(declare-function agent-shell--dot-subdir                "agent-shell")
(declare-function agent-shell--save-clipboard-image      "agent-shell")

;;; Config

(add-hook 'agent-shell-viewport-edit-mode-hook
          (defun hel-agent-shell-viewport-edit-mode-h ()
            (setf (alist-get ?` hel-surround-alist)
                  '(:insert (lambda ()
                              ;; If selection is linewise enclose it in tripple
                              ;; backticks, otherwise -- in sinlge one.
                              (if (hel-linewise-selection-p)
                                  '("```\n" . "\n```")
                                '("`" . "`")))))))

;;; Keybindings

(hel-collection-setup agent-shell
  (:keymap agent-shell-mode-map
    (:bind
      "C-r" 'comint-history-isearch-backward-regexp)
    (:bind :state normal
      "] ]" 'hel-agent-shell-next-item
      "[ [" 'hel-agent-shell-previous-item
      "C-j" 'hel-agent-shell-next-item
      "C-k" 'hel-agent-shell-previous-item
      "z j" 'hel-agent-shell-next-item
      "z k" 'hel-agent-shell-previous-item
      "z u" 'hel-agent-shell-item-beginning
      "p"   'hel-agent-shell-paste-dwim
      ","    hel-agent-shell-local-leader-map)
    (:bind :state insert
      "C-w" 'hel-delete-backward-word))

  (:initial-state agent-shell-viewport-view-mode emacs)

  (:keymap agent-shell-viewport-view-mode-map
    (:bind :state emacs
      "i"   'hel-normal-state
      "h"   'left-char
      "j"   'next-line
      "k"   'previous-line
      "l"   'right-char
      "g g" 'beginning-of-buffer
      "G"   'end-of-buffer
      "] ]" 'agent-shell-viewport-next-page
      "[ [" 'agent-shell-viewport-previous-page
      "C-j" 'agent-shell-viewport-next-item
      "C-k" 'agent-shell-viewport-previous-item
      "z j" 'agent-shell-viewport-next-item
      "z k" 'agent-shell-viewport-previous-item
      ","    hel-agent-shell-viewport-view-local-leader-map)
    (:bind :state normal
      "<escape>" 'hel-emacs-state
      "q"        'bury-buffer))

  (:keymap agent-shell-viewport-edit-mode-map
    (:bind :state normal
      "[ [" 'agent-shell-viewport-compose-peek-last
      "C-k" 'agent-shell-viewport-previous-history
      "C-j" 'agent-shell-viewport-next-history
      "C-r" 'agent-shell-viewport-search-history
      "p"   'hel-agent-shell-paste-dwim
      ;;
      "Z Z" '("send prompt" . agent-shell-viewport-compose-send)
      "Z Q" '("cancel" . agent-shell-viewport-compose-cancel)
      ","    hel-agent-shell-viewport-edit-local-leader-map))

  (:initial-state agent-shell-diff-mode emacs)
  (:keymap agent-shell-diff-mode-map
    (:bind
      "C-j" 'diff-hunk-next
      "C-k" 'diff-hunk-prev)))

(defvar-keymap hel-agent-shell-local-leader-map
  :doc "<local-leader> in agent-shell mode."
  "RET"   '("set session mode" . agent-shell-set-session-mode)
  "<tab>" '("cycle session mode" . agent-shell-cycle-session-mode)
  ","     '("compose prompt" . agent-shell-prompt-compose)
  "?"     '("help menu" . agent-shell-help-menu)
  "l"     '("clear shell buffer" . agent-shell-clear-buffer)
  "m"     '("set model" . agent-shell-set-session-model)
  "v"     '("switch viewport/shell mode" . agent-shell-other-buffer)
  "s"     '("send screenshot" . agent-shell-send-screenshot)
  "!"     '("shell command" . agent-shell-insert-shell-command-output)
  "p"     '("pending request add" . agent-shell-queue-request)
  "P"     '("pending request remove" . agent-shell-remove-pending-request)
  "t"     '("token usage" . agent-shell-show-usage))

(defvar-keymap hel-agent-shell-viewport-view-local-leader-map
  :doc "<local-leader> in agent-shell viewport mode."
  :parent hel-agent-shell-local-leader-map
  "<tab>" '("cycle session mode" . agent-shell-viewport-cycle-session-mode)
  "RET"   '("set session mode" . agent-shell-viewport-set-session-mode)
  "m"     '("set model" . agent-shell-viewport-set-session-model)
  "?"     '("help menu" . agent-shell-viewport-help-menu))

(defvar-keymap hel-agent-shell-viewport-edit-local-leader-map
  :doc "<local-leader> in agent-shell compose buffer."
  :parent hel-agent-shell-viewport-view-local-leader-map
  ","     '("send prompt" . agent-shell-viewport-compose-send)
  "q"     '("cancel" . agent-shell-viewport-compose-cancel)
  "?"     '("help menu" . agent-shell-viewport-compose-help-menu))

;;; Commands

;; C-j or ]] or zj
(defun hel-agent-shell-next-item ()
  "Go to next item."
  (declare (modes agent-shell-mode))
  (interactive)
  (let* ((prompt-pos (save-excursion
                       (when (comint-next-prompt 1)
                         (point))))
         (block-pos (save-excursion
                      (agent-shell-ui-forward-block)))
         (button-pos (save-excursion
                       (agent-shell-next-permission-button)))
         (next-pos (->> (list prompt-pos
                              block-pos
                              button-pos)
                        (delq nil)
                        (apply #'min))))
    (when next-pos
      (deactivate-mark)
      (goto-char next-pos)
      (when (eq next-pos prompt-pos)
        (comint-skip-prompt)))))

;; C-k or [[ or zk
(defun hel-agent-shell-previous-item ()
  "Go to previous item."
  (declare (modes agent-shell-mode))
  (interactive)
  (let* ((current-pos (point))
         (prompt-pos (save-excursion
                       (when-let* ((pos (comint-next-prompt -1))
                                   ((< pos current-pos)))
                         pos)))
         (block-pos (save-excursion
                      (when-let* ((pos (agent-shell-ui-backward-block))
                                  ((< pos current-pos)))
                        pos)))
         (button-pos (save-excursion
                       (when-let* ((pos (agent-shell-previous-permission-button))
                                   ((< pos current-pos)))
                         pos)))
         (next-pos (-some->> (list prompt-pos
                                   block-pos
                                   button-pos)
                     (delq nil)
                     (apply #'max))))
    (when next-pos
      (deactivate-mark)
      (goto-char next-pos)
      (when (eq next-pos prompt-pos)
        (comint-skip-prompt)))))

;; zu
(defun hel-agent-shell-item-beginning ()
  "Jump to the beginning of current item."
  (declare (modes agent-shell-mode))
  (interactive)
  (when-let*
      ((start-point (point))
       (block-start (when (get-text-property (point) 'agent-shell-ui-state)
                      (if-let* ((block (agent-shell-ui--block-range :position (point))))
                          (map-elt block :start))))
       (target (if (/= (line-number-at-pos block-start)
                       (line-number-at-pos start-point))
                   block-start
                 (save-excursion
                   (goto-char block-start)
                   (when-let* ((prev (text-property-search-backward
                                      'agent-shell-ui-state nil
                                      (lambda (_old-val new-val)
                                        (if new-val
                                            (map-elt new-val :navigatable)))
                                      t)))
                     (prop-match-beginning prev))))))
    (deactivate-mark)
    (goto-char target)))

;; p
(hel-define-command hel-agent-shell-paste-dwim (&optional arg)
  "Paste image or text from clipboard into `agent-shell'.

If the clipboard contains an image, save it and insert as file context.
Otherwise, invoke `hel-paste-after' with ARG as usual.

Needs external utilities.  See `agent-shell-clipboard-image-handlers'
for details."
  :multiple-cursors nil
  (declare (modes agent-shell-mode))
  (interactive "*P")
  (if-let* (((window-system))
            (screenshots-dir (agent-shell--dot-subdir "screenshots"))
            (image-path (agent-shell--save-clipboard-image
                         :destination-dir screenshots-dir
                         :no-error t)))
      (agent-shell-insert
       :text (agent-shell--get-files-context :files (list image-path))
       :shell-buffer (agent-shell--shell-buffer))
    ;; else
    (funcall-interactively #'hel-paste-after arg)))

;;; .
(provide 'hel-collection-agent-shell)
;;; hel-collection-agent-shell.el ends here
