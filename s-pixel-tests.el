(pop-buffer-insert 5
  (s-pixel-pad "happy hacking emacs" 20 50)
  "\n"
  (s-pixel-pad "happy hacking emacs" 0 50))

(pop-buffer-insert 10
  (s-pixel-reach "happy hacking emacs" 400)
  "\n"
  (s-pixel-reach "happy hacking emacs" 400 'left)
  "\n"
  (s-pixel-reach "happy hacking emacs" 400 'right)
  "\n"
  (s-pixel-reach "happy hacking emacs" 400 'left 30)
  "\n"
  (s-pixel-reach "happy hacking emacs" 400 'left -30)
  "\n"
  (s-pixel-reach "happy hacking emacs" 400 'right 30)
  "\n"
  (s-pixel-reach "happy hacking emacs" 400 'right -30))

(pop-buffer-insert 10
  (s-pixel-align "happy hacking emacs" 400)
  "\n"
  (s-pixel-align "happy hacking emacs" 400 'left)
  "\n"
  (s-pixel-align "happy hacking emacs" 400 'center)
  "\n"
  (s-pixel-align "happy hacking emacs" 400 'right))

(pop-buffer-insert 10
  (s-pixel-center "happy hacking emacs" 500))

(pop-buffer-insert 10
  (s-pixel-floor "happy hacking emacs" 50)
  "\n"
  (s-pixel-left "happy hacking emacs" 50)
  "\n"
  (s-pixel-right "happy hacking emacs" 50)
  "\n"
  (s-pixel-chop-left "happy hacking emacs" 50)
  "\n"
  (s-pixel-chop-right "happy hacking emacs" 50))

;; 示例调用 (假设字符宽度为10像素)
(pop-buffer-insert 20
  ;; 使用当前frame字体度量
  (progn
    (ekp-clear-caches)
    (s-pixel-wrap
     "Ni-ka Ford has always known that she wanted to be an artist. But she wasn’t sure how to channel that passion until her final year as a studio art major in college. She remembers one day in an art studio when she was looking out the window at a tree. “And I was like, ‘Wow, the branches really look like veins in the body,’” she says. This inspiration led her to notice “a lot of similarities between our bodies and nature” and drew her to the field of medical illustration. Today her work distills medical complexity into illustrations and graphics that appear in journal articles, teaching materials and popular publications." 577))
  ;; (knuth-plass-justify
  ;;  "在使用 Emacs 进行开发时，很多用户会依赖 Org-mode 来管理他们的任务和笔记。For instance, with Org-mode, you can easily organize your projects and even export your notes to various formats like HTML or PDF. 此外，Emacs 的可定制性是它的一个巨大优势。You can write your own Emacs Lisp functions to automate repetitive tasks or extend the editor's functionality. 比如，通过编写简单的函数，你可以实现自动格式化代码、批量重命名文件，或者集成Git等版本控制工具。Emacs 的强大之处在于它的灵活性和扩展性，让用户可以根据自己的需求定制工作环境。"
  ;;  400)
  )
