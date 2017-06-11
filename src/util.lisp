(in-package :cl-user)
(defpackage qi.util
  (:use :cl)
  (:export :asdf-system-path
           :download-strategy
           :is-gh-url?
           :is-git-url?
           :is-hg-url?
           :is-tar-url?
           :load-asdf-system
           :run-git-command
           :run-hg-command
           :sym->str
           :update-repository))
(in-package :qi.util)

;; Code:

(defun sym->str (sym)
  "Takes a symbol (:sym), and returns it as a string (\"sym\"), unless
<sym> is already a string. In both cases in downcases the string."
  (if (symbolp sym)
      (string-downcase (symbol-name sym))
      (string-downcase sym)))

(defun is-tar-url? (str)
  "Does <str> have a tarball extension."
  (or (ppcre:scan "^https?.*.tgz" str)
      (ppcre:scan "^https?.*tar.gz" str)))

(defun is-git-url? (str)
  "Is <str> a git:// or .git url."
  (or (ppcre:scan "^git://.*" str)
      (ppcre:scan ".*\.git$" str)))

(defun is-hg-url? (str)
  "Is <str> a hg:// or .hg url."
  (or (ppcre:scan "^hg://.*" str)
      (ppcre:scan ".*.hg" str)))

(defun is-gh-url? (str)
  "Is <str> a github url."
  (ppcre:scan "^https://github.*" str))

(defun download-strategy (url)
  (cond ((is-tar-url? url)
         :tarball)
        ((or (is-git-url? url)
             (is-gh-url? url))
         :git)
        ((is-hg-url? url)
         :hg)
        (t
         (error "Could not determine download strategy for ~S" url))))

(defun asdf-system-path (sys)
  "Find the pathname for a system, return NIL if it's not available."
  (handler-case
      (asdf:component-pathname (asdf:find-system sys))
    (error () () nil)))


(defun load-asdf-system (sys)
  (handler-bind ((warning #'muffle-warning))
    (ignore-errors
      (setf *load-verbose* nil)
      (setf *load-print* nil)
      (setf *compile-verbose* nil)
      (setf *compile-print* nil)
      (asdf:load-system sys :verbose nil))))

(defun run-git-command (command &optional directory)
  "Run the git COMMAND in the specified DIRECTORY."
  (uiop:run-program (concatenate 'string "git " command)
                    :directory (if directory (namestring directory))
                    :wait t
                    :output :lines))

(defun run-hg-command (command)
  "Run the Mercurial COMMAND."
  (uiop:run-program (concatenate 'string "hg " command) :wait t :output :lines))

(defun update-repository (&key name directory upstream branch revision)
  "Update the NAMEd repository, located in DIRECTORY, using UPSTREAM.
Unless BRANCH or REVISION is specified, update to the latest revision.
If DIRECTORY exists but isn't a repository, make it one."
  (ensure-directories-exist directory)

  ;; If `directory' is already a git repo, update it
  (if (probe-file (fad:merge-pathnames-as-directory directory ".git/"))
      (let (stash
            (upstream-ref (if branch
                              (concatenate 'string "origin/" branch)
                            ;; https://stackoverflow.com/a/15284176
                            (first (run-git-command "rev-parse --symbolic-full-name @{u}" directory))))
            (pre-revision (first (run-git-command "rev-parse HEAD" directory))))
        (format t "~%---> Upgrading ~A" name)
        (run-git-command "fetch origin" directory)

        (setq stash (first (run-git-command "status --untracked-files=all --porcelain" directory)))
        (if stash (run-git-command "stash" directory))

        (run-git-command (if revision
                             (concatenate 'string "reset --hard " revision)
                           (concatenate 'string "rebase " upstream-ref))
                         directory)

        (if stash (run-git-command "stash pop" directory))

        (let ((post-revision (first (run-git-command "rev-parse HEAD" directory))))
          (if (string= pre-revision post-revision)
              (format t "~%~3t✓ ~A is already up to date.~%" name)
            (format t "~%~3t✓ Updated ~A to ~A~%" name post-revision))))

    ;; If `directory' is not a git repo, make it one
    (progn
      ;; Adapted from
      ;; https://github.com/Homebrew/brew/blob/bff8e84/Library/Homebrew/cmd/update.sh#L37-L50;
      ;; copyright Homebrew contributors, released under the BSD 2-Clause License
      (run-git-command "init" directory)
      (run-git-command
       (concatenate 'string "config remote.origin.url " upstream) directory)
      (run-git-command "config remote.origin.fetch \"+refs/heads/*:refs/remotes/origin/*\"" directory)
      (run-git-command "fetch origin" directory)

      (run-git-command (concatenate
                        'string
                        "reset --hard "
                        (if (or branch revision)
                            (or revision (concatenate 'string "origin/" branch))
                          "origin/master"))
                       directory)

      ;; setting `upstream-ref' above requires this
      (run-git-command "branch --set-upstream-to=origin/master master" directory)

      (let ((post-revision (first (run-git-command "rev-parse HEAD" directory))))
        (format t "~%~3t✓ Updated ~A to ~A~%" name post-revision)))))
