
(setq github-cache-directory "~/.emacs.d/github-cache/")
(setq github-user-name "Pilen")
(setq github-user-password "")

(shell-command "echo hej")
(get-buffer-create "*github-api*")
(generate-new-buffer "*github-api*")
(set-buffer (get-buffer-create "*github-api*"))
(with-temp-buffer)


(defun github-absolute-query (query)
  (save-excursion
    (set-buffer (get-buffer-create "*github-api*"))
    (delete-region (point-min) (point-max))
    (with-temp-buffer
      (insert "abekaten")
      (call-process-region (point-min) (point-max) "curl" t (get-buffer-create "*github-api*") nil
                           "-s" query))
    (goto-char (point-min))
    (json-read)))

(defun github-query (query)
  (github-absolute-query (concat "https://api.github.com" query)))

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
     (lambda (group)
       (insert "\n" (car group) ":\n")
       (mapcar
        (lambda (repo)
          (let ((name (cdr (assoc 'name repo)))
                (pushed_at (cdr (assoc 'pushed_at repo)))
                (open_issues (cdr (assoc 'open_issues repo))))
            (insert (format "  %-20s" name) " "
                    ;;name "\n"
                    "last push: " pushed_at "    "

                    (if (zerop open_issues)
                  1      ""
                      (concat (format "%6s " open_issues)
                              (if (= 1 open_issues)
                                  "issue"
                                "issues")))
                    "\n\n")))
        (cdr group)))
     ;; create list of (Group . [repos])
     (cons
      ;; Users repos
      (cons github-user-name
            (github-query (concat "/users/" github-user-name "/repos?sort=updated")))
      ;; Repos of all the users organizations
      (mapcar (lambda (org)
                (let ((name (cdr (assoc 'login org)))
                      (url (cdr (assoc 'repos_url org))))
                  (cons name (github-absolute-query url))))
              (github-query (concat "/users/" github-user-name "/orgs")))))))

(github-list-repos)
(github-query "https://api.github.com/orgs/RusKursusGruppen/repos")

(start-process)


oversigt:
name
open_issues
pushed_at
