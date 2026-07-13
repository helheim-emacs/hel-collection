;;; hel-collection-calendar.el --- Hel bindings for calendar -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'hel-collection)

(hel-collection-setup calendar
  (:keymap calendar-mode-map
    ;; Both are commands in the pristine map — `calendar-backward-year' and
    ;; `calendar-forward-year' — so they cannot carry the "[ [" / "] ]"
    ;; prefixes below until they are gone.
    (:unbind "[" "]")
    (:bind
      ;; motions
      "h"    'calendar-backward-day
      "j"    'calendar-forward-week
      "k"    'calendar-backward-week
      "l"    'calendar-forward-day
      "g h"  'calendar-beginning-of-week
      "g l"  'calendar-end-of-week
      "("    'calendar-beginning-of-month
      ")"    'calendar-end-of-month
      "{"    'calendar-backward-month
      "}"    'calendar-forward-month
      "g g"  'calendar-beginning-of-year
      "G"    'calendar-end-of-year
      "[ ["  'calendar-backward-year
      "] ]"  'calendar-forward-year
      ;; holidays
      "v"    'calendar-set-mark
      "u"    'calendar-unmark
      "="    'calendar-count-days-region
      "g H"  'calendar-hebrew-goto-date ; "gh"
      "r"    'calendar-cursor-holidays) ; "h"

    ;; Scrolling
    ;;   Bind these into the base keymap so they show up in "<F1> m"
    ;; (`describe-mode').
    (:bind
      "C-d"  'calendar-scroll-left
      "C-u"  'calendar-scroll-right
      "C-f"  'calendar-scroll-left-three-months
      "C-b"  'calendar-scroll-right-three-months)
    ;; Repeat them in Emacs state so they actually work, overriding the
    ;; default scroll commands.
    (:bind :state emacs
      "C-d"  'calendar-scroll-left
      "C-u"  'calendar-scroll-right
      "C-f"  'calendar-scroll-left-three-months
      "C-b"  'calendar-scroll-right-three-months)))

(provide 'hel-collection-calendar)
;;; hel-collection-calendar.el ends here
