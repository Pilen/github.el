
(setq github-cache-directory "~/.emacs.d/github-cache/")
(setq github-user-name "Pilen")
(setq github-user-password "")
(setq github-issues-sorting "updated")

(setq github-curl-max-time 10)

(shell-command "echo hej")
(get-buffer-create "*github-api*")
(generate-new-buffer "*github-api*")
(set-buffer (get-buffer-create "*github-api*"))
(with-temp-buffer)

(defun github-horizontal-line (start)
  (concat start (make-string (- 79 (length start)) ?_) "\n"))

(setq github-horizontal-line (github-horizontal-line ""))

(defun github-filename (query)
  (let ((filename (replace-regexp-in-string "https://api.github.com" "" query)))
    (concat (file-name-as-directory github-cache-directory)
            (replace-regexp-in-string "/" "|" (if (string-prefix-p "/" filename)
                                                  (substring filename 1)
                                                filename)))))

(defun github-absolute-query (query)
  (save-excursion
    (set-buffer (get-buffer-create "*github-api*"))
    (delete-region (point-min) (point-max))
    (if (zerop (with-temp-buffer
                 (insert "user = " github-user-name ":" github-user-password)
                 (call-process-region (point-min) (point-max) "curl" t (get-buffer-create "*github-api*") nil
                                      "--config" "-"
                                      "--silent"
                                      "--max-time" (int-to-string github-curl-max-time)
                                      query)))
        (progn
          (write-region (point-min) (point-max) (github-filename query))
          (goto-char (point-min))
          (json-read))
      (message "Connection to github.com went wrong")
      (github-cached-query query))))
(github-absolute-query "https://api.github.com/users/Pilen/repos")


