
(setq github-cache-directory "~/.emacs.d/github-cache/")
(setq github-user-name "Pilen")
(setq github-user-password "")

(setq github-curl-max-time 10)

(shell-command "echo hej")
(get-buffer-create "*github-api*")
(generate-new-buffer "*github-api*")
(set-buffer (get-buffer-create "*github-api*"))
(with-temp-buffer)


(defun github-absolute-query (&rest query)
  (save-excursion
    (set-buffer (get-buffer-create "*github-api*"))
    (delete-region (point-min) (point-max))
    (with-temp-buffer
      (insert "user = " github-user-name ":" github-user-password)
      (call-process-region (point-min) (point-max) "curl" t (get-buffer-create "*github-api*") nil
                           "--config" "-"
                           "--silent"
                           "--max-time" (int-to-string github-curl-max-time)
                           (apply 'concat query)))
    (goto-char (point-min))
    (json-read)))

(defun github-query (&rest query)
  (apply 'github-absolute-query "https://api.github.com"
         (when (not (string-prefix-p "/" (car query)))
           "/")
             query))

(defun github-repo-names ()
  (mapcar
   (lambda (repo)
     (cdr (assoc 'name repo)))
   (github-query "/users/" github-user-name "/repos")))

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
                        ""
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
            (github-query "/users/" github-user-name "/repos?sort=updated"))
      ;; Repos of all the users organizations
      (mapcar (lambda (org)
                (let ((name (cdr (assoc 'login org)))
                      (url (cdr (assoc 'repos_url org))))
                  (cons name (github-absolute-query url))))
              (github-query "/users/" github-user-name "/orgs"))))))

(progn
 (defun github-repo (repo-full_name)
   (let* ((repo (github-query "repos/" repo-full_name))
          (name (cdr (assoc 'name repo)))
          (full_name (cdr (assoc 'full_name repo)))
          (private (cdr (assoc 'private repo)))
          (description (cdr (assoc 'description repo)))
          (created_at (cdr (assoc 'created_at repo)))
          (updated_at (cdr (assoc 'updated_at repo)))
          (pushed_at (cdr (assoc 'pushed_at repo)))
          (git_url (cdr (assoc 'git_url repo)))
          (ssh_url (cdr (assoc 'ssh_url repo)))
          (language (cdr (assoc 'language repo)))
          (forks (cdr (assoc 'forks repo)))
          (fork (cdr (assoc 'fork repo)))
          (open_issues_count (cdr (assoc 'open_issues_count repo)))
          (open_issues (cdr (assoc 'open_issues repo)))
          (subscribers_count (cdr (assoc 'subscribers_count repo)))
          (languages_url (cdr (assoc 'languages_url repo)))

          (visibility (if (eq private 'true)
                          "private"
                        "public"))
          (origin (if (eq fork 'true)
                      "fork"
                    ""))

          (languages (github-absolute-query languages_url))
          (byte_sum (apply '+ (mapcar 'cdr languages)))
          (spaces (reduce (lambda (longest lang)
                            (max longest (length (symbol-name (car lang)))))
                          (cons 0 languages)
                          :start 0))
          (langs (apply 'concat (mapcar (lambda (lang)
                                          (concat (symbol-name (car lang)) ": "
                                                  (make-string (- spaces (length (symbol-name (car lang)))) ? )
                                                  (int-to-string (round (* (/ (cdr lang) byte_sum 1.0) 100)))
                                                  "%\n"))
                                        (sort languages (lambda (x y) (>= (cdr x) (cdr y)))))))

          (branches (github-query "repos/" "RusKursusGruppen/gris" "/branches"))
          (branch_names (mapconcat (lambda (branch) (cdr (assoc 'name branch)))
                        branches ", "))
          )

     (set-buffer (get-buffer-create (concat "*github: " full_name "*")))
     (delete-region (point-min) (point-max))
     (insert full_name "\n"
             description "\n\n"
             git_url "\n"
             ssh_url "\n"
             "created: " created_at "    pushed at: " pushed_at "\n"
             visibility " " origin "    forks: "(int-to-string forks) "    subscribers: " (int-to-string subscribers_count) "\n"
             "Branches: " branch_names "\n"

             "\n"
             langs
             "\n"

             "\n"

             "Open issues: " (int-to-string open_issues_count) "\n"

             )))

 (github-repo "RusKursusGruppen/GRIS"))



(github-absolute-query "https://api.github.com/orgs/RusKursusGruppen/repos")

(start-process)


oversigt:
name
open_issues
pushed_at

repo:
name
full_name
private
description
created_at
updated_at / pushed_at
git_url
ssh_url
language
forks
open_issues_count
open_issues
subscribers_count




(github-list-repos)
