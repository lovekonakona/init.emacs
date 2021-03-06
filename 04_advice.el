;; -*- encoding: utf-8-unix; -*-
;; File-name:    <04_advice.el>
;; Create:       <2012-01-16 13:44:23 ran9er>
;; Time-stamp:   <2012-02-16 00:22:37 ran9er>
;; Mail:         <2999am@gmail.com>

(defadvice isearch-yank-word-or-char (around aiywoc activate)
  ;; default-key: isearch-mode-map C-w
  (interactive)
  (isearch-yank-string
   (if mark-active
       (buffer-substring-no-properties
        (region-beginning) (region-end))
     (current-word nil nil)))
  (deactivate-mark))

(defadvice comment-or-uncomment-region (before slickcomment activate compile)
  "When called interactively with no active region, toggle comment on current line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (list (line-beginning-position)
           (line-beginning-position 2)))))

(defadvice what-cursor-position (around what-cursor-position-around activate)
  "When called interactively with active region, print info of region instead."
  (if mark-active
      (let ((beg (region-beginning))
            (end (region-end)))
        (message "Region: begin=%d end=%d length=%d"
                 beg end (- end beg)))
    ad-do-it))

(defadvice delete-horizontal-space (around resize-space (&optional backward-only) activate)
  "if elop or bolp or space around \"(\" or \")\", delete all space;"
  (interactive "*P")
  (let ((orig-pos (point))
        (skip-chars " \t")
        (delimit-char
         (mapcar (lambda (x) (string-to-char x))
                 '("(" ")")))
        fwd-pos fwd-p bwd-pos bwd-p)
    (setq
     fwd-pos (progn (skip-chars-forward skip-chars)(eolp))
     fwd-p  (memq (following-char) delimit-char)
     bwd-pos (progn (skip-chars-backward skip-chars)(bolp))
     bwd-p  (memq (preceding-char) delimit-char))
    (goto-char orig-pos)
    (if (or fwd-pos bwd-pos (and fwd-p bwd-p))
        ad-do-it
      ad-do-it
      (insert " ")
      (if bwd-p (backward-char 1)))))

(defadvice kill-line (around merge-line (&optional arg) activate)
  "if this line is not empty and cursor in the end of line, merge next N line"
  (interactive "P")
  (let ((n (or arg 1)))
    (if (and (null (bolp)) (eolp))
        (while (< 0 n)
          (delete-char 1)
          (delete-horizontal-space)
          (if (< 1 n) (end-of-line))
          (setq n (1- n)))
      ad-do-it)))

(defadvice kill-ring-save (around slick-copy activate)
  "When called interactively with no active region, copy a single line instead."
  (if (or (use-region-p) (not (called-interactively-p)))
      ad-do-it
    (kill-new (buffer-substring (line-beginning-position)
                                (line-beginning-position 2))
              nil '(yank-line))
    (message "Copied line")))

(defadvice kill-region (around slick-copy)
  "When called interactively with no active region, kill a single line instead."
  (if (or (use-region-p) (not (called-interactively-p)))
      ad-do-it
    (kill-new (filter-buffer-substring (line-beginning-position)
                                       (line-beginning-position 2) t)
              nil '(yank-line))))

(defadvice kill-region (before smart-kill)
  (let ((p (point))
        (i (save-excursion (abs (skip-chars-backward " \t")))))
    (setq end p)
    (cond
     ((if mark-active
          (setq beg (mark))))
     ((< 0 i)
       (if (zerop (mod i tab-width))
           (setq beg (- p tab-width))
         (setq beg (- p (mod i tab-width)))))
     (t
      (progn (backward-word)
             (setq beg (point)))))))
;; (ad-activate 'kill-region)
;; (ad-deactivate 'kill-region)

(defun yank-line (string)
  "Insert STRING above the current line."
  (beginning-of-line)
  (unless (= (elt string (1- (length string))) ?\n)
    (save-excursion (insert "\n")))
  (insert string))

(defadvice skeleton-pair-insert-maybe (around xxx activate)
  (let ((skeleton-pair-alist skeleton-pair-alist)
        (c-before
         (lambda(x)(save-excursion
                 (skip-chars-backward " \t")
                 (eq (char-before (point)) x)))))
    (if (and (eq last-command-event 123)(funcall c-before 61))
        (setq skeleton-pair-alist '((?\{ _ "}"))))
    ad-do-it))
