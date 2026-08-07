;;; hel-collection.el --- Hel bindings for third-party packages -*- lexical-binding: t -*-
;;
;; Copyright © 2026 Yuriy Artemyev
;;
;; Author: Yuriy Artemyev <anuvyklack@gmail.com>
;; Maintainer: Yuriy Artemyev <anuvyklack@gmail.com>
;; Version: 0.2.0
;; Homepage: https://github.com/helheim-emacs/hel-collection
;; Package-Requires: ((emacs "29.1") (dash "2.19.1") (hel "0.12.0"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Keybindings for third-party and built-in Emacs packages to use them with Hel.
;; Bindings are written directly into the package's own keymap, instead of Hel
;; Emacs state so they show up in `describe-mode' (<F1> m) as real,
;; native bindings.
;;
;;; Code:

(require 'cl-lib)
(require 'dash)
(require 'hel)

(defgroup hel-collection nil
  "Hel keybindings for third-party packages."
  :group 'hel
  :prefix "hel-collection-")

(defcustom hel-collection-setup-hook nil
  "Abnormal hook run after a `hel-collection-setup' form has been applied.
This is the place to run code once a feature has loaded and after
hel-collection has finished its setup. Bind keys in this hook if you
want your bindings survive the mode file reloading.

Each function is called with (FEATURE KEYMAPS &rest _).
KEYMAPS is the list of keymap symbols the form touched.
The `&rest _' is required for forward compatibility."
  :type 'hook)

(defun hel-collection--locate-base-dir (file)
  "Return the directory holding hel-collection's `modes' directory.
FILE is the path hel-collection was loaded from."
  (when file
    (let ((source (concat (file-name-sans-extension file) ".el")))
      (->> (list file source (file-truename source))
           (-map #'file-name-directory)
           (-uniq)
           (-first (lambda (dir)
                     (file-directory-p (expand-file-name "modes" dir))))))))

(defvar hel-collection--base-dir
  (hel-collection--locate-base-dir (or load-file-name buffer-file-name))
  "The directory hel-collection's mode files are loaded relative to.
Mode files live under `modes' below it and are loaded by path rather
than through `load-path', to not overpopulate it.")

;;; Filters

(defcustom hel-collection-key-denylist nil
  "Keys hel-collection must not touch."
  :type '(repeat string))

(defun hel-collection--keys-conflict-p (key1 key2)
  "Return non-nil if key sequences KEY1 and KEY2 conflict.
Two keys conflict when one is a prefix of the other, so that denying
a prefix key suppresses everything under it."
  (let* ((k1 (key-parse key1))
         (k2 (key-parse key2))
         (n (min (length k1)
                 (length k2))))
    (equal (substring k1 0 n)
           (substring k2 0 n))))

(defun hel-collection--key-allowed-p (key)
  "Return non-nil if hel-collection may touch KEY."
  (not (-any? (lambda (k) (hel-collection--keys-conflict-p k key))
              hel-collection-key-denylist)))

;;; The pristine snapshot

(defvar hel-collection--pristine (make-hash-table :test 'eq)
  "KEYMAP-SYMBOL -> KEYMAP-COPY of the keymap as it was before we touched it.")

(defun hel-collection--snapshot (keymap-symbol)
  "Record the pristine state of KEYMAP-SYMBOL, once."
  (unless (gethash keymap-symbol hel-collection--pristine)
    (puthash keymap-symbol (copy-keymap (symbol-value keymap-symbol))
             hel-collection--pristine)))

(defun hel-collection--restore (keymap-symbol)
  "Restore KEYMAP-SYMBOL to its pristine state, in place."
  (when-let* ((pristine (gethash keymap-symbol hel-collection--pristine)))
    ;; Use `setcdr' instead of `setq' to keep the original object rather
    ;; then allocate the new one.
    (setcdr (symbol-value keymap-symbol)
            (cdr (copy-keymap pristine)))))

;;;###autoload
(defun hel-collection-restore (&optional keymap-symbol)
  "Undo hel-collection's changes, restoring keymaps to their pristine state.
With no argument, restore every keymap hel-collection has snapshotted.
With a prefix argument, prompt for a single KEYMAP-SYMBOL to restore."
  (interactive
   (list (when current-prefix-arg
           (let (symbols)
             (maphash (lambda (k _v) (push k symbols))
                      hel-collection--pristine)
             (intern (completing-read "Restore keymap: " symbols nil t))))))
  (if keymap-symbol
      (hel-collection--restore keymap-symbol)
    (maphash (lambda (k _v) (hel-collection--restore k))
             hel-collection--pristine)))

;;; Binding

(defun hel-collection--keymap-set (keymap-symbol &rest args)
  "Bind KEY to DEFINITION in the keymap named by KEYMAP-SYMBOL.
KEYMAP-SYMBOL should be a symbol, not keymap itself. All other arguments
are the same as for `hel-keymap-set'.

\(fn KEYMAP-SYMBOL [:state STATE] &rest [KEY DEFINITION]...)"
  (declare (indent defun))
  (-let* ((keymap (if (boundp keymap-symbol)
                      (symbol-value keymap-symbol)
                    (error "hel-collection: keymap `%s' is not bound"
                           keymap-symbol)))
          ((kwargs . keys) (hel-split-keyword-args args)))
    (setq keys (->> keys
                    (-partition 2)
                    (-filter (-lambda ((key _))
                               (hel-collection--key-allowed-p key)))
                    (-flatten-n 1)))
    (when keys
      (apply #'hel-keymap-set keymap (append kwargs keys)))))

;;; The expander

(defvar hel-collection--feature nil
  "Feature of the `hel-collection-setup' form being expanded.
Bound only during macro expansion.")

(defvar hel-collection--keymaps nil
  "Keymap symbols established by the enclosing `:keymap' form.
Bound only during macro expansion.")

(defvar hel-collection--snapshotted nil
  "Keymaps that already got a `hel-collection--snapshot' call in this form.
Bound only during macro expansion.")

(defvar hel-collection--touched nil
  "Every keymap the `hel-collection-setup' form being expanded names.
Reported to `hel-collection-setup-hook' and recorded for reloading.
Bound only during macro expansion.")

(defvar hel-collection-macros nil
  "Alist of (KEYWORD . EXPANDER) used as a `macroexpand-all' environment.")

(defun hel-collection--expand (body)
  "Expand hel-collection's keywords in BODY, a list of forms."
  (macroexpand-all (macroexp-progn body)
                   (append hel-collection-macros
                           macroexpand-all-environment)))

(defun hel-collection--binding-maps (keyword)
  "Return the keymaps KEYWORD binds into, or signal if there are none."
  (or hel-collection--keymaps
      (error "hel-collection: `%s' outside a `:keymap' form" keyword)))

(setf (alist-get :after-load hel-collection-macros)
      (lambda (&rest body)
        ;; Returned unexpanded on purpose: `macroexpand-all' keeps walking
        ;; its own output, so the body is expanded for us.  Only a keyword
        ;; that establishes context has to expand its body itself.
        `(with-eval-after-load ',hel-collection--feature ,@body)))

(setf (alist-get :keymap hel-collection-macros)
      (lambda (keymap &rest body)
        (let ((maps (ensure-list keymap)))
          (unless (-all-p #'symbolp maps)
            (error "hel-collection: `:keymap' takes a symbol or a list of them, got %S" keymap))
          (let ((fresh (-difference maps hel-collection--snapshotted)))
            (cl-callf append hel-collection--touched maps)
            (cl-callf append hel-collection--snapshotted fresh)
            (macroexp-progn
             (append (-map (lambda (map) `(hel-collection--snapshot ',map))
                           fresh)
                     (list (let ((hel-collection--keymaps maps))
                             (hel-collection--expand body)))))))))

(setf (alist-get :bind hel-collection-macros)
      (lambda (&rest args)
        (-let [((&plist :state) . bindings) (hel-split-keyword-args args)]
          (unless (cl-evenp (length bindings))
            (error "hel-collection: odd number of KEY/DEFINITION arguments in `:bind'"))
          (macroexp-progn
           (-map (lambda (map)
                   `(hel-collection--keymap-set ',map
                      ,@(if state (list :state `',(hel-unquote state)))
                      ,@bindings))
                 (hel-collection--binding-maps :bind))))))

(setf (alist-get :unbind hel-collection-macros)
      (lambda (&rest args)
        (-let [((&plist :state) . keys) (hel-split-keyword-args args)]
          (macroexp-progn
           (-map (lambda (map)
                   `(hel-collection--keymap-set ',map
                      ,@(if state (list :state `',(hel-unquote state)))
                      ,@(-mapcat (lambda (key) (list key nil)) keys)))
                 (hel-collection--binding-maps :unbind))))))

(setf (alist-get :initial-state hel-collection-macros)
      (lambda (mode state)
        `(hel-set-initial-state ',(hel-unquote mode) ',(hel-unquote state))))

;;;###autoload
(defmacro hel-collection-setup (feature &rest body)
  "Configure FEATURE.

A form in BODY whose car is one of the keywords below is expanded in
place, at any depth: the body is walked by `macroexpand-all', so a
keyword nested inside a `when', a `let' or a `with-eval-after-load'
expands just as one written at the top of BODY does.  Data behind
`quote' is left alone.  Any other form is plain imperative Lisp and is
passed through untouched.

The keywords:

  (:after-load BODY...)
      Evaluate BODY once FEATURE has been loaded.

  (:keymap KEYMAP BODY...)
      KEYMAP is an unquoted keymap symbol, or an unquoted list of them.
      Each `:bind' or `:unbind' in BODY binds into every KEYMAP named.

  (:bind [:state STATE] KEY DEFINITION...)
      Bind KEYs to DEFINITIONs in the enclosing `:keymap'.
      See `hel-keymap-set' for arguments.

  (:unbind [:state STATE] KEY...)
      Remove KEY from the enclosing `:keymap'.

  (:initial-state MODE STATE)
      Enter MODE in the Hel STATE, via `hel-set-initial-state'.

\(fn FEATURE &rest BODY)"
  (declare (indent 1)
           (debug (symbolp &rest sexp)))
  (let* ((hel-collection--feature feature)
         (hel-collection--keymaps nil)
         (hel-collection--snapshotted nil)
         (hel-collection--touched nil)
         (expansion (hel-collection--expand body))
         (maps (-uniq hel-collection--touched)))
    `(progn
       (hel-collection--record-keymaps ',maps)
       ,@(macroexp-unprogn expansion)
       (with-eval-after-load ',feature
         (run-hook-with-args 'hel-collection-setup-hook
                             ',feature ',maps)))))

(put :after-load    'lisp-indent-function 0)
(put :keymap        'lisp-indent-function 1)
(put :bind          'lisp-indent-function 'defun)
(put :unbind        'lisp-indent-function 'defun)
(put :initial-state 'lisp-indent-function 'defun)

;;; Mode files

(defun hel-collection--modes-dir ()
  "Return hel-collection's `modes' directory.
Signal an error if it could not be located."
  (or (and hel-collection--base-dir
           (expand-file-name "modes" hel-collection--base-dir))
      (error "hel-collection: cannot locate the `modes' directory next to %s"
             (or load-file-name buffer-file-name "hel-collection.el"))))

(defun hel-collection--mode-file (mode)
  "Return the path of MODE's mode file."
  (expand-file-name (format "%s/hel-collection-%s.el" mode mode)
                    (hel-collection--modes-dir)))

(defun hel-collection-modes ()
  "Return the list of modes shipped with hel-collection."
  (->> (directory-files (hel-collection--modes-dir)
                        nil directory-files-no-dot-files-regexp)
       (-map #'intern)
       (-filter (lambda (mode)
                  (file-exists-p (hel-collection--mode-file mode))))))

(defun hel-collection--load-mode-file (mode)
  "Load MODE's mode file.
This only registers `with-eval-after-load' forms; nothing is bound yet."
  (let ((file (hel-collection--mode-file mode)))
    (if (file-exists-p file)
        (load (file-name-sans-extension file) nil t)
      (error "hel-collection: no mode file for `%s'" mode))))

;;;###autoload
(cl-defun hel-collection-init (&optional (modes (hel-collection-modes)))
  "Enable Hel bindings for MODES, defaulting to every shipped mode file.
MODES is a mode symbol or a list of them."
  (-each (ensure-list modes) #'hel-collection--load-mode-file))

;;; Development reload

(defvar hel-collection--file-keymaps (make-hash-table :test 'equal)
  "FILE -> the keymaps the `hel-collection-setup' forms in FILE name.
Filled at load time by `hel-collection--record-keymaps', which every
expansion calls, and read by `hel-collection-reload-file' to know what to
restore.")

(defun hel-collection--record-keymaps (maps)
  "Record that the file currently being loaded names MAPS.
Every `hel-collection-setup' expansion opens with a call to this, which
runs while `load-file-name' still names the mode file.  The key is the
`.el' truename, so loading the source and loading the byte-compiled file
land on the same entry."
  (when-let* ((file (or load-file-name buffer-file-name))
              (key (file-truename
                    (concat (file-name-sans-extension file) ".el"))))
    (puthash key
             (-union (gethash key hel-collection--file-keymaps) maps)
             hel-collection--file-keymaps)))

;;;###autoload
(defun hel-collection-reload-file (&optional file)
  "Reapply all keybindings defined in FILE.

Restore the original versions of all keymaps modified by FILE from their
snapshots, then reapply all keybinding changes. This also removes any
keybindings that were deleted from the source file but are still present
in the active keymaps.

This function is intended for development, so you do not need to restart
Emacs after editing keybindings."
  (interactive (list buffer-file-name))
  (let* ((file (or file buffer-file-name
                   (error "hel-collection: no file to reload")))
         (maps (gethash (file-truename file) hel-collection--file-keymaps)))
    (-each maps #'hel-collection--restore)
    (load-file file)))

;;; .
(provide 'hel-collection)
;;; hel-collection.el ends here
