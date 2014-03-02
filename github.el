
(setq github-cache-directory "~/.emacs.d/github-cache/")
(setq github-user-name "Pilen")
(setq github-user-password "")

(shell-command "echo hej")
(get-buffer-create "*github-api*")
(generate-new-buffer "*github-api*")
(with-temp-buffer

(defun github-query (query)
  (save-excursion
    (set-buffer (get-buffer-create "*github-api*"))
    (delete-region (point-min) (point-max))
    (if (zerop
         (with-temp-buffer
           (insert "abekaten")
           (call-process-region (point-min) (point-max) "curl" t (get-buffer-create "*github-api*") nil
                                "-s" (concat "https://api.github.com" query))))
        (save-buffer)
    (goto-char (point-min))
    (json-read)))



(defun github-repo-names ()
  (mapcar
   (lambda (repo)
     (cdr (assoc 'name repo)))
   (github-query (concat "/users/" github-user-name "/repos"))))

(dolist (name (github-repo-names)) (message name))



(start-process)
