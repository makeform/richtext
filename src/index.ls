quill-css = {}

# adopted from word-len in @plotdb/form op internal function
word-len = (v = "", method) ->
  return if method == \simple-word =>
    v.split(/\s|[,.;:!?，。；：︰！？、．　"]/).filter(->it)
      .map ->
        # segment by non-ascii codes
        it.split(/[\u1000-\uffff]/).map(-> if it.length => 2 else 1).reduce(((a,b) -> a + b),0) - 1
      .reduce(((a,b) -> a + b), 0)
  else v.length

hint = (content, terms, t) ->
  terms = (terms or []).filter -> it.opset == \richtext and it.op == \text-length
  lc = {}
  if !terms.length => return {invalid: false, text: ""}
  list = terms.map (term) ->
    {min, max, method} = term.config or {}
    if min? => lc.min = (lc.min or 0) >? min
    if max? => lc.max = (if !lc.max? => max else lc.max) <? max
    count = word-len content, method
    lc.count = count
    [
      if min? => count - min else undefined
      if max? => max - count else undefined
    ]
  ret = [
    Math.min.apply Math, list.map ->it.0
    Math.min.apply Math, list.map ->it.1
  ]
  ret = if lc.min? and ret.0 < 0 => [-1, "#{t(\還差)} #{-ret.0} #{t(\字)}"]
  else if lc.max? and ret.1 < 0 => [1, "#{t(\超過)} #{-ret.1} #{t(\字)}"]
  else if lc.max? => [0, "#{t(\還剩)} #{ret.1} #{t(\字)}"]
  else [0, "#{t(\已寫)} #{lc.count} #{t(\字)}"]
  {invalid: !!ret.0, text: ret.1}

module.exports =
  pkg:
    name: \@makeform/richtext
    extend: name: \@makeform/common
    host: name: \@grantdash/composer
    i18n:
      en:
        "還差": "remaining to reach:"
        "超過": "exceeded by:"
        "還剩": "remaining:"
        "已寫": "written:"
        "字": "word(s)"
        "image-uploading": "Uploading image. Please wait until it's done."
        "fullscreen-enter": "Expand editor"
        "fullscreen-exit": "Collapse editor"
        # texts of the table engine's ui ( see `table-engines` )
        table:
          "fullCheckboxText": "Insert full width table"
          "customBtnText": "Custom"
          "confirmText": "Confirm"
          "cancelText": "Cancel"
          "rowText": "Row"
          "colText": "Column"
          "notPositiveNumberError": "Please enter a positive integer"
          "custom": "Custom"
          "clear": "Clear"
          "transparent": "Transparent"
          "perWidthInsufficient": "The percentage width is insufficient. To complete the operation, the table needs to be converted to a fixed width. Do you want to continue?"
          "InsertTop": "Insert a row above"
          "InsertRight": "Insert a column right"
          "InsertBottom": "Insert a row below"
          "InsertLeft": "Insert a column left"
          "MergeCell": "Merge cells"
          "SplitCell": "Split cell"
          "DeleteRow": "Delete row"
          "DeleteColumn": "Delete column"
          "DeleteTable": "Delete table"
          "BackgroundColor": "Set background color"
          "BorderColor": "Set border color"
          "FreezeRow": "Freeze to this row"
          "UnfreezeRow": "Unfreeze"
          "FreezeCol": "Freeze to this column"
          "UnfreezeCol": "Unfreeze column"
          "SwitchWidth": "Switch table width"
          "InsertCaption": "Insert table caption"
          "ToggleTdBetweenTh": "Toggle header cell"
        config:
          hint: name: 'Character Count Hint', desc: "Show character count and limit hints."
          fullscreen: enabled: name: 'Fullscreen Editing', desc: "Show a button to edit in a large popup. Default: enabled."
          table: enabled: name: 'Tables', desc: "Show a button to insert tables. Default: enabled."
          image:
            compress:
              enabled: name: 'Image Compression', desc: "Compress images before uploading. Default: enabled."
              filesize: name: 'Max File Size (KB)', desc: "Maximum image size in KB after compression. Default: 500."
              pixel: name: 'Max Dimension (px)', desc: "Maximum image width or height in pixels. Default: 1200."
      "zh-TW":
        "還差": "還差"
        "超過": "超過"
        "還剩": "還剩"
        "已寫": "已寫"
        "字": "字"
        "image-uploading": "圖片上傳中，請稍候。"
        "fullscreen-enter": "放大編輯"
        "fullscreen-exit": "收合"
        table:
          "fullCheckboxText": "插入滿版表格"
          "customBtnText": "自訂"
          "confirmText": "確定"
          "cancelText": "取消"
          "rowText": "列"
          "colText": "欄"
          "notPositiveNumberError": "請輸入正整數"
          "custom": "自訂"
          "clear": "清除"
          "transparent": "透明"
          "perWidthInsufficient": "百分比寬度不足，需改為固定寬度才能完成，是否繼續？"
          "InsertTop": "上方插入列"
          "InsertRight": "右方插入欄"
          "InsertBottom": "下方插入列"
          "InsertLeft": "左方插入欄"
          "MergeCell": "合併儲存格"
          "SplitCell": "分割儲存格"
          "DeleteRow": "刪除列"
          "DeleteColumn": "刪除欄"
          "DeleteTable": "刪除表格"
          "BackgroundColor": "背景色"
          "BorderColor": "框線色"
          "FreezeRow": "凍結至此列"
          "UnfreezeRow": "取消凍結"
          "FreezeCol": "凍結至此欄"
          "UnfreezeCol": "取消凍結欄"
          "SwitchWidth": "切換表格寬度"
          "InsertCaption": "加入表格標題"
          "ToggleTdBetweenTh": "切換為標題儲存格"
        config:
          hint: name: '字數提示', desc: "啟用字數提示"
          fullscreen: enabled: name: '放大編輯', desc: "顯示放大編輯按鈕，預設啟用。"
          table: enabled: name: '表格', desc: "顯示插入表格按鈕，預設啟用。"
          image:
            compress:
              enabled: name: '圖片壓縮', desc: "上傳前壓縮圖片，預設啟用。"
              filesize: name: '檔案大小上限 (KB)', desc: "壓縮後的圖片大小上限（KB），預設 500。"
              pixel: name: '長邊像素上限 (px)', desc: "圖片寬或高的像素上限，預設 1200。"
    dependencies: [
    # quilljs uses css such as @support which isn't handled correctly by csscope.
    # this leads to incorrect list numbering (requires correct counter-reset style to solve)
    # which leads to separated list numbered as a single one.
    # before we fix this issue in csscope, we have to load it programmatically ( see init func )
    # however, we may have quill imported in other context,
    # so we scope it in `mf-rictext-quill` class and put it in a separated quill.snow.css locally
    # * name: \@makeform/richtext, path: "quill.snow.min.css", global: true
    # quill has XSS issues in <= 2.0.3; we hotfix in forked module
    * name: \@plotdb/quill, version: \main, path: \dist/quill.js
    * name: "dompurify", version: \main, path: \dist/purify.min.js
    * name: "ldcolor", version: "main", path: "index.min.js", async: false
    * name: "@loadingio/ldcolorpicker", version: "main", path: "index.min.js"
    * name: "@loadingio/ldcolorpicker", version: "main", path: "index.min.css", global: true
    * name: \ldfile
    # table engine, see `table-engines`. its UMD build reads `Quill` from the context, so it goes after quill.
    * name: "quill-table-up", version: \main, path: \dist/index.umd.js
    * name: "quill-table-up", version: \main, path: \dist/index.css, global: true
    * name: "quill-table-up", version: \main, path: \dist/table-creator.css, global: true
    ]
  init: (opt) ->
    opt.pubsub.on \inited, (o = {}) ~> @ <<< o
    opt.pubsub.fire \subinit, mod: mod.call @, opt
  client: (bid) ->
    meta: config:
      hint: enabled: type: \boolean, name: \config.hint.name, desc: \config.hint.desc
      fullscreen: enabled: type: \boolean, default: true, name: \config.fullscreen.enabled.name, desc: \config.fullscreen.enabled.desc
      table: enabled: type: \boolean, default: true, name: \config.table.enabled.name, desc: \config.table.enabled.desc
      image: compress:
        enabled: type: \boolean, name: \config.image.compress.enabled.name, desc: \config.image.compress.enabled.desc
        filesize: type: \number, name: \config.image.compress.filesize.name, desc: \config.image.compress.filesize.desc
        pixel: type: \number, name: \config.image.compress.pixel.name, desc: \config.image.compress.pixel.desc

# ---- table engines ---------------------------------------------------------------------------
# a table plugin is an engine: how it's registered, its toolbar item and module options.
# engines store tables in their own delta formats ( blot names ), which other engines - or quill
# without one - can't read: such a delta loads as an empty table or loses it altogether. the html
# however converts fine between them ( cells, merged cells, column widths ). so a value records
# the engine that wrote its tables ( `table` ), and a value from another engine is loaded from its
# html instead of its delta ( see `@on \change` in init ).
# to switch engines: add one here, list its files in `dependencies`, and point `table-engine` to it.
#  - `id`: stored in the value. bump it when a new major of the plugin changes the delta format.
#  - `init(ctx, Quill, t, {menu})`: register to quill once, return `{toolbar, tool, modules, formats}`:
#    the toolbar items, the toolbar format name ( its button is `.ql-<tool>` ), module options and
#    the formats its tables use. `menu`: names of the context menu items ( see `table-menus` ).
table-engines =
  up:
    id: \table-up@3
    init: (ctx, Quill, t, {menu} = {}) ->
      T = ctx.TableUp
      if !T => return null
      if !table-engines.up.registered =>
        Quill.register {"modules/#{T.TableUp.moduleName}": T.TableUp}, true
        table-engines.up.registered = true
      toolbar: [{"#{T.TableUp.toolName}": []}]
      tool: T.TableUp.toolName
      modules: "#{T.TableUp.moduleName}":
        full: true
        customSelect: T.defaultCustomSelect
        customBtn: true
        # an object, not a function: given a function, table-up builds its context menu twice.
        texts: Object.fromEntries table-text-keys.map (k) -> [k, t("table.#k")]
        modules: [
          {module: T.TableResizeLine}
          {module: T.TableResizeScale}
          {module: T.TableAlign}
          {module: T.TableSelection}
          {module: T.TableMenuContextmenu, options: tools: (menu or table-menus.basic).map((n) -> T.tableMenuTools[n]).filter(-> it)}
        ]
      # for `config.strict`: the formats its tables are made of
      formats: Object.values(T.blotName or {})
  # quill's own table module: insert / delete rows and columns by api only, no ui. not used as an engine,
  # but its formats are always registered ( quill's full build ), so values from before `table` existed
  # may hold such tables ( `table` attribute on cell lines ); they're treated as written by this engine.
  builtin:
    id: \quill-table@2
    init: -> toolbar: null, modules: {table: true}, formats: <[table]>
table-engine = \up
# keys of table-up's ui texts, translated in i18n `table`
table-text-keys = <[fullCheckboxText customBtnText confirmText cancelText rowText colText notPositiveNumberError custom clear transparent perWidthInsufficient InsertTop InsertRight InsertBottom InsertLeft MergeCell SplitCell DeleteRow DeleteColumn DeleteTable BackgroundColor BorderColor FreezeRow UnfreezeRow FreezeCol UnfreezeCol SwitchWidth InsertCaption ToggleTdBetweenTh]>

# ---- presets ---------------------------------------------------------------------------------
# what the editor offers comes from a preset ( `config.preset` , default `basic` ), and each tool
# can be turned on or off on top of it ( `config.tools` , e.g. `{table: false, color: true}` ).
# the older switches `config.fullscreen.enabled` / `config.table.enabled` still work; `tools` wins.
# every tool is in the toolbar, shown or hidden by the config, so the config can change any time.
# this only shows / hides buttons: shortcuts and pasted content still bring any format in, so
# values keep what they had. `config.strict` ( read once, at init ) limits the formats to the
# enabled tools - pasted formats outside them are dropped, and so are such formats in stored values.
#  - `bar`: toolbar item. `sel`: its toolbar element(s). `fmt`: formats it brings ( for strict ).
tool-defs =
  header: bar: {header: [1, 2, false]}, sel: \.ql-header, fmt: <[header]>
  bold: bar: \bold, fmt: <[bold]>
  italic: bar: \italic, fmt: <[italic]>
  underline: bar: \underline, fmt: <[underline]>
  strike: bar: \strike, fmt: <[strike]>
  color: bar: \color, fmt: <[color]>
  list: bar: [{list: \ordered}, {list: \bullet}], fmt: <[list indent]>
  align: bar: {align: []}, fmt: <[align]>
  blockquote: bar: \blockquote, fmt: <[blockquote]>
  link: bar: \link, fmt: <[link]>
  image: bar: \image, fmt: <[image]>
  table: {} # from the table engine
  fullscreen: bar: \fullscreen
# toolbar groups ( one `.ql-formats` each ), in order
tool-groups = [<[header]> <[bold italic underline strike color]> <[list align blockquote]> <[link image table]> <[fullscreen]>]
presets =
  minimal: tools: <[bold italic underline list link]>
  basic: tools: <[header bold italic underline list align link image table fullscreen]>, table-menu: \basic
  full: tools: <[header bold italic underline strike color list align blockquote link image table fullscreen]>, table-menu: \full
# items of the table's context menu, by name ( table-up's `tableMenuTools` ). `Break` is a divider.
# `config.table.menu`: a list of names, or the name of one of these. read once, at init.
table-menus =
  basic: <[InsertTop InsertRight InsertBottom InsertLeft Break MergeCell SplitCell Break DeleteRow DeleteColumn DeleteTable Break BackgroundColor BorderColor]>
table-menus.full = table-menus.basic ++ <[Break FreezeRow UnfreezeRow FreezeCol UnfreezeCol Break SwitchWidth InsertCaption ToggleTdBetweenTh]>

# {tool: true / false} from the config
active-tools = (cfg = {}) ->
  set = Object.fromEntries (presets[cfg.preset] or presets.basic).tools.map -> [it, true]
  if (cfg.fullscreen or {}).enabled? => set.fullscreen = !!cfg.fullscreen.enabled
  if (cfg.table or {}).enabled? => set.table = !!cfg.table.enabled
  for k, v of (cfg.tools or {}) => set[k] = !!v
  set

mod = ({root, manager, ctx, data, parent, t}) ->
  {ldview, Quill, ldcolor, ldcolorpicker, ldfile, DOMPurify} = ctx
  image-meta = {}
  # types accepted from the toolbar, drop and file paste. all are re-encoded as jpeg when
  # compression is on ( so a gif loses its animation ).
  image-types = <[image/png image/jpeg image/gif image/webp]>
  init: ->
    self = @
    # workaround: @plotdb/csscope doesn't inject quill-css correctly so we do it here manually.
    if !quill-css.node =>
      url = manager.get-url {name: \@makeform/richtext, path: \quill.snow.min.css}
      quill-css.node = link = document.createElement \link
      link.setAttribute \rel, \stylesheet
      link.setAttribute \href, url
      link.setAttribute \type, \text/css
      link.setAttribute \id, \_quilljs-css-element
      document.body.appendChild link
    lc = @mod.child
    @on \change, (v = {}) ~>
      (v.images or []).for-each (img) -> if img.url => image-meta[img.url] = img
      json = v.json or {}
      # drop placeholders left in stored data (saved mid-upload, or written by an older version
      # that had no marker): they aren't content, and a spinner that never resolves is worse
      # than showing nothing.
      n = (json.ops or []).length
      json.ops = (json.ops or []).filter (op) -> !uploader.is-placeholder((op.insert or {}).image)
      dropped = n - json.ops.length
      # compare against our own placeholder-free view of the document, not the raw contents:
      # the editor legitimately holds placeholders that never appear in the value, and counting
      # them as a diff would setContents them away while their upload is still in flight.
      if JSON.stringify(doc-json!) == JSON.stringify(json) => return
      # `\silent`: this is an external value pushed in, not a user edit. without it quill fires
      # text-change, which would (a) re-run upload detection over imported data-url images and
      # (b) write back through @value, risking a change -> setContents -> change loop.
      # tables written by another engine ( or by one when we have none ) can't be read from the
      # delta, so such a value is rebuilt from its html. it's saved in our format on the next edit.
      # values written before `table` existed may still hold tables: quill's full build registers its
      # own table formats, so a table pasted into an older version was kept as one.
      from = v.table or (if (json.ops or []).some((op) -> (op.attributes or {}).table?) => table-engines.builtin.id)
      if from and from != (table or {}).id and v.html =>
        quill.setContents [], \silent
        quill.updateContents quill.clipboard.convert({html: v.html}), \silent
      else quill.setContents json, \silent
      view.render <[remains]>
      # write the cleaned document back, so such a record is repaired on its next save rather
      # than carrying the dead placeholder until the user happens to edit the field.
      if dropped => @value build-value!
    lc.view = view = new ldview do
      root: root
      action: click:
        "fullscreen-close": ->
          exit-fullscreen!
          # the button is hidden now, so don't leave the focus on it.
          quill.focus!
      handler:
        content: ({node}) -> node.innerHTML = DOMPurify.sanitize quill.root.innerHTML
        editor: -> sync-tools!
        "fullscreen-title": @mod.hitf.render {path: \title}
        "fullscreen-close": ({node}) ->
          node.setAttribute \title, t(\fullscreen-exit)
          node.setAttribute \aria-label, t(\fullscreen-exit)
        remains: ({node}) ~>
          enabled = !!(@mod.info.config.hint or {}).enabled
          node.classList.toggle \d-none, !enabled
          if !enabled => return node.textContent = ""
          content = (quill.getText! or '').trim!
          terms = @serialize!term
          ret = hint content, terms, t
          node.textContent = ret.text
          node.classList.toggle \text-danger, !!ret.invalid
    # the engine is always set up, whether the table button shows or not ( `tools.table` ): a pasted
    # table is still a table, and a stored one must stay editable after the option is turned off.
    cfg = @mod.info.config or {}
    menu = (cfg.table or {}).menu
    menu = if Array.isArray(menu) => menu else table-menus[menu or (presets[cfg.preset] or presets.basic).table-menu or \basic]
    table = if (e = table-engines[table-engine]) and (o = e.init ctx, Quill, t, {menu}) => {id: e.id} <<< o else null
    # every tool goes in ( except under `strict` ); `sync-tools` shows the enabled ones.
    bar-of = (k) -> if k == \table => ((table or {}).toolbar or []) else [].concat(tool-defs[k].bar)
    tools-at-init = active-tools cfg
    quill = new Quill view.get(\input), do
      theme: \snow
      formats: if !cfg.strict => undefined else
        [k for k of tools-at-init when tools-at-init[k]]
          .map((k) -> if k == \table => ((table or {}).formats or []) else (tool-defs[k].fmt or []))
          .reduce(((a, b) -> a ++ b), [])
      modules: {
        toolbar:
          # under `strict` the formats are fixed at init, so a disabled tool would be a dead button
          container: tool-groups
            .map((g) -> g.filter((k) -> !cfg.strict or tools-at-init[k]).map(bar-of).reduce(((a, b) -> a ++ b), []))
            .filter(-> it.length)
          handlers:
            # the palette is ldcolorpicker's, opened by the same button ( see the end of init )
            color: ->
            fullscreen: -> if lc.fullscreen => exit-fullscreen! else enter-fullscreen!
            image: ~>
              input = document.createElement \input
              input.setAttribute \type, \file
              input.setAttribute \accept, image-types.join(', ')
              input.setAttribute \multiple, true
              input.onchange = ~>
                files = Array.from(input.files or [])
                input.value = null
                insert-files (quill.getSelection(true) or {index: quill.getLength! - 1}), files
              input.click!
        # files dropped onto the editor, or pasted as files ( e.g. a screenshot ). without this
        # quill turns them into data urls, which then go the paste route below - same result,
        # but the whole file is base64-ed into the document first.
        uploader:
          mimetypes: image-types
          handler: (range, files) -> insert-files range, files
      } <<< ((table or {}).modules or {})

    # enlarge the editor where it is, instead of opening a second quill in a popup: with a single
    # instance, in-flight uploads, placeholders and `image-meta` need no syncing at all. it also
    # stays in place in the DOM since moving it out of the widget loses the csscope scope.
    # the popover puts it in the top layer so ancestors can't trap it - a `transform` ancestor
    # would make a `position: fixed` element relative to that ancestor. without popover support
    # we just live with `position: fixed`.
    editor = view.get \editor
    fullscreen-btn = quill.getModule(\toolbar).container.querySelector \.ql-fullscreen
    fullscreen-icon = (d) ->
      """<svg viewBox="0 0 18 18"><path class="ql-stroke" fill="none" d="#d"></path></svg>"""
    fullscreen-icons =
      enter: fullscreen-icon "M3 7V3H7M11 3H15V7M15 11V15H11M7 15H3V11"
      exit: fullscreen-icon "M7 3V7H3M11 3V7H15M15 11H11V15M7 15V11H3"
    set-fullscreen-btn = (state) ->
      fullscreen-btn.innerHTML = fullscreen-icons[state]
      fullscreen-btn.setAttribute \title, t("fullscreen-#state")
    set-fullscreen-btn \enter

    tools = ~> active-tools @mod.info.config
    fullscreen-enabled = ~> !!tools!.fullscreen

    enter-fullscreen = ~>
      if lc.fullscreen or @_mode != \edit or !fullscreen-enabled! => return
      # the editor leaves the flow; hold its space so that the page behind doesn't jump.
      editor.parentNode.style.minHeight = "#{editor.offsetHeight}px"
      lc.fullscreen = overflow: document.documentElement.style.overflow
      document.documentElement.style.overflow = \hidden
      editor.classList.add \fullscreen
      # only set while open: UA rules hide any element with a `popover` attribute when it's closed.
      if editor.showPopover =>
        editor.setAttribute \popover, \manual
        editor.showPopover!
      set-fullscreen-btn \exit

    exit-fullscreen = ->
      if !lc.fullscreen => return
      # removing the attribute hides the popover as well.
      editor.removeAttribute \popover
      editor.classList.remove \fullscreen
      editor.parentNode.style.minHeight = ''
      document.documentElement.style.overflow = lc.fullscreen.overflow
      lc.fullscreen = null
      set-fullscreen-btn \enter

    # show the enabled tools ( see `presets` ), and a group only when something in it shows.
    # a picker's `<select>` shares the class and is hidden by quill itself, so leave it alone.
    sync-tools = ->
      act = tools!
      bar = quill.getModule(\toolbar).container
      for k of tool-defs =>
        name = if k == \table => (table or {}).tool else (tool-defs[k].sel or ".ql-#k").substring(4)
        if !name => continue
        Array.from(bar.querySelectorAll ".ql-#name:not(select)").for-each (n) -> n.style.display = if act[k] => '' else \none
      Array.from(bar.querySelectorAll \.ql-formats).for-each (g) ->
        g.style.display = if Array.from(g.children).some((n) -> n.tagName != \SELECT and n.style.display != \none) => '' else \none
      if !act.fullscreen => exit-fullscreen!

    # view mode must be inert: not editable, thus no text-change, thus no upload.
    sync-mode = ~>
      # only on an actual change: table-up rebuilds its ui ( menus etc. ) whenever `contenteditable` is
      # written, without dropping the old one, so a repeated enable(true) stacks a second context menu.
      if quill.isEnabled! != (@_mode == \edit) => quill.enable @_mode == \edit
      if @_mode != \edit => exit-fullscreen!
      # defined further down; `sync-mode` also runs once before that.
      if select-image => select-image null
    @on \mode, sync-mode
    sync-mode!

    # Returns {enabled, pixel, filesize} from config.image.compress, with defaults applied.
    compress-opts = ->
      cfg = ((self.mod.info.config?.image or {}).compress) or {}
      enabled: if cfg.enabled? => !!cfg.enabled else true
      pixel: cfg.pixel or 1200
      filesize: cfg.filesize or 500

    # Compress image blob: resize to max `pixel` on longest side, JPEG, under `filesize` KB.
    compress-image = (blob, pixel = 1200, filesize = 500) ->
      new Promise (resolve, reject) ->
        url = URL.createObjectURL blob
        img = new Image!
        img.onload = ->
          URL.revokeObjectURL url
          {width, height} = img
          if width > pixel or height > pixel
            if width >= height
              height = Math.round height * pixel / width
              width = pixel
            else
              width = Math.round width * pixel / height
              height = pixel
          canvas = document.createElement \canvas
          canvas.width = width
          canvas.height = height
          ctx = canvas.getContext \2d
          ctx.drawImage img, 0, 0, width, height
          max-bytes = filesize * 1024
          try-quality = (lo, hi, cb) ->
            if hi - lo < 0.01
              canvas.toBlob cb, 'image/jpeg', lo
              return
            mid = (lo + hi) / 2
            canvas.toBlob (b) ->
              if b.size <= max-bytes => cb b
              else try-quality lo, mid, cb
            , 'image/jpeg', mid
          canvas.toBlob (b) ->
            if b.size <= max-bytes => resolve b
            else try-quality 0.1, 0.85, resolve
          , 'image/jpeg', 0.85
        img.onerror = reject
        img.src = url

    get-image-meta = (blob) ->
      new Promise (resolve, reject) ->
        url = URL.createObjectURL blob
        img = new Image!
        img.onload = ->
          URL.revokeObjectURL url
          {width, height} = img
          long  = width >? height
          short = width <? height
          pixels = width * height
          resolve {width, height, long, short, pixels, size: blob.size}
        img.onerror = reject
        img.src = url

    check-image-terms = (meta) ->
      ts = (self._meta?.term or []).filter (term) ->
        term.op?.id in <[long-side short-side width height pixel-count file-size]>
      if !ts.length => return Promise.resolve!
      ps = ts.map (term) -> term.validate {images: [meta]}
      Promise.all(ps).then (rets) ->
        failed = rets.map((r,i) -> [r, ts[i]]).filter(->!it.0).map(->it.1)
        if failed.length =>
          msg = failed.map(-> it.msg or '檔案規格不符').join('; ')
          return Promise.reject new Error(msg)

    build-images = ->
      nd = quill.getContents!
      (nd.ops or [])
        .filter (op) -> op.insert?.image and image-meta[op.insert.image]
        .map (op) -> {url: op.insert.image} <<< image-meta[op.insert.image]

    # patch only the image embeds we care about, leaving the rest of the document retained.
    # we used to rebuild everything with setContents from a snapshot taken before the async
    # work started, which (a) dropped the caret and (b) raced with the user's own edits and
    # with other uploads finishing around the same time - each writing back its stale snapshot.
    # a delta touches nothing else, and quill transforms the selection for us.
    #  - `pred(url)`: which image embeds to patch.
    #  - `fn(delta, op)`: what to append to the delta for a matched op.
    patch-images = (pred, fn) ->
      Delta = Quill.import \delta
      delta = new Delta!
      found = false
      (quill.getContents!ops or []).for-each (op) ->
        url = (op.insert or {}).image
        if typeof(url) == \string and pred(url) =>
          found := true
          fn delta, op
        else delta.retain(if typeof(op.insert) == \string => op.insert.length else 1)
      if !found => return false
      quill.updateContents delta, \silent
      true

    replace-image = (sig, url) ->
      patch-images(
        (u) -> uploader.get-sig(u) == sig
        (delta, op) -> delta.delete(1).insert({image: url}, op.attributes)
      )

    remove-images = (sigs) ->
      patch-images(
        (u) -> sigs.indexOf(uploader.get-sig u) >= 0
        (delta) -> delta.delete 1
      )

    # mark the widget as busy so `validate` reports it invalid, which blocks submit while
    # leaving local save untouched. this must cover the whole pipeline - compressing a large
    # image takes time too, and the field must not look ready while its images are in flight.
    mark-pending = ~>
      lc.uploading = (lc.uploading or 0) + 1
      @validate!
      done = false
      ~>
        if done => return
        done := true
        lc.uploading = (lc.uploading or 1) - 1
        @validate!

    # the document as it should be stored. placeholder images are transient UI state, never
    # data: dropping them here means a save (or autosave) during an upload won't persist a
    # loading spinner into the record, which would otherwise be re-uploaded on every reload.
    doc-json = ->
      json = quill.getContents!
      json.ops = (json.ops or []).filter (op) -> !uploader.is-placeholder((op.insert or {}).image)
      json

    build-value = ->
      json = doc-json!
      node = quill.root.cloneNode true
      Array.from(node.querySelectorAll('img'))
        .filter (img) -> uploader.is-placeholder img.getAttribute(\src)
        .for-each (img) -> img.parentNode.removeChild img
      ret =
        json: json
        text: quill.getText!
        html: DOMPurify.sanitize node.innerHTML
        images: build-images!
      # which engine wrote the tables in `json`, so another one knows to use `html` ( see `@on \change` )
      if table and node.querySelector(\table) => ret.table = table.id
      ret

    # ---- image pipeline ----------------------------------------------------------------------
    # every way an image comes in ends up in `ingest`:
    #  - toolbar button, drop, pasted files: `insert-files` puts placeholders in, with the blobs.
    #  - pasted html holding data urls: `text-change` swaps them for placeholders, with the urls.
    # each item is `{sig, blob}` or `{sig, url}`, `sig` being its placeholder's.
    # an item goes compress -> check terms -> upload -> replace its placeholder by the real url.
    # a failing item drops only its own placeholder.
    ingest = (items = []) ~>
      if !items.length => return Promise.resolve!
      done = mark-pending!
      opts = compress-opts!
      items.for-each (o) -> set-progress o.sig, 0
      ps = items.map (o) ->
        (if o.blob => Promise.resolve(o.blob) else ldfile.fromURL(o.url, \blob).then (r) -> r.file)
          .then (blob) -> if opts.enabled => compress-image blob, opts.pixel, opts.filesize else blob
          .then (blob) -> get-image-meta(blob).then (meta) -> {blob, meta}
          .then ({blob, meta}) -> check-image-terms(meta).then ->
            image-meta[o.sig] = meta
            {blob, sig: o.sig}
          .catch (e) ->
            drop-progress o.sig
            remove-images [o.sig]
            alert e.message or '檔案規格不符'
            null
      Promise.all ps
        .then (list) -> upload-files list.filter(-> it), uploader.insert
        .then ~> @value build-value!
        .catch (e) ~>
          console.error e
          # drop only our own placeholders (matched by sig) so a concurrent batch is untouched.
          remove-images items.map (.sig)
          @value build-value!
          alert e.message or '圖片上傳失敗'
        .finally ->
          items.for-each (o) -> drop-progress o.sig
          done!

    # `range`: where to insert ( `{index, length}`; a selection is replaced ). `files`: File list.
    insert-files = (range, files) ~>
      if @_mode != \edit or !tools!.image => return
      files = Array.from(files or []).filter (f) -> f and f.type in image-types
      if !files.length => return
      Delta = Quill.import \delta
      items = files.map (blob) ->
        placeholder = uploader.placeholder uploader.key!
        {blob, placeholder, sig: uploader.get-sig(placeholder)}
      delta = new Delta!retain(range.index or 0)
      if range.length => delta.delete range.length
      items.for-each (o) -> delta.insert {image: o.placeholder}
      # `user`: it's the user's edit, so it goes into undo history like a typed one.
      quill.updateContents delta, \user
      quill.setSelection (range.index or 0) + items.length, \silent
      ingest items

    # files: [{blob, sig}]. uploaded one by one; `insert` gets the item plus `file`, the server's
    # response for the blob.
    upload-files = (files = [], insert) ~>
      _ = (idx = 0) ~>
        file = files[idx]
        if !file => return Promise.resolve!
        @mod.child._upload {file: file.blob, progress: (p) -> set-progress file.sig, ratio(p)}
          .then (f) ->
            if insert => insert file <<< {file: {} <<< f}
            _(idx + 1)
      _ 0

    # the host's progress object: `{percent}` ( ld$.xhr ) or `{loaded, total}` ( XHR event ).
    ratio = (p = {}) ->
      r = if p.percent? => p.percent else if p.total => p.loaded / p.total else 0
      (r or 0) >? 0 <? 1

    # ---- upload progress -----------------------------------------------------------------------
    # a bar laid over each placeholder. it's an overlay instead of part of the placeholder image:
    # changing the image on every tick would be a document edit each time ( undo history, value ).
    # `lc.progress[sig]`: 0 while compressing or queued ( shown as an indeterminate bar ), then
    # the upload ratio. the bar goes away once its placeholder is replaced.
    lc.progress = {}
    lc.bars = {}
    progress-layer = document.createElement \div
    progress-layer.className = \mf-rt-layer
    quill.container.appendChild progress-layer
    set-progress = (sig, v) -> lc.progress[sig] = v; render-layer!
    drop-progress = (sig) -> delete lc.progress[sig]; render-layer!
    render-progress = ->
      c = quill.container.getBoundingClientRect!
      seen = {}
      Array.from(quill.root.querySelectorAll \img).for-each (img) ->
        src = img.getAttribute \src
        if !uploader.is-placeholder(src) => return
        sig = uploader.get-sig src
        if !((v = lc.progress[sig])?) => return
        seen[sig] = true
        if !(bar = lc.bars[sig]) =>
          bar = lc.bars[sig] = document.createElement \div
          bar.className = \mf-rt-progress
          bar.appendChild document.createElement(\div)
          progress-layer.appendChild bar
        r = img.getBoundingClientRect!
        bar.style <<<
          left: "#{r.left - c.left + 8}px"
          top: "#{r.bottom - c.top - 14}px"
          width: "#{Math.max(r.width - 16, 16)}px"
        bar.classList.toggle \pending, !(v > 0)
        bar.firstChild.style.width = "#{Math.round(v * 100)}%"
      for sig, bar of lc.bars => if !seen[sig] =>
        bar.parentNode.removeChild bar
        delete lc.bars[sig]

    # ---- image resize --------------------------------------------------------------------------
    # click an image to get a frame with a handle at its bottom right corner. drag to resize,
    # double click the handle to go back to the natural size. the width is stored as a percentage
    # of the editor's content width, in the image's `width` attribute ( a format quill's image
    # already has ), so it scales with the page, the fullscreen editor, print and pdf alike.
    resizer = do
      node: document.createElement \div
      handle: document.createElement \div
      label: document.createElement \div
      img: null
    resizer.node.className = \mf-rt-resizer
    resizer.handle.className = \mf-rt-resizer-handle
    resizer.label.className = \mf-rt-resizer-label
    resizer.node.appendChild resizer.handle
    resizer.node.appendChild resizer.label
    progress-layer.appendChild resizer.node
    content-width = ->
      cs = getComputedStyle quill.root
      quill.root.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight)
    render-resizer = ->
      img = resizer.img
      if img and !quill.root.contains(img) => img = resizer.img = null
      resizer.node.style.display = if img => \block else \none
      if !img => return
      c = quill.container.getBoundingClientRect!
      r = img.getBoundingClientRect!
      resizer.node.style <<<
        left: "#{r.left - c.left}px", top: "#{r.top - c.top}px"
        width: "#{r.width}px", height: "#{r.height}px"
      w = img.getAttribute \width
      resizer.label.textContent = if resizer.drag => "#{resizer.drag.pct}%" else (w or '原始大小')
    # positions are read from layout, so batch them into one frame.
    render-layer = ->
      if lc.layer-raf => return
      lc.layer-raf = requestAnimationFrame ->
        lc.layer-raf = null
        render-progress!
        render-resizer!
    select-image = (img) -> resizer.img = img; render-layer!
    quill.root.addEventListener \click, (evt) ->
      img = evt.target
      ok = self._mode == \edit and img.tagName == \IMG and !uploader.is-placeholder(img.getAttribute \src)
      select-image(if ok => img else null)
    # anything other than clicking an image ( typing, clicking elsewhere ) drops the frame.
    quill.root.addEventListener \keydown, -> if resizer.img => select-image null
    document.addEventListener \mousedown, (evt) ->
      if resizer.img and !resizer.node.contains(evt.target) and evt.target != resizer.img => select-image null
    quill.root.addEventListener \scroll, render-layer
    window.addEventListener \resize, render-layer
    resizer.handle.addEventListener \pointerdown, (evt) ->
      if !(img = resizer.img) => return
      evt.preventDefault!
      resizer.handle.setPointerCapture evt.pointerId
      max = content-width!
      w = img.getBoundingClientRect!width
      resizer.drag = {x: evt.clientX, w, max, pct: Math.round(100 * w / max)}
    resizer.handle.addEventListener \pointermove, (evt) ->
      if !((d = resizer.drag) and (img = resizer.img)) => return
      w = (d.w + evt.clientX - d.x) >? 24 <? d.max
      d.pct = Math.round(100 * w / d.max) >? 1
      # preview only. the document changes once, on release.
      img.style.width = "#{d.pct}%"
      render-layer!
    resizer.handle.addEventListener \pointerup, (evt) ->
      if !((d = resizer.drag) and (img = resizer.img)) => return
      resizer.drag = null
      img.style.width = ''
      if !img.getAttribute(\style) => img.removeAttribute \style
      set-image-width img, "#{d.pct}%"
    resizer.handle.addEventListener \dblclick, -> if resizer.img => set-image-width resizer.img, false
    set-image-width = (img, width) ->
      if !(blot = Quill.find img) => return
      quill.formatText quill.getIndex(blot), 1, {width}, \user
      render-layer!

    uploader =
      insert: (o) ~>
        meta = image-meta[o.sig]
        delete image-meta[o.sig]
        # the placeholder may be gone by now - the user can delete it while the upload is in
        # flight. the file itself is already on the server (cleaning that up is the backend's
        # business); what we must not do is re-insert an image the user removed, or keep its
        # meta around for a url nothing references.
        if replace-image(o.sig, o.file.url) and meta => image-meta[o.file.url] = meta
        @value build-value!
        render-layer!

      hash: {}
      # keep `data-mf-ph="1"` as the very first attribute so its base64 encoding is a fixed
      # prefix, letting us tell our own loading placeholder apart from a real data-url image
      # by a plain string compare. this marker is what makes a placeholder recognizable across
      # reloads: it used to be tracked only by an in-memory table, so a placeholder that got
      # saved into the data (user saved mid-upload) was re-uploaded on every reload.
      ph-head: "data:image/svg+xml;base64,"
      ph-mark: "PHN2ZyBkYXRhLW1mLXBoPSIx" # btoa('<svg data-mf-ph="1')
      # placeholders written before the marker existed start straight with `data-key`. they are
      # still out there in stored records, so recognize them too - otherwise they linger in the
      # document as a spinner that never resolves, and can be re-uploaded if the user moves one.
      legacy-ph-mark: "PHN2ZyBkYXRhLWtleT0i" # btoa('<svg data-key="')
      is-placeholder: (url) ->
        u = url or ''
        if u.indexOf(uploader.ph-head) != 0 => return false
        rest = u.substring uploader.ph-head.length
        rest.indexOf(uploader.ph-mark) == 0 or rest.indexOf(uploader.legacy-ph-mark) == 0
      placeholder: (key) ->
        uploader.ph-head + btoa("""<svg data-mf-ph="1" data-key="#key" #{uploader.loader}""")
      need-upload: (url = "") -> !!(/^data:image/.exec(url) and !uploader.is-placeholder(url))
      get-sig: (url) ->
        u = url or ''
        if !uploader.is-placeholder(u) => return u.substring(0,64)
        # decode just the head and pull `data-key` out: the attributes before it already fill
        # a 64-char window, so a plain substring would give every placeholder the same sig.
        b64 = u.substring(uploader.ph-head.length, uploader.ph-head.length + 120)
        head = atob b64.substring(0, b64.length - (b64.length % 4))
        "ph:" + ((/data-key="([^"]*)"/.exec(head) or [])[1] or '')
      key: -> "#{Date.now!}-#{Math.random!toString(36)substring(2)}"
      # omit heading `<svg` so we can append attrs easily.
      loader: '''xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid" width="96" height="96" style="background:#fafafa"><g><circle stroke-dasharray="131.95 45.98" r="28" stroke-width="8" stroke="#d7d7d7" fill="none" cy="50" cx="50"><animateTransform keyTimes="0;1" values="0 50 50;360 50 50" dur="1s" repeatCount="indefinite" type="rotate" attributeName="transform"></animateTransform></circle></g></svg>'''
    quill.on \text-change, (d, od, src) ~>
      if @_mode != \edit => return
      @value build-value!
      view.render <[remains]>
      render-layer!
      # only a user edit (typing / pasting / dropping) may start an upload. other sources are
      # our own bookkeeping (see the silent setContents calls) or programmatic updates.
      if src != \user => return
      # a pasted html can carry images as data urls. swap them for placeholders right away -
      # after this tick, so quill is done with the paste - and send them down the pipeline.
      hash = {}
      list = d.ops
        .filter (o) -> uploader.need-upload (o.insert or {}).image
        .map (o) ->
          url = o.insert.image
          placeholder = uploader.placeholder uploader.key!
          hash[url] = {sig: uploader.get-sig(placeholder), url, placeholder}
      if !list.length => return
      done = mark-pending!
      <~ debounce 0 .then _
      patch-images(
        (url) -> !!hash[url]
        (delta, op) -> delta.delete(1).insert({image: hash[op.insert.image].placeholder}, op.attributes)
      )
      ingest(list).finally done

    node = root.querySelector('.ql-color')
    lc.ldcp = new ldcolorpicker(
      node,
      className: "round shadow-sm round flat compact-palette no-empty-color vertical"
      palette: <[#ff0a0a #ff7d0a #ffdb06 #0a9f74 #0067ad #6e20bd #222 #eee]>
      idx: 0
      context: 'richtext'
      exclusive: true
    )
    lc.ldcp.on \change, (v) ~> if quill.get-selection! => quill.format \color, ldcolor.web(v)

  render: -> if @mod.child.view => @mod.child.view.render!
  is-empty: (v) ->
    v = @content(v)
    if (typeof(v) == \undefined) or v == null => return true
    if (v.text or '').trim! => return false
    # `text` never contains embeds, so a field holding only pictures looks empty by text alone.
    # that made a required image-only field report `required`, and worse: `is-equal` treats two
    # empty values as identical, so such a value was never even stored.
    !((v.json or {}).ops or []).some (op) -> (op.insert or {}).image?
  is-equal: (u, v) ->
    eu = @is-empty u
    ev = @is-empty v
    if eu xor ev => return false
    if eu and ev => return true
    return JSON.stringify(u) == JSON.stringify(v)
  # a non-empty error list puts the widget in status 2, which
  #   - blocks submit (@grantdash/prj.tdb checks formmgr.status! before submitting)
  #   - keeps the widget in the invalid list, so the `check` action can jump to it
  #   - surfaces the message through @makeform/common's error block
  # local save doesn't check status, so a draft can still be saved while uploading.
  validate: -> if (@mod.child or {}).uploading => ["image-uploading"] else []
  content: (v) -> v or {json: {}, text: ""}
  adapt: (opt) ->
    @mod.child._upload = opt.upload
    @render!
  opsets: [
  * id: "richtext"
    i18n: {}
    convert: (v) -> return v
    ops: do
      "image-count":
        func: (v, c = {}) ->
          list = ((v.json or {}).ops or []).filter -> it.insert and it.insert.image
          if c.min? => if list.length < c.min => return false
          if c.max? => if list.length > c.max => return false
          return true
        config:
          min: {type: \number, hint: "minimal image count"}
          max: {type: \number, hint: "maximal image count"}
      "text-length":
        func: (v, c = {}) ->
          t = (v.text or '').trim!
          len = word-len t, c.method
          if c.min? => if len < c.min => return false
          if c.max? => if len > c.max => return false
          return true
        config:
          min: {type: \number, hint: "minimal char count"}
          max: {type: \number, hint: "maximal char count"}
          method: type: \choice, default: \char, values: <[char simple-word]>
      "file-size":
        func: (v = {}, c = {}) ->
          imgs = if Array.isArray(v) => v else (v?.images or [])
          !imgs.filter(->
            kb = it.size / 1024
            (c.min? and kb < c.min) or (c.max? and kb > c.max)
          ).length
        config:
          min: {type: \number, name: 'min-size', hint: "minimal file size in KB"}
          max: {type: \number, name: 'max-size', hint: "maximal file size in KB"}
      "long-side": dim-op \long
      "short-side": dim-op \short
      "width": dim-op \width
      "height": dim-op \height
      "pixel-count": dim-op \pixels
  ]

dim-op = (k) ->
  func: (v = {}, c = {}) ->
    imgs = if Array.isArray(v) => v else (v?.images or [])
    !imgs.filter(->!((!c.min? or it[k] >= (c.min or 0)) and (!c.max? or it[k] <= c.max))).length
  config:
    min: {type: \number, name: 'min-size', hint: "minimal size"}
    max: {type: \number, name: 'max-size', hint: "maximal size"}
