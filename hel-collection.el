;;; hel-collection.el --- Hel bindings for third-party packages -*- lexical-binding: t -*-
;;
;; Copyright © 2026 Yuriy Artemyev
;;
;; Author: Yuriy Artemyev <anuvyklack@gmail.com>
;; Maintainer: Yuriy Artemyev <anuvyklack@gmail.com>
;; Version: 0.1.0
;; Homepage: https://github.com/anuvyklack/hel-collection
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

;;;###autoload
(defmacro hel-collection-setup (feature &rest body)
  "Apply BODY after FEATURE has been loaded.

The BODY is wrapped in `with-eval-after-load' with FEATURE and
each form is dispatched on its car:

  (:keymap KEYMAP BINDING...)
      KEYMAP is an unquoted keymap symbol, or an unquoted list of them.
      Each nested BINDING form binds into every KEYMAP named.

  (:bind [:state STATE] KEY DEFINITION...)
      Bind KEYs to DEFINITIONs in the enclosing `:keymap'.
      See `hel-keymap-set' for arguments.

  (:unbind [:state STATE] KEY...)
      Remove KEY from the enclosing `:keymap'.

  (:initial-state MODE STATE)
      Enter MODE in the Hel STATE, via `hel-set-initial-state'.

Any other form is passed through unchanged and evaluated once FEATURE
has loaded.

\(fn FEATURE &rest BODY)"
  (declare (indent 1)
           (debug (symbolp &rest sexp)))
  (let ((snapshotted '())   ; maps we have emitted snapshot/restore for
        (all-maps '())      ; every map touched, reported to the hook
        (forms '()))
    (dolist (form body)
      (pcase (car-safe form)
        (:keymap
         (-let* (((_ keymap . bindings) form)
                 (maps (ensure-list keymap)))
           (unless (-all-p #'symbolp maps)
             (error "hel-collection: `:keymap' takes a symbol or a list of them, got %S"
                    keymap))
           (dolist (map maps)
             (unless (memq map all-maps) (push map all-maps))
             (unless (memq map snapshotted)
               (push map snapshotted)
               (push `(hel-collection--snapshot ',map) forms)))
           (dolist (binding bindings)
             (push (hel-collection--expand-binding binding maps) forms))))
        (:initial-state
         (-let [(_ mode state) form]
           (push `(hel-set-initial-state ',(hel-unquote mode)
                                         ',(hel-unquote state))
                 forms)))
        ;; Imperative escape hatch — passed through untouched.
        (_ (push form forms))))
    `(with-eval-after-load ',feature
       ,@(nreverse forms)
       (run-hook-with-args 'hel-collection-setup-hook ',feature ',(nreverse all-maps)))))

(defun hel-collection--expand-binding (form maps)
  "Expand a `:bind' or `:unbind' FORM into `hel-collection--keymap-set' calls.
One call is emitted per keymap symbol in MAPS.  Any other FORM is returned
unchanged, so it rides along as imperative Lisp inside `:keymap'."
  (pcase (car-safe form)
    (:bind
     (-let [((&plist :state) . bindings) (hel-split-keyword-args (cdr form))]
       (unless (cl-evenp (length bindings))
         (error "hel-collection: odd number of KEY/DEFINITION arguments in `:bind'"))
       (macroexp-progn
        (-map (lambda (map)
                `(hel-collection--keymap-set ',map
                   ,@(if state (list :state `',(hel-unquote state)))
                   ,@bindings))
              maps))))
    (:unbind
     (-let [((&plist :state) . keys) (hel-split-keyword-args (cdr form))]
       (macroexp-progn
        (-map (lambda (map)
                `(hel-collection--keymap-set ',map
                   ,@(if state (list :state `',(hel-unquote state)))
                   ,@(-mapcat (lambda (key) (list key nil)) keys)))
              maps))))
    (_ form)))

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

;;; The source walker

(defun hel-collection-walk-mode (mode)
  "Parse MODE's mode file. See `hel-collection-walk-file'."
  (hel-collection-walk-file (hel-collection--mode-file mode)))

(defun hel-collection-walk-file (file)
  "Parse FILE, returning one plist per `hel-collection-setup' form.
Each plist is (:feature FEATURE :keymaps BLOCKS :initial-states STATES
:imperative FORMS), where BLOCKS holds the result of
`hel-collection--walk-keymap-form' — a (:maps SYMS :bindings BINDINGS)
plist — for each `:keymap' block, INITIAL-STATES is a list of
\(MODE . STATE), and IMPERATIVE is the plain Lisp forms — everything the
grammar does not recognise.

Note the two levels: the outer `:keymaps' is the list of blocks, the
inner `:maps' the symbols one block binds into."
  (->> (hel-collection--read-file file)
       (-filter (lambda (form)
                  (eq 'hel-collection-setup (car-safe form))))
       (-map #'hel-collection--walk-setup-form)))

(defun hel-collection--read-file (file)
  "Read FILE and return its top-level forms."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (cl-loop for form = (condition-case nil
                            (read (current-buffer))
                          (end-of-file nil))
             while form collect form)))

(defun hel-collection--walk-keymap-form (form)
  "Walk a `:keymap' FORM.  Return a plist (:maps SYMS :bindings BINDINGS).
MAPS is a list even when the source named a single map, and the bindings
are shared by all of them — the grouping the author wrote is preserved
rather than fanned out, so a README can render one table for the group.
A consumer that wants per-map data takes the cross product itself.

Each binding is a plist (:key KEY :definition DEF :state STATE)."
  (-let [(_ keymaps . body) form]
    (list
     :maps (ensure-list keymaps)
     :bindings (-mapcat
                (-lambda ((keyword . args))
                  (-let* (((kwargs . args) (hel-split-keyword-args args))
                          (state (-> (plist-get kwargs :state)
                                     (hel-unquote))))
                    (pcase keyword
                      (:bind (-map (-lambda ((key definition))
                                     (list :key key :definition definition :state state))
                                   (-partition 2 args)))
                      (:unbind (-map (lambda (key)
                                       (list :key key :definition nil :state state))
                                     args)))))
                body))))

(defun hel-collection--walk-setup-form (form)
  "Walk a `hel-collection-setup' FORM.  See `hel-collection-walk-file'."
  (-let [(_ feature . body) form]
    (let (keymaps initial-states imperative)
      (dolist (subform body)
        (pcase (car-safe subform)
          (:keymap (push (hel-collection--walk-keymap-form subform)
                         keymaps))
          (:initial-state
            (-let [(_ mode state) subform]
              (push (cons (hel-unquote mode)
                          (hel-unquote state))
                    initial-states)))
          (_ (push subform imperative))))
      (list :feature feature
            :keymaps (nreverse keymaps)
            :initial-states (nreverse initial-states)
            :imperative (nreverse imperative)))))

;;; Development reload

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
         (maps (->> (hel-collection-walk-file file)
                    (-mapcat (lambda (form) (plist-get form :keymaps)))
                    (-mapcat (lambda (block) (plist-get block :maps)))
                    (-distinct))))
    (-each maps #'hel-collection--restore)
    (load-file file)))

;;; .
(provide 'hel-collection)
;;; hel-collection.el ends here
