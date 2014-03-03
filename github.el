
(setq github-cache-directory "~/.emacs.d/github-cache/")
(setq github-user-name "Pilen")
(setq github-user-password "")

(shell-command "echo hej")
(get-buffer-create "*github-api*")
(generate-new-buffer "*github-api*")
(set-buffer (get-buffer-create "*github-api*"))
(with-temp-buffer)

(defun github-query (query)
  (save-excursion
    (set-buffer (get-buffer-create "*github-api*"))
    (delete-region (point-min) (point-max))
    (with-temp-buffer
      (insert "abekaten")
      (call-process-region (point-min) (point-max) "curl" t (get-buffer-create "*github-api*") nil
                           "-s" (concat "https://api.github.com" query)))
    (goto-char (point-min))
    (json-read)))

(defun github-repo-names ()
  (mapcar
   (lambda (repo)
     (cdr (assoc 'name repo)))
   (github-query (concat "/users/" github-user-name "/repos"))))

(dolist (name (github-repo-names)) (message name))


(defun github-list-repos ()
  (save-excursion
    (set-buffer (get-buffer-create "*github*"))
    (delete-region (point-min) (point-max))
    (mapcar
     (lambda (repo)
       (let ((name (cdr (assoc 'name repo)))
             (pushed_at (cdr (assoc 'pushed_at repo)))
             (open_issues (cdr (assoc 'open_issues repo))))
         (insert (format "%-20s" name) " "
                 ;;name "\n"
                 "last push: " pushed_at "    "

                 (if (zerop open_issues)
                     ""
                   (concat (format "%6s " open_issues)
                           (if (= 1 open_issues)
                               "issue"
                             "issues")))
                 "\n\n")))
     (github-query (concat "/users/" github-user-name "/repos?sort=updated")))))
(github-list-repos)

(start-process)


oversigt:
name
open_issues
pushed_at
