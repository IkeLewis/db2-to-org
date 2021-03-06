;;; copy-table-sql.el --- Copy tables as... -*- lexical-binding: t -*-

;; Copyright (C) 2018 Isaac Lewis

;; Author: Isaac Lewis <isaac.b.lewis@gmail.com>
;; Version: 1.0.0
;; Keywords: convenience, sql

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Copy text tables produced by SQL queries as various types of
;; formatted text, e.g. markdown, org, etc.  Currently, only query
;; results for db2 tables are supported and may be converted to ORG
;; tables or (GitHub flavored) markdown tables.

;;; Utility Functions

(defun copy-table-next-line-same-col ()
  (interactive)
  (let ((goal-column (current-column)))
    (next-line)))

(defun copy-table-previous-line-same-col ()
  (interactive)
  (let ((goal-column (current-column)))
    (previous-line)))

;;; API

(defun copy-table-sql-db2-as-org ()
  "Copy a db2 SQL table as an org table.  Example:

    First     Last        Batting_Avg
    --------- ----------- -----------
     Nicholas Castellanos        .305
       Miguel     Cabrera        .299
	 John       Hicks        .278

   Select the table.  Type M-x copy-table-sql-db2-as-org and then
   C-y to paste the org table:

    | First    | Last        | Batting Avg |
    |----------+-------------+-------------|
    | Nicholas | Castellanos |        .305 |
    | Miguel   | Cabrera     |        .299 |
    | John     | Hicks       |        .278 |

    "
  (interactive)
  (let ((cb (current-buffer)))
    (message "Copying table from %s" cb)
    (with-current-buffer cb
      (kill-ring-save (region-beginning) (region-end))
      (with-temp-buffer
	(org-mode)
	(yank)
	(whitespace-cleanup)
	(delete-trailing-whitespace)
	;; delete-trailing-whitespace will allow up to 1 newline
	;; character at the end of the buffer (because that's what we
	;; want most of the time), but here we want to remove that
	;; character, as well.
	(goto-char (point-max))
	(if (equal (line-beginning-position)
		   (line-end-position))
	    (delete-char -1))

	;; Use the second line of space separated dash groupings to
	;; format the headings (which may contain spaces).
	(goto-line 1)
	(insert "|")
	(goto-line 2)
	(insert "|")
	(forward-sexp)
	(while (not (equal (point)
			   (line-end-position)))
	  (delete-char 1)
	  (insert "|")
	  (copy-table-previous-line-same-col)
	  (delete-char -1)
	  (insert "|")
	  (copy-table-next-line-same-col)
	  (forward-sexp))
	(goto-line 1)
	(move-end-of-line 1)
	(insert "|")
	(goto-line 2)
	(move-end-of-line 1)
	(insert "|")

	(goto-line 3)
	(while (not (equal (point) (buffer-end 1)))
	  (insert "|")
	  (if (equal (point) (line-end-position))
	      (forward-line)
	    (forward-sexp)))
	(insert "|")
	;; Make sure line 2 starts with '|-'
	(goto-line 2)
	(forward-char 1)
	(delete-char 1)
	(insert "-")
	;; Call org-cycle to format the table
	(goto-char 2)
	(org-cycle)
	;; Kill the table
	(kill-region 1 (point-max))))))

(defun copy-table-sql-db2-as-github-markdown ()
  "Copy a db2 SQL table as a GitHub flavored Markdown table.

    Example:

    First     Last        Batting_Avg
    --------- ----------- -----------
     Nicholas Castellanos        .305
       Miguel     Cabrera        .299
	 John       Hicks        .278

   Select the table.  Type M-x copy-table-sql-db2-as-github-markdown and then
   C-y to paste the org table:

     First    | Last        | Batting Avg
    ----------|-------------|-------------
     Nicholas | Castellanos |        .305
     Miguel   | Cabrera     |        .299
     John     | Hicks       |        .278

    "
  (interactive)
  (with-current-buffer (current-buffer)
    (copy-table-sql-db2-as-org)
    (with-temp-buffer
      (yank)
      (goto-char 1)
      (while (not (equal (point) (buffer-end 1)))
	(delete-char 1)
	(end-of-line)
	(delete-char -1)
	(forward-line))
      (goto-line 2)
      ;; Run replace-string quietly
      (let ((inhibit-message t))
	(replace-string "+"
			"|"
			nil
			(line-beginning-position)
			(line-end-position)))
      (kill-region 1 (point-max)))))

(provide 'copy-table-sql)
;; copy-table-sql.el ends here
