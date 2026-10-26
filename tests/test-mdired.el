;;; test-mdired.el --- Casual Suite Tests      -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Charles Y. Choi

;; Author: Charles Choi <kickingvegas@gmail.com>
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
(require 'project)
(require 'mdired-test-utils)
(require 'mdired)

(ert-deftest test-mdired-do-command ()
  "Test for `mdired-do-command'."

  (mdired-testbench
   '("a" "b" "c" "d")
   (lambda (_ scratch-dirs)
     (mdired-do-command (lambda ()
                          "Write dummy file."
                          (interactive)
                          (write-region "hey they clittiak" nil "data.txt")))
     (mapc (lambda (sdir)
             (should (file-exists-p (expand-file-name "data.txt" sdir))))
           scratch-dirs))))


(ert-deftest test-mdired-copy ()
  "Test for `mdired-copy'."

  (mdired-testbench
   '("a" "b" "c" "d")
   (lambda (temp-dir scratch-dirs)
     (let* ((source (expand-file-name "copy-test.txt" temp-dir)))
       (write-region "hey they copy-tester" nil source)
       (revert-buffer)
       (dired-goto-file source)
       (mdired-copy t)
       (mapc (lambda (sdir)
             (should (file-exists-p (expand-file-name "copy-test.txt" sdir))))
           scratch-dirs)))))

(ert-deftest test-mdired-compile ()
  "Test for `mdired-compile'.

This test must be run interactively."

  (when (not noninteractive)
    (let* ((root (project-root (project-current t)))
           (data-dir (expand-file-name (file-name-concat root "tests" "data")))
           (data-file (expand-file-name "Makefile" data-dir)))

      (mdired-testbench
       '("a" "b")
       (lambda (temp-dir scratch-dirs)
         (let ((mfile (file-name-concat temp-dir "Makefile")))
           (copy-file data-file mfile t)
           (revert-buffer)
           (dired-goto-file mfile)
           (mdired-copy t)

           (mdired-compile)

           (should (buffer-live-p (get-buffer "*compilation - b*")))
           (should (buffer-live-p (get-buffer "*compilation - a*")))))))))

(ert-deftest test-mdired-byte-recompile ()
  "Test for `mdired-byte-recompile'."

  (let* ((root (project-root (project-current t)))
         (data-dir (expand-file-name (file-name-concat root "tests" "data")))
         (data-file (expand-file-name "foo.el" data-dir)))

    (mdired-testbench
     '("a" "b")
     (lambda (temp-dir scratch-dirs)
       (let ((efile (file-name-concat temp-dir "foo.el")))
         (copy-file data-file efile t)
         (revert-buffer)
         (dired-goto-file efile)
         (mdired-copy t)

         (mapc (lambda (sdir)
                 (let ((tfile (file-name-concat sdir "foo.el")))
                   (byte-compile-file tfile)
                   (set-file-times tfile (current-time))))
               scratch-dirs)

         (mdired-byte-recompile)

         (mapc (lambda (sdir)
             (should (file-exists-p (expand-file-name "foo.elc" sdir))))
           scratch-dirs))))))

(provide 'test-mdired)
;;; test-mdired.el ends here
