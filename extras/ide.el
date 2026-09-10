;;; -*- lexical-binding: t -*-
;;;
;;; Emacs Bedrock — IDE layer
;;;
;;; Doom/Spacemacs-style enhancements: SPC leader with which-key panel,
;;; projects, treemacs file tree, ghostel (libghostty) terminal, LSP.
;;;
;;; Requires extras/base.el, extras/dev.el, and extras/vim-like.el to be
;;; loaded first (this file is loaded last from init.el).

;;; Contents:
;;;
;;;  - Environment (exec-path for GUI launches)
;;;  - Evil adjustments
;;;  - Which-key command panel
;;;  - SPC leader (general.el)
;;;  - Treemacs file tree
;;;  - Ghostel terminal
;;;  - Eglot LSP for Go, Rust, TypeScript
;;;  - Font

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Environment
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Emacs.app launched from the Dock gets a minimal launchd PATH; make sure
;; Homebrew, cargo, and local bins are visible to eglot/treemacs/etc.
(defun bedrock-ide/add-exec-path (dir)
  "Add DIR to `exec-path' and the PATH environment variable if it exists."
  (when (and (file-directory-p dir)
             (not (member dir exec-path)))
    (add-to-list 'exec-path dir)
    (setenv "PATH" (concat dir path-separator (getenv "PATH")))))

(mapc #'bedrock-ide/add-exec-path
      (list "/opt/homebrew/bin"
            "/usr/local/bin"
            (expand-file-name "~/.cargo/bin")
            (expand-file-name "~/.local/bin")
            ;; fnm-managed node globals (codex-acp, auggie) + opencode
            (expand-file-name "~/.local/share/fnm/aliases/default/bin")
            (expand-file-name "~/.opencode/bin")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Evil adjustments
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; CUA's C-c/C-v region behavior fights evil's visual state; evil users
;; paste with `p' and yank with `y' instead.
(cua-mode -1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Which-key command panel
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; base.el swaps which-key for embark-auto-prefix-help; restore which-key so
;; the leader key gets the familiar Doom-style popup panel of shortcuts.
(when (fboundp 'embark-auto-prefix-help-mode)
  (embark-auto-prefix-help-mode -1))

(use-package which-key
  :custom
  (which-key-idle-delay 0.3)
  (which-key-idle-secondary-delay 0.05)
  (which-key-show-early-on-C-h t)
  ;; Doom-style bottom panel: force a multi-row grid with breathing room
  ;; instead of one long line
  (which-key-popup-type 'side-window)
  (which-key-side-window-location 'bottom)
  (which-key-side-window-max-height 0.35)
  (which-key-min-display-lines 6)
  (which-key-max-display-columns 4)
  (which-key-add-column-padding 2)
  (which-key-max-description-length 32)
  :config
  (which-key-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   SPC leader
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package general
  :config
  (general-create-definer bedrock-ide/leader
    :states '(normal visual motion)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC")

  (bedrock-ide/leader
   "SPC" 'execute-extended-command
   ":"   'execute-extended-command

   "p" '(:ignore t :which-key "project")
   "p p" 'project-switch-project
   "p f" 'project-find-file
   "p b" 'consult-project-buffer
   "p d" 'project-find-dir
   "p g" 'project-find-regexp
   "p c" 'project-compile
   "p k" 'project-kill-buffers
   "p t" 'ghostel-project

   "a" '(:ignore t :which-key "agent")
   "a a" 'agent-shell
   "a c" 'agent-shell-openai-start-codex
   "a o" 'agent-shell-opencode-start-agent
   "a u" 'agent-shell-auggie-start-agent
   "a m" 'agent-shell-prompt-compose

   "f" '(:ignore t :which-key "file")
   "f f" 'find-file
   "f r" 'consult-recent-file
   "f s" 'save-buffer
   "f d" 'project-dired
   "f e" 'bedrock-ide/find-config

   "b" '(:ignore t :which-key "buffer")
   "b b" 'consult-buffer
   "b i" 'ibuffer
   "b k" 'kill-current-buffer
   "b s" 'save-buffer

   "w" '(:ignore t :which-key "window")
   "w v" 'split-window-right
   "w s" 'split-window-below
   "w d" 'delete-window
   "w o" 'delete-other-windows
   "w h" 'windmove-left
   "w j" 'windmove-down
   "w k" 'windmove-up
   "w l" 'windmove-right
   "w =" 'balance-window
   "w <" 'shrink-window-horizontally
   "w >" 'enlarge-window-horizontally
   "w ^" 'enlarge-window
   "w -" 'shrink-window

   "g" '(:ignore t :which-key "git")
   "g s" 'magit-status
   "g d" 'magit-diff-unstaged
   "g b" 'magit-blame-addition
   "g l" 'magit-log-buffer-file

   "s" '(:ignore t :which-key "search")
   "s s" 'consult-line
   "s p" 'consult-ripgrep
   "s o" 'consult-outline
   "/"   'consult-ripgrep

   "o" '(:ignore t :which-key "open")
   "o p" 'treemacs
   "o t" 'ghostel
   "o n" 'ghostel-next
   "o e" 'eshell
   "o b" 'xwidget-webkit-browse-url
   "o B" 'bedrock-ide/webkit-new-session

   "h" '(:ignore t :which-key "help")
   "h f" 'describe-function
   "h v" 'describe-variable
   "h k" 'describe-key
   "h h" 'help-for-help

   "TAB" '(:ignore t :which-key "tabs")
   "TAB TAB" 'tab-switch
   "TAB n" 'tab-new
   "TAB d" 'tab-close
   "TAB r" 'tab-rename
   "TAB ]" 'tab-next
   "TAB [" 'tab-previous
   "TAB p" 'bedrock-ide/project-tab

   "q" '(:ignore t :which-key "quit")
   "q q" 'save-buffers-kill-emacs
   "q f" 'delete-frame))

(defun bedrock-ide/webkit-new-session (url)
  "Open a NEW xwidget we session for URL, instead of navigating the last one."
  (interactive "sURL: ")
  (xwidget-webkit-browse-url url 'new-session))

(defun bedrock-ide/find-config ()
  "Open the Bedrock init file."
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Agent shells (ACP): Codex, opencode, Auggie
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; agents: codex-acp + auggie (npm via fnm), opencode (~/.opencode/bin) are on
;; exec-path (added in Environment).  Login flows run in-buffer on first use.
(use-package agent-shell
  :commands (agent-shell
             agent-shell-prompt-compose
             agent-shell-openai-start-codex
             agent-shell-opencode-start-agent
             agent-shell-auggie-start-agent)
  :config
  ;; agent-shell buffers are chat-like, not modal targets
  (dolist (mode '(agent-shell-diff-mode
                  agent-shell-viewport-edit-mode
                  agent-shell-viewport-view-mode))
    (evil-set-initial-state mode 'emacs)))

;; `agent-shell-openai-start-codex' is missing from the package's autoloads
(autoload 'agent-shell-openai-start-codex "agent-shell-openai" nil t)

(use-package treemacs
  :custom
  (treemacs-is-never-other-window t)
  :config
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-fringe-indicator-mode 'always))

(use-package treemacs-evil
  :after treemacs)

(use-package nerd-icons)

(use-package treemacs-nerd-icons
  :after (treemacs nerd-icons)
  :config
  (treemacs-nerd-icons-config))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Startup project picker + tree on project switch
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Startup project list was removed in favor of desktop.el session restore.
;; Open a project manually with SPC p p.

(defun bedrock-ide/open-project-tree (&rest _)
  "Display the current project in treemacs."
  (when (fboundp 'treemacs-add-and-display-current-project)
    (treemacs-add-and-display-current-project)))

;; Whenever you switch projects (SPC p p), open its file tree
(advice-add 'project-switch-project :after #'bedrock-ide/open-project-tree)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Tabs (workspaces for grouping buffers)
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun bedrock-ide/project-tab ()
  "Switch to a tab dedicated to the current project, creating it if needed.
Buffers and window layout stay grouped per tab, so each project gets
its own workspace."
  (interactive)
  (if-let* ((project (project-current))
            (name (file-name-nondirectory
                   (directory-file-name (project-root project)))))
      (if (member name (mapcar (lambda (tab) (cdr (assq 'name tab)))
                               (funcall tab-bar-tabs-function)))
          (tab-bar-select-tab-by-name name)
        (tab-new)
        (tab-bar-rename-tab name))
    (message "Not in a project; use SPC TAB n for a blank tab")))

;; The built binary's dumped loaddefs lacks this autoload; register it
;; explicitly so SPC o b works.
(autoload 'xwidget-webkit-browse-url "xwidget" nil t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Ghostel terminal (libghostty)
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package ghostel
  :custom
  (ghostel-module-auto-install t)       ; auto-download prebuilt module, don't ask
  :commands (ghostel ghostel-project ghostel-project-list-buffers))

(use-package evil-ghostel
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode))

(with-eval-after-load 'project
  (add-to-list 'project-switch-commands '(ghostel-project "Ghostel") t)
  (add-to-list 'project-switch-commands
               '(ghostel-project-list-buffers "Ghostel buffers") t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Eglot LSP
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; TSLS needs either a workspace node_modules/typescript or an explicit
;; tsserver.path.  Homebrew's typescript formula is TS 7 (Go), which ships
;; no tsserver, so ~/node_modules/typescript is symlinked to the global
;; typescript@5 install (via fnm's stable default alias); TSLS's module
;; search climbs parent directories and picks it up for every project
;; under home.  Projects that install their own typescript take precedence.
;; Official tree-sitter grammar sources; run M-x treesit-install-language-grammar
;; (or treesit-install-all-available-grammars) to install/update.
(use-package treesit
  :ensure nil
  :custom
  (treesit-language-source-alist
   '((rust . ("https://github.com/tree-sitter/tree-sitter-rust"))
     (go . ("https://github.com/tree-sitter/tree-sitter-go"))
     (gomod . ("https://github.com/camdencheek/tree-sitter-go-mod"))
     (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript"))
     (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" nil "typescript/src"))
     (tsx . ("https://github.com/tree-sitter/tree-sitter-typescript" nil "tsx/src"))
     (json . ("https://github.com/tree-sitter/tree-sitter-json"))
     (yaml . ("https://github.com/tree-sitter-grammars/tree-sitter-yaml")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Session restore (desktop.el)
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Restores frames, windows, buffers and point across restarts.  Saving
;; happens on exit and periodically once an Emacs is up and running.
(use-package desktop
  :ensure nil
  :custom
  (desktop-path (list user-emacs-directory))
  (desktop-save 'ask-if-new)
  (desktop-auto-save-timeout 180)
  (desktop-restore-frames t)
  (desktop-restore-in-current-display t)
  (desktop-load-locked-desktop t)
  :config
  (desktop-save-mode 1))

;; Ghostel terminal buffers: restore directory + identity (not scrollback)
(use-package ghostel-desktop
  :ensure nil                           ; ships inside the ghostel package
  :after ghostel
  :demand t)

;; Webkit buffers: save the URL and re-open it on restore
(defun bedrock-ide--webkit-desktop-save (&rest _args)
  "Return desktop data for an xwidget-webkit buffer: (URL).
Called with the desktop dirname, per `desktop-save-buffer' convention."
  (when (xwidget-at (point-min))
    (list (xwidget-webkit-uri (xwidget-webkit-current-session)))))

(defun bedrock-ide--webkit-desktop-restore (_file name misc)
  "Re-open the webkit session saved from buffer NAME with MISC data."
  (if (and (require 'xwidget nil t)
           (listp misc)
           (car misc)
           (not (string= (car misc) "")))
      (let ((buf (xwidget-webkit--create-new-session-buffer (car misc))))
        (with-current-buffer buf
          (rename-buffer name)
          (xwidget-webkit-goto-uri (xwidget-at (point-min)) (car misc)))
        buf)
    nil))

(with-eval-after-load 'xwidget
  (add-hook 'xwidget-webkit-mode-hook
            (lambda ()
              (setq-local desktop-save-buffer #'bedrock-ide--webkit-desktop-save)))
  (add-to-list 'desktop-buffer-mode-handlers
               '(xwidget-webkit-mode . bedrock-ide--webkit-desktop-restore)))

;; Treemacs: desktop can't save its buffer contents, so remember whether the
;; tree was open and re-open it (project-follow picks files back up) after
;; the desktop is read.
(defvar bedrock-ide--treemacs-was-open nil)

(defun bedrock-ide--treemacs-open-p ()
  (cl-some (lambda (w)
             (string-match-p "Treemacs-Buffer" (buffer-name (window-buffer w))))
           (window-list (selected-frame) 'never-minibuffer nil)))

(defun bedrock-ide--update-treemacs-state (&rest _args)
  (setq bedrock-ide--treemacs-was-open (bedrock-ide--treemacs-open-p)))

(advice-add 'desktop-save :before #'bedrock-ide--update-treemacs-state)

(with-eval-after-load 'treemacs
  (add-to-list 'desktop-globals-to-save 'bedrock-ide--treemacs-was-open)
  (add-hook 'desktop-after-read-hook
            (lambda ()
              (when (and bedrock-ide--treemacs-was-open
                         (not (bedrock-ide--treemacs-open-p)))
                (run-with-idle-timer 1 nil #'bedrock-ide/open-project-tree)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Font
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Berkeley Mono, 14pt.  Icon glyphs (nerd-icons/treemacs) live in the
;; Private Use Area, which Berkeley Mono doesn't cover; route them to
;; Symbols Nerd Font Mono so they render crisply instead of tofu.
;; Install fonts with: brew install --cask font-berkeley-mono (or your own copy)
;;   and: brew install --cask font-symbols-only-nerd-font
(use-package emacs
  :ensure nil
  :config
  (when (display-graphic-p)
    (let ((berkeley (seq-find (lambda (f) (string-match-p "Berkeley" f))
                              (font-family-list))))
      (cond (berkeley
             (set-face-attribute 'default nil :family berkeley :height 140))
            ((member "JetBrainsMono Nerd Font" (font-family-list))
             (set-face-attribute 'default nil
                                 :family "JetBrainsMono Nerd Font" :height 130))))
    (dolist (range '((#xE000 . #xF8FF) (#xF0000 . #xFFFFD)))
      (set-fontset-font t range
                        (font-spec :family "Symbols Nerd Font Mono")
                        nil 'prepend))))
