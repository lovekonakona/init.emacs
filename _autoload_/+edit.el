;; -*- encoding: utf-8-unix; -*-
;; File-name:    <edit.el>
;; Create:       <2011-12-27 21:29:35 ran9er>
;; Time-stamp:   <2012-02-10 13:39:04 ran9er>
;; Mail:         <2999am@gmail.com>

;;;###autoload
(defun swap-point()
  (interactive)
  (if (or (null (boundp '*last-point*)) (null *last-point*))
      (progn (make-local-variable '*last-point*)
             (setq *last-point* (cons (point) (point))))
    (let ((p (point)))
      (if (eq p (cdr *last-point*))
          (progn (goto-char (car *last-point*))
                 (setq *last-point* (cons (cdr *last-point*)(car *last-point*))))
        (goto-char (cdr *last-point*))
        (setq *last-point* (cons p (cdr *last-point*)))))))


;;;###autoload
(defun resize-horizontal-space (&optional backward-only)
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
        (delete-horizontal-space backward-only)
      (delete-horizontal-space backward-only)
      (insert " ")
      (if bwd-p (backward-char 1)))))

;;;###autoload
(defun smart-backward-kill ()
  (interactive)
  (let ((i (save-excursion (abs (skip-chars-backward " \t")))))
    (cond
     (mark-active
      (call-interactively 'kill-region))
     ((< 0 i)
      (backward-delete-char
       (if (zerop (mod i tab-width)) tab-width (mod i tab-width))))
     (t
      (call-interactively 'backward-kill-word)))))

;; parallel-edit
(defun insert-char-from-read(c)
  (cond
   ((eq c 13)
    (newline))
   ((eq c 127)
    (delete-backward-char 1))
   ((eq c 23)
    (backward-kill-word 1))
   (t
    (insert-char c 1))))

(defun mirror-region (src psn mkr-lst)
  "mirror region in mkr-lst, with str, and goto psn"
  (let ((str (buffer-substring-no-properties (car src)(cdr src))))
    (mapcar
     (lambda(x)
       (delete-region (car x)(1- (cdr x)))
       (goto-char (car x))
       (insert str))
     mkr-lst))
  (goto-char psn))

;;;###autoload
(defun parallel-edit (position-list &optional prt)
  (interactive)
  (let* ((p (or prt 0))
         (start-position (point-marker))
         end-position y x
         (end-marker (progn (forward-char (1+ p))(point-marker)))
         (marker-list (mapcar (lambda (x)
                                (cons
                                 (progn (goto-char x)(point-marker))
                                 (progn (forward-char (1+ p))(point-marker))))
                              position-list)))
    (goto-char start-position)
    (setq y nil)
    (while (null (eq (setq x (read-char "parallel-edit")) 13))
      (if y nil
        (delete-region start-position (1- end-marker)))
      (insert-char-from-read x)
      (setq end-position (1- end-marker)
            y t)
      (mirror-region (cons start-position end-position) end-position marker-list))))

;; outside
;;;###autoload
(defun outside (o b s &optional n)
  "up list N level, append PRE ahead and SUF behind, backward M char"
  (interactive "P")
  (let ((x (if n (prefix-numeric-value n) 1))
        beg end tmp delimiter)
    (if mark-active
        (setq delimiter ""
              beg (region-beginning)
              end (region-end))
      (setq delimiter s)
      (up-list x)
      ;; (setq end (point))
      ;; (setq beg (backward-list))
      ;; (while (member (char-to-string (get-byte (1- beg)))
      ;;                '("'" "`" "," "#" "@"))
      ;;   (setq beg (1- beg)))
      (setq end (point)
            beg (+ (backward-list)(skip-chars-backward  "'`,#@"))))
    (setq tmp (buffer-substring-no-properties beg end))
    (delete-region beg end)
    (insert o)
    (backward-char b)
    (save-excursion
      (insert delimiter tmp))))

;;;###autoload
(defun outside-kill (&optional n)
  "up list N level, append PRE ahead and SUF behind, backward M char"
  (interactive "P")
  (let ((x (if n (prefix-numeric-value n) 1))
        beg end tmp)
    (if mark-active
        (setq beg (region-beginning)
              end (region-end))
      (up-list 1)
      (setq end (point)
            beg (+ (backward-list)(skip-chars-backward  "'`,#@"))))
    (setq tmp (buffer-substring-no-properties beg end))
    (delete-region beg end)
    (up-list x)
    (delete-region
     (point)
     (+ (backward-list)(skip-chars-backward  "'`,#@")))
    (save-excursion
      (insert tmp))))
