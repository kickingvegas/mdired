;;; mdired-test-utils.el --- TBD -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Charles Y. Choi

;; Author: Charles Y. Choi <kickingvegas@gmail.com>
;; Keywords: tools

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

;;

;;; Code:
(require 'ert)

(defun mdiredt-setup ()
  "Test setup function."
  )

(defun mdiredt-breakdown (&optional clear)
  "Test breakdown function, if CLEAR is non-nil then clear state."
  )


(defun mdired-testbench (dirlist block)
  "Setup mdired testbench with DIRLIST and BLOCK.

- DIRLIST: list of strings
- BLOCK: function to execute

In a new temporary directory:

1. Open new temporary directory in Dired buffer.
2. Create directories specified by DIRLIST.
3. Mark new directories in Dired buffer.
4. Run BLOCK."

  (let* ((temp-dir (make-temp-file "mdired-" t))
         (scratch-dirs (mapcar (lambda (x)
                                 (expand-file-name x temp-dir))
                               dirlist)))
    (unwind-protect
        (progn
          (dired temp-dir)
          (mapc (lambda (sdir)
                  (make-directory sdir)
                  (revert-buffer)
                  (dired-goto-file sdir)
                  (dired-mark nil))
                scratch-dirs)

          (funcall block temp-dir scratch-dirs))
      (delete-directory temp-dir t))))

(provide 'mdired-test-utils)
;;; mdired-test-utils.el ends here
