;;; tern-django.el --- Create tern projects for django applications.

;; Copyright (C) 2014 by Malyshev Artem

;; Author: Malyshev Artem <proofit404@gmail.com>
;; URL: https://github.com/proofit404/tern-django
;; Version: 0.0.1
;; Package-Requires: ((emacs "24") (tern "0.0.1") (f "0.17.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Installation:

;; You can install this package from Melpa:
;;
;;     M-x package-install RET tern-django RET

;;; Commentary:

;; Obviously all JavaScript code of application stored in application
;; static folder.  So we can write standard .tern-project file into
;; each application root.  We can add custom JavaScript from templates
;; script html tags.  We can extend default "libs", "loadEagerly" and
;; "plugins" settings.  Also if template use external library from
;; internet we can download it to temporary folder and make it
;; accessible for tern.
;;
;; `tern-django' command do following:
;;
;; * Check if DJANGO_SETTINGS_MODULE was specified
;; * Run python script in the background
;; * Parse each template file in each application folder
;; * Find specified static files in the script html tags
;; * Save processed result in sqlite3 database
;; * Write .tern-project file for each application if necessary

;;; Usage:

;; Drop following line into your .emacs file:
;;
;;     (add-hook 'after-save-hook 'tern-django)
;;
;; Setup your project variables:
;;
;;     M-x setenv RET DJANGO_SETTINGS_MODULE RET project.settings
;;     M-x setenv RET PYTHONPATH RET /home/user/path/to/project/
;;
;; When you save any file all tern projects will be updated to the
;; most resent changes in your project.  Only one process running at
;; the time.  So first run for newly specified project will take some
;; time.  But next run will be much faster because `tern-django' saves
;; processed result for future reuse.  You can safely ignore both tern
;; projects and tern ports files in you VCS.

;;; Code:

(require 'python)
(require 'f)

(defvar tern-django-directory (file-name-directory load-file-name)
  "Directory contain `tern-django' package.")

(defvar tern-django-script "tern_django.py"
  "Script path to read django settings.")

(defvar tern-django-process nil
  "Currently running `tern-django' process.")

(defvar tern-django-buffer "*tern-django*"
  "Buffer for `tern-django' process output.")

(defun tern-django-p ()
  "Return t if script run inside django environment."
  (stringp (getenv "DJANGO_SETTINGS_MODULE")))

(defun tern-django-python ()
  "Detect python executable."
  (let ((python (if (eq system-type 'windows-nt) "pythonw" "python"))
        (bin (if (eq system-type 'windows-nt) "Scripts" "bin")))
    (--if-let python-shell-virtualenv-path
        (f-join it bin python)
      python)))

(defun tern-django-running-p ()
  "Check if `tern-django' process is running."
  (and tern-django-process
       (process-live-p tern-django-process)))

(defun tern-django-process-sentinel (process event)
  "Check `tern-django' exit code.
Show PROCESS output buffer if any error has occurred.
EVENT argument is ignored."
  (unless (zerop (process-exit-status process))
    (pop-to-buffer tern-django-buffer)))

(defun tern-django-bootstrap ()
  "Start `tern-django' python script."
  (when (tern-django-p)
    (let ((default-directory tern-django-directory))
      (with-current-buffer
          (get-buffer-create tern-django-buffer)
        (erase-buffer))
      (setq tern-django-process
            (start-process "tern-django"
                           tern-django-buffer
                           (tern-django-python)
                           tern-django-script))
      (set-process-sentinel tern-django-process
                            'tern-django-process-sentinel))))

(defun tern-django-terminate ()
  "Terminate `tern-django' python script."
  (when (tern-django-running-p)
    (set-process-query-on-exit-flag tern-django-process nil)
    (kill-process tern-django-process))
  (when (get-buffer tern-django-buffer)
    (kill-buffer tern-django-buffer))
  (setq tern-django-process nil))

;;;###autoload
(defun tern-django ()
  "Create tern projects for django applications."
  (interactive)
  (unless (tern-django-running-p)
    (tern-django-bootstrap)))

(provide 'tern-django)

;;; tern-django.el ends here
