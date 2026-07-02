(defun s-pixel--cjk-char-p (char)
  "Return if char CHAR is cjk."
  (or
   ;; CJK统一表意文字（基本区）
   (<= #x4E00 char #x9FFF)
   ;; CJK扩展A区
   (<= #x3400 char #x4DBF)
   ;; CJK扩展B区（注意：超出16位范围）
   (and (<= #x20000 char) (<= char #x2A6DF))
   ;; CJK兼容/部首扩展等
   ;; CJK符号和标点
   (<= #x3000 char #x303F)
   ;; 日文假名
   (<= #x3040 char #x30FF)
   ;; 韩文谚文
   (<= #xAC00 char #xD7AF)
   ;; CJK兼容表意文字
   (<= #xF900 char #xFAFF)))

(defun s-pixel--split (string)
  "Split STRING into a list: English by word, Chinese
by character, punctuation attached to previous unit."
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (let (result)
      (while (not (eobp))
        ;; skip whitespace
        (skip-syntax-forward "-")
        (unless (eobp)
          (let ((start (point)))
            (if (s-pixel--cjk-char-p (char-after))
                (forward-char 1)
              (forward-word 1))
            ;; attach punctuation
            (while (and (not (eobp)) 
                        (equal (char-syntax (char-after)) ?.))
              (forward-char 1))
            (push (buffer-substring-no-properties start (point))
                  result))))
      (nreverse result))))

;; (defun s-pixel--get-text-properties (str)
;;   "获取字符串STR的所有文本属性区间。
;; 返回值为列表，每个元素为 (START END PROPERTIES)，其中
;; START和END为区间的起始和结束位置，PROPERTIES为该区间的属性。"
;;   (let ((len (length str))
;;         (pos 0) ranges)
;;     (while (< pos len)
;;       (let* ((props (text-properties-at pos str))
;;              (next-pos (next-property-change pos str len)))
;;         (when props
;;           (push (list pos next-pos props) ranges))
;;         (setq pos next-pos)))
;;     (nreverse ranges)))

;; (defun s-pixel--copy-text-properties (from-str to-str)
;;   "Copy the text properties of FROM-STR to TO-STR and return TO-STR."
;;   (when-let ((props (s-pixel--get-text-properties from-str)))
;;     (dolist (prop props)
;;       (setq to-str (apply 'propertize to-str (nth 2 prop)))))
;;   to-str)

(provide 's-pixel-utils)
