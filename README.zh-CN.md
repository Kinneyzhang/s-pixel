# s-pixel

[English](README.md)

`s-pixel` 是一个小型 Emacs Lisp 辅助库，用于按像素宽度处理字符串的空白、
对齐、截断和换行，而不是按字符数量处理。

它适合用于 Emacs buffer 中的 UI 文本。实际视觉对齐会受到当前 frame、字体、
混合宽度文本以及 `display` 文本属性影响，单纯按字符数对齐通常不够准确。

## 目录

- [项目状态](#项目状态)
- [功能](#功能)
- [依赖](#依赖)
- [安装](#安装)
- [核心概念](#核心概念)
- [快速开始](#快速开始)
- [API 参考](#api-参考)
- [内部辅助函数](#内部辅助函数)
- [手动可视化示例](#手动可视化示例)
- [开发](#开发)
- [许可证](#许可证)

## 项目状态

本仓库是一个仅包含源码的 Emacs Lisp 工具包。目前 `s-pixel-tests.el` 提供
手动可视化示例，不是自动化 ERT 测试套件。

函数实现保持小而直接。公开函数定义在 `s-pixel.el` 中；实现辅助函数和
tokenizer 实验代码定义在 `s-pixel-utils.el` 中。

## 功能

- 使用 Emacs `display` 文本属性创建横向空白。
- 按像素宽度在字符串左右两侧填充。
- 在固定像素宽度槽位中对齐文本。
- 当字符串过宽时，保留左侧或右侧可见内容。
- 从字符串左侧或右侧移除指定像素宽度。
- 通过 `ekp-pixel-justify` 按像素宽度换行。
- 使用内部 tokenizer 辅助函数拆分混合拉丁/CJK 文本。

## 依赖

- 支持 `string-pixel-width` 的 Emacs。建议使用 Emacs 27.1 或更新版本。
- [`s.el`](https://github.com/magnars/s.el)，由 `s-pixel-pad` 使用。
- `ekp`，由 `s-pixel-wrap` 使用，并由 `s-pixel.el` 直接依赖。
- 图形 Emacs frame，用于获得可靠的像素测量结果。

像素测量使用当前选中 frame 和当前字体。GUI 与终端、不同字体、字体变更之后
的测量结果都可能不同。

## 安装

克隆或放置本仓库到本机某个目录，然后加入 `load-path`：

```elisp
(add-to-list 'load-path "/path/to/s-pixel")
(require 's-pixel)
```

只有在需要直接使用内部工具函数时，才单独加载 `s-pixel-utils`：

```elisp
(require 's-pixel-utils)
```

## 核心概念

`s-pixel` 面向渲染宽度工作。字符串宽度通过 `string-pixel-width` 测量，
额外空白通过带属性的空格表示：

```elisp
(propertize " " 'display '(space :width (20)))
```

库中的像素参数表示横向像素宽度。对于保留完整字符串的函数，`total-pixel`
必须大于或等于输入字符串的实际渲染宽度。

会截断内容的函数都在字符边界截断，不会拆开单个渲染字符。

## 快速开始

```elisp
;; 在字符串前添加 20 像素空白，在字符串后添加 50 像素空白。
(s-pixel-pad "happy hacking emacs" 20 50)

;; 让渲染后的字符串占满 400 像素，默认左对齐。
(s-pixel-reach "happy hacking emacs" 400)

;; 在 400 像素宽度内居中或右对齐。
(s-pixel-align "happy hacking emacs" 400 'center)
(s-pixel-align "happy hacking emacs" 400 'right)

;; 保留能放入 50 像素的左侧内容，并在右侧补齐到 50 像素。
(s-pixel-left "happy hacking emacs" 50)

;; 保留能放入 50 像素的右侧内容，并在左侧补齐到 50 像素。
(s-pixel-right "happy hacking emacs" 50)
```

## API 参考

### `s-pixel-spacing`

```elisp
(s-pixel-spacing pixel)
```

返回一个按 `pixel` 像素宽度渲染的横向空白字符串。

当 `pixel` 为 `0` 时返回空字符串；否则返回一个带有 `display` 属性
`(space :width (pixel))` 的空格。它是填充和对齐函数使用的底层构造函数。

### `s-pixel-pad`

```elisp
(s-pixel-pad s prefix-pixel &optional suffix-pixel)
```

返回在 `s` 前后添加像素空白后的字符串。

`prefix-pixel` 是前缀空白宽度。可选参数 `suffix-pixel` 是后缀空白宽度；
省略时不添加后缀空白。该函数会保留 `s` 的原始内容。

### `s-pixel-reach`

```elisp
(s-pixel-reach s total-pixel &optional side offset)
```

返回一个经过填充的字符串，使渲染宽度达到 `total-pixel` 像素。

`side` 控制 `offset` 从哪一侧开始计算，只能是 `left` 或 `right`，默认是
`left`。`offset` 默认是 `0`。

正数 `offset` 从 `side` 一侧开始计算；负数 `offset` 从相反一侧向回计算。
最终偏移量会被限制在合法范围内，确保 `s` 不会超出 `total-pixel`。

如果 `s` 的渲染宽度大于 `total-pixel`，或者 `side` 不受支持，该函数会报错。

### `s-pixel-align`

```elisp
(s-pixel-align s total-pixel &optional align)
```

返回一个填充到 `total-pixel` 像素并按 `align` 对齐的字符串。

`align` 只能是 `left`、`center` 或 `right`，默认是 `left`。如果 `s` 的渲染
宽度大于 `total-pixel`，或者 `align` 不受支持，该函数会报错。

### `s-pixel-center`

```elisp
(s-pixel-center s total-pixel)
```

返回在 `total-pixel` 像素宽度内居中的 `s`。

它是下面调用的便捷封装：

```elisp
(s-pixel-align s total-pixel 'center)
```

### `s-pixel-wrap`

```elisp
(s-pixel-wrap s pixel)
```

对 `s` 换行，使每一行都放入 `pixel` 像素宽度内。

该函数委托给 `ekp-pixel-justify`，因此具体断行行为取决于安装的 `ekp` 实现
和当前 frame 字体。

### `s-pixel-floor`

```elisp
(s-pixel-floor s pixel)
```

返回 `s` 中渲染宽度不超过 `pixel` 的最长前缀。

如果完整字符串能够放入，则返回 `s`。如果第一个渲染字符就超过 `pixel`，
则返回空字符串。

### `s-pixel-left`

```elisp
(s-pixel-left s pixel)
```

返回一个占用 `pixel` 像素宽度、保留 `s` 左侧内容的字符串。

如果 `s` 超过 `pixel`，会在字符边界截断右侧内容，并在右侧补空白，使结果
仍然按 `pixel` 像素宽度渲染。

### `s-pixel-right`

```elisp
(s-pixel-right s pixel)
```

返回一个占用 `pixel` 像素宽度、保留 `s` 右侧内容的字符串。

如果 `s` 超过 `pixel`，会在字符边界截断左侧内容，并在左侧补空白，使结果
仍然按 `pixel` 像素宽度渲染。

### `s-pixel-chop-left`

```elisp
(s-pixel-chop-left s pixel)
```

返回从左侧移除最多 `pixel` 个渲染像素后的 `s`。

当 `pixel` 大于或等于 `s` 的渲染宽度时，结果为空字符串。

### `s-pixel-chop-right`

```elisp
(s-pixel-chop-right s pixel)
```

返回从右侧移除最多 `pixel` 个渲染像素后的 `s`。

当 `pixel` 大于或等于 `s` 的渲染宽度时，结果为空字符串。

## 内部辅助函数

下面这些函数属于实现细节。它们遵循 Emacs Lisp 双连字符命名约定，后续可能
变更。

### `s-pixel--smart-offset`

```elisp
(s-pixel--smart-offset s total-pixel offset-pixel)
```

返回 `s` 在 `total-pixel` 像素宽度内的起始偏移量。

`offset-pixel` 会在扣除 `s` 宽度后的剩余空间里计算。正数从起始位置计算，
负数从末尾向回计算。返回值会被限制在合法范围内，确保 `s` 不会超出
`total-pixel`。

### `s-pixel--align-offset`

```elisp
(s-pixel--align-offset s total align)
```

根据 `align` 返回 `s` 在 `total` 像素宽度内的起始偏移量。

`align` 必须是 `left`、`center` 或 `right`。

### `s-pixel--cjk-char-p`

```elisp
(s-pixel--cjk-char-p char)
```

当 `char` 属于 CJK 相关 Unicode 范围时返回非 nil。

覆盖范围包括常见 CJK 表意文字、CJK 扩展 A 和 B、CJK 标点、假名、韩文音节
以及 CJK 兼容表意文字。

### `s-pixel--split`

```elisp
(s-pixel--split string)
```

把 `string` 拆分为视觉文本单元。

拉丁文本按单词分组，CJK 文本按字符分组，标点会附加到前一个文本单元。
单元之间的空白会被跳过。

## 手动可视化示例

`s-pixel-tests.el` 包含用于视觉检查的手动示例。在图形 Emacs frame 中加载
该文件后运行：

```elisp
(s-pixel-tests-run)
```

测试文件已经包含一个小型独立的 `pop-buffer-insert` 辅助函数，因此不依赖
作者自己的私有 Emacs 配置。

## 开发

编辑时可以运行最小相关批处理加载检查：

```sh
emacs --batch -L . -l s-pixel-utils.el --eval "(message \"s-pixel-utils loaded\")"
emacs --batch -L . -l s-pixel.el --eval "(message \"s-pixel loaded\")"
```

由于主包依赖 `s.el` 和 `ekp`，第二个命令要求这些库已经在 Emacs 的
`load-path` 中可用。

## 许可证

当前仓库没有包含许可证文件。