(defun github-query (&rest query)
  (github-absolute-query
   (concat "https://api.github.com"
           (when (not (string-prefix-p "/" (car query))) "/")
           (apply 'concat query))))


(defun github-cached-query (&rest query)
  (with-temp-buffer
    (let ((filename (github-filename (apply 'concat query ))))
      (if (file-exists-p filename)
          (progn
            (insert-file-contents filename)
            (json-read))
        (message "No cached version exists")
        nil))))

(defun github-update-repo (full_name)
)
(let ((full_name "Pilen/github.el"))
  (let* ((filename (github-filename (concat "updated_at/" full_name)))
         (latest_update (if (not (file-exists-p filename))
                            nil
                          (with-temp-buffer
                            (insert-file-contents filename)
                            (buffer-string))))
         (since (if (null latest_update) "" (concat ";since=" latest_update)))
         (updated_at (cdr (assoc 'updated_at (github-query "repos/" full_name))))
         (issues (github-query "repos/" full_name "/issues" "?sort=" github-issues-sorting since)))

    (github-query "repos/" full_name "/branches")

    (mapcar (lambda (issue)
              (let ((number (cdr (assoc 'number issue))))
                (github-query "repos/" full_name "/issues/" (int-to-string number) "/comments")
                (github-query "repos/" full_name "/issues/" (int-to-string number) "/events")))
            issues)

    (with-temp-file (github-filename (concat "updated_at/" full_name))
      (insert updated_at))
  ))

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



(let ;((full_name "RusKursusGruppen/GRIS"))
    ((full_name "Pilen/github.el"))
  (set-buffer (get-buffer-create (concat "*github: " full_name "/issues*")))
  (delete-region (point-min) (point-max))
  (mapcar (lambda (issue)
            (let* ((number (cdr (assoc 'number issue)))
                   (title (cdr (assoc 'title issue)))
                   (state (cdr (assoc 'state issue)))
                   (assignee (cdr (assoc 'assignee issue)))
                   (comments (cdr (assoc 'comments issue)))
                   (created_at (cdr (assoc 'created_at issue)))
                   (updated_at (cdr (assoc 'updated_at issue)))
                   (closed_at (cdr (assoc 'closed_at issue)))
                   (closed_by (cdr (assoc 'closed_by issue)))
                   (body (cdr (assoc 'body issue)))
                   (user (cdr (assoc 'user issue)))
                   (labels (cdr (assoc 'labels issue)))
                   (url (cdr (assoc 'url issue)))
                   (milestone (cdr (assoc 'milestone issue)))

                   )

              (insert
               "#" (int-to-string number) ": " title "\n"
               (if (zerop (length labels)) "(unlabeled)"
                 (mapconcat (lambda (label) (concat "[" (cdr (assoc 'name label)) "]")) labels ", "))
               (if (null milestone) "" (concat " ~ milestone: " (cdr (assoc 'title milestone)))) "" "\n"
               "Created by " (cdr (assoc 'login user)) " " created_at
               (if (null assignee) "" (concat " assigned to: " (cdr (assoc 'login assignee)))) ""
               (if (zerop comments) "" (concat ", " (int-to-string comments) " comment" (when (> comments 1) "s"))) "\n"
               "\n"
               )
              ))
          (github-query "repos/" full_name "/issues" "?sort=" github-issues-sorting ";state=open")
        ))

(let ;((full_name "Pilen/github.el")
    ((full_name "RusKursusGruppen/GRIS")
      (number 37))
  (set-buffer (get-buffer-create (concat "*github: " full_name "/issue/" (int-to-string number) "*")))
  (delete-region (point-min) (point-max))
  (let* ((issue (github-query "repos/" full_name "/issues/" (int-to-string number)))
                   (title (cdr (assoc 'title issue)))
                   (state (cdr (assoc 'state issue)))
                   (assignee (cdr (assoc 'assignee issue)))
                   (comments (cdr (assoc 'comments issue)))
                   (created_at (cdr (assoc 'created_at issue)))
                   (updated_at (cdr (assoc 'updated_at issue)))
                   (closed_at (cdr (assoc 'closed_at issue)))
                   (closed_by (cdr (assoc 'closed_by issue)))
                   (body (cdr (assoc 'body issue)))
                   (user (cdr (assoc 'user issue)))
                   (labels (cdr (assoc 'labels issue)))
                   (url (cdr (assoc 'url issue)))
                   (milestone (cdr (assoc 'milestone issue)))
                   )

    (insert
     "#" (int-to-string number) ": " title "\n"
     (if (zerop (length labels)) "(unlabeled)"
       (mapconcat (lambda (label) (concat "[" (cdr (assoc 'name label)) "]")) labels ", "))
     "\n"
     (if (null milestone) "" (concat "milestone: " (cdr (assoc 'title milestone)))) "" "\n"
     "Created by " (cdr (assoc 'login user)) " " created_at
     (if (null assignee) "" (concat " assigned to: " (cdr (assoc 'login assignee)))) "\n"
     (if (zerop comments) "" (concat (int-to-string comments) " comment" (when (> comments 1) "s"))) "\n"
     "\n\n"
     (github-horizontal-line "Description:" )
     body "\n"
     github-horizontal-line
     "\n"
     )

    (mapcar
     (lambda (item)
       (if (null (assoc 'body item))
           (progn ;event
             (let ((actor (cdr (assoc 'actor item)))
                   (event (cdr (assoc 'event item)))
                   (commit_id (cdr (assoc 'commit_id item)))
                   (created_at (cdr (assoc 'created_at item))))
               (insert
                (cdr (assoc 'login actor)) " " event " this at " created_at "\n"
                (if (not (null commit_id)) (concat "in commit #" commit_id "\n") "")
                "\n\n"
                )
             ))
         (progn ;comment
           (let ((user (cdr (assoc 'user item)))
                 (created_at (cdr (assoc 'created_at item)))
                 (updated_at (cdr (assoc 'updated_at item)))
                 (body (cdr (assoc 'body item))))
             (insert
              (github-horizontal-line (concat (cdr (assoc 'login user)) ":" ))
              created_at " " updated_at "\n"
              body
              "\n"
              github-horizontal-line
              "\n\n"
             )))))
     (sort
      (nconc
       (mapcar 'identity (github-query "repos/RusKursusGruppen/GRIS/issues/38/comments"))
       (mapcar 'identity (github-query "repos/RusKursusGruppen/GRIS/issues/38/events")))
      (lambda (x y)
        (let ((xt (cdr (assoc 'created_at x)))
              (yt (cdr (assoc 'created_at y))))
          (string-lessp xt yt)))))
    ))



(github-query "repos/" "RusKursusGruppen/GRIS" "/issues" "?sort=" github-issues-sorting ";state=open;since=2014-02-16T16:35:17Z")


https://api.github.com/repos/RusKursusGruppen/gris/issues

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
