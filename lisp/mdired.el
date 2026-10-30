;;; mdired.el --- SIMD-style commands for marked Dired items -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Charles Y. Choi

;; Author: Charles Y. Choi <kickingvegas@gmail.com>
;; URL: https://github.com/kickingvegas/mdired
;; Keywords: tools
;; Package-Version: 0.3.1-rc.1
;; Package-Requires: ((emacs "30.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; mdired is an Elisp package that provides commands for running SIMD-style
;; operations on marked Dired items.

;; Please be advised: mdired can make irreversible changes to the file system if
;; no prior checkpoint (typically via a source code management or backup tool)
;; is available. Exercise caution.

;; INSTALL

;; If manually installed then ensure that mdired.el is in `load-path'.

;; If installed via `package-install', then all mdired commands are auto-loaded.

;;; Code:
(require 'dired)
(require 'compile)

;;;###autoload (autoload 'mdired-do-command "mdired" nil '(dired-mode))
(defun mdired-do-command (command)
  "Run Elisp COMMAND on marked Dired items.

For all marked Dired items, call `find-file' and then run COMMAND on
each item in sequential fashion. After this command has been run, any
buffers that are modified will remain open and unsaved.

COMMAND may be an interactive command or a named keyboard macro.

Note: `mdired-do-command' does not check if a marked Dired item is a
file or directory. The marked Dired item should handle COMMAND
gracefully.

If a COMMAND on a marked item results in an error, the error is ignored;
COMMAND will still be run on all remaining marked items."
  (interactive "CRun on marked files M-x " dired-mode)
  (save-window-excursion
    (mapc (lambda (filename)
            (find-file filename)
            (ignore-errors
              (call-interactively command)))
          (dired-get-marked-files))))

;;;###autoload (autoload 'mdired-copy "mdired" nil '(dired-mode))
(defun mdired-copy (&optional arg)
  "Copy current Dired item to marked Dired items with overwrite policy ARG.

For all marked Dired items, copy the current Dired item to it. If the
marked item is a directory, the current item is copied into it. If the
marked item is a file, the current Dired item will write over it per the
policy determined via the command prefix ARG.

If no command prefix \\[universal-argument] is set, then the user will
be prompted to select an overwrite policy as described in `copy-file'.
The options provided are:

  - never : do not overwrite marked file
  - overwrite : overwrite marked file
  - ask : prompt user if marked file should be overwritten.

If the command prefix \\[universal-argument] is set, then marked files
will be overwritten without prompt."
  (interactive "P" dired-mode)
  (let* ((arg (if (not arg)
                  (completing-read "Overwrite Policy: "
                                   '("never" "overwrite" "ask")
                                   nil nil "ask")
                "overwrite"))
         (ok-flag (cond
                   ((string-equal "never" arg) nil)
                   ((string-equal "overwrite" arg) t)
                   ((string-equal "ask" arg) 1)))
         (source (dired-get-filename))
         (targets (dired-get-marked-files)))

    (if (member source targets)
        (error "Source ‘%s’ cannot be a target" source)
      (mapc (lambda (target)
              (let ((target (if (and (file-directory-p target)
                                     (not (string-equal (substring target -1) "/")))
                                (concat target "/")
                              target)))
                (ignore-errors
                  (copy-file source target ok-flag))))
            targets))))

(defun mdired-directory-p (targets)
  "Predicate if all elements in TARGETS are directories."
  (let ((tests (mapcar (lambda (target)
                          (file-directory-p target))
                        targets)))
    (seq-reduce (lambda (a b)
                  (and a b))
                tests t)))

;;;###autoload (autoload 'mdired-compile "mdired" nil '(dired-mode))
(defun mdired-compile ()
  "Run `compile' on marked Dired directories.

For all marked directories, run `compile' on each directory, with output
placed in a uniquely named buffer of the form

  \"*compilation - %s*\"

where \"%s\" is the name of the marked directory.

`mdired-compile' pre-checks that all marked items are directories and
will not execute if not true.

Refer to Info node `(emacs)Compilation' for detail on `compile'."
  (interactive nil dired-mode)

  (let* ((command (compilation-read-command (eval compile-command)))
         (targets (dired-get-marked-files)))

    (if (mdired-directory-p targets)
        (mapc (lambda (target)
                (let ((new-name (format "*compilation - %s*" (file-name-nondirectory
                                                              (directory-file-name target))))
                      (default-directory target))
                  (compilation-start command nil (lambda (_mode)
                                                   new-name))))
              targets)
      (error "ERROR: All marked files must be directories"))))

;;;###autoload (autoload 'mdired-byte-recompile "mdired" nil '(dired-mode))
(defun mdired-byte-recompile ()
  "Byte recompile marked Elisp files or directories.

For all marked items, run either `byte-recompile-directory' if the item
is a directory, or `byte-recompile-file' if the item is an Elisp file."
  (interactive nil dired-mode)

  (let ((targets (dired-get-marked-files)))
    (mapc (lambda (target)
            (cond
             ((file-directory-p target)
              (let* ((default-directory target))
                (byte-recompile-directory target)))

             ((string-equal (file-name-extension target) "el")
              (byte-recompile-file target))

             (t
              (error "Invalid target for byte-compilation: %s" target))))
              targets)))

(provide 'mdired)
;;; mdired.el ends here
