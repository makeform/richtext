quill-css = {}
console.log \working

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
        config:
          hint: name: 'Character Count Hint', desc: "Show character count and limit hints."
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
        config:
          hint: name: '字數提示', desc: "啟用字數提示"
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
    * name: \quill, version: \main, path: \dist/quill.js
    # or use cdn: https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.js
    * name: "ldcolor", version: "main", path: "index.min.js", async: false
    * name: "@loadingio/ldcolorpicker", version: "main", path: "index.min.js"
    * name: "@loadingio/ldcolorpicker", version: "main", path: "index.min.css", global: true
    * name: \ldfile
    ]
  init: (opt) ->
    opt.pubsub.on \inited, (o = {}) ~> @ <<< o
    opt.pubsub.fire \subinit, mod: mod.call @, opt
  client: (bid) ->
    meta: config:
      hint: enabled: type: \boolean, name: \config.hint.name, desc: \config.hint.desc
      image: compress:
        enabled: type: \boolean, name: \config.image.compress.enabled.name, desc: \config.image.compress.enabled.desc
        filesize: type: \number, name: \config.image.compress.filesize.name, desc: \config.image.compress.filesize.desc
        pixel: type: \number, name: \config.image.compress.pixel.name, desc: \config.image.compress.pixel.desc

mod = ({root, manager, ctx, data, parent, t}) ->
  {ldview, Quill, ldcolor, ldcolorpicker, ldfile} = ctx
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
      j = quill.getContents!
      if JSON.stringify(j) == JSON.stringify(v.json or {}) => return
      quill.setContents(v.json or {})
    lc.view = view = new ldview do
      root: root
      handler:
        content: ({node}) -> node.innerHTML = quill.root.innerHTML
        remains: ({node}) ~>
          enabled = !!(@mod.info.config.hint or {}).enabled
          node.classList.toggle \d-none, !enabled
          if !enabled => return node.textContent = ""
          content = (quill.getText! or '').trim!
          terms = @serialize!term
          ret = hint content, terms, t
          node.textContent = ret.text
          node.classList.toggle \text-danger, !!ret.invalid
    progress = ->
    quill = new Quill view.get(\input), do
      theme: \snow
      modules:
        toolbar:
          container: [
            [{ header: [1, 2, false] }],
            <[bold italic underline]> /* ++ <[color]> */,
            [{list: 'ordered'}, {list: 'bullet'}, {align: []}]
            <[link image]>
          ]
          handlers:
            image: ~>
              input = document.createElement \input
              input.setAttribute \type, \file
              input.setAttribute \accept, 'image/png, image/gif, image/jpeg'
              input.onchange = ~>
                ext = {}
                files = input.files
                if !(files and files.length) => return
                file = files.0
                input.value = null
                key = uploader.key!
                placeholder = "data:image/svg+xml;base64," + btoa("""<svg data-key="#key" #{uploader.loader}""")
                sig = uploader.get-sig(placeholder)
                uploader.sig[sig] = true
                quill.insertEmbed quill.getSelection!index, \image, placeholder
                opts = compress-opts!
                (if opts.enabled => compress-image(file, opts.pixel, opts.filesize) else Promise.resolve(file))
                  .then (blob) ->
                    upload-files([{blob, sig}], uploader.insert)
              input.click!

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

    #files contains object {file, ...} where
    #  - `blob`: the file blob
    #  - `...`: additional info which will be passed to `insert`.
    # `insert` accpets an object with `file`(from server) and `blob` (file object)
    upload-files = (files = [], insert) ~>
      ext = {}
      _ = (idx = 0) ~>
        file = files[idx]
        if !file => return Promise.resolve!
        @mod.child._upload {file: file.blob, progress}
          .then (f) ->
            f = [{} <<< f <<< {blob: file.blob}]
            (if ext.detail => ext.detail(f) else Promise.resolve f)
          .then (f) ->
            f = f.0
            delete f.blob
            if !lc.file => lc.file = []
            else if !Array.isArray(lc.file) => lc.file = [lc.file]
            lc.file.push f
            if insert => insert file <<< {file: f}
            _(idx + 1)
      _ 0

    convert-images = (list) ->
      opts = compress-opts!
      ps = list.map (o) ->
        ldfile.fromURL o.image, \blob
          .then (r) ->
            if opts.enabled => compress-image r.file, opts.pixel, opts.filesize
            else Promise.resolve r.file
          .then (blob) -> {blob, sig: o.sig}
      Promise.all ps

    uploader =
      insert: (o) ~>
        nd = quill.getContents!
        nd.ops
          .filter (op) -> o.sig == uploader.get-sig((op.insert or {}).image)
          .map (op) -> op.insert.image = o.file.url
        quill.setContents nd, \silent
        text = quill.getText!
        html = quill.root.innerHTML
        @value {json: nd, text, html}

      hash: {}
      sig: {}
      need-upload: (url = "") -> !!(/data:image/.exec(url) and !uploader.sig[uploader.get-sig url])
      get-sig: (url) -> (url or '').substring(0,64)
      key: -> "#{Date.now!}-#{Math.random!toString(36)substring(2)}"
      # omit heading `<svg` so we can append attrs easily.
      loader: '''xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid" width="96" height="96" style="background:#fafafa"><g><circle stroke-dasharray="131.95 45.98" r="28" stroke-width="8" stroke="#d7d7d7" fill="none" cy="50" cx="50"><animateTransform keyTimes="0;1" values="0 50 50;360 50 50" dur="1s" repeatCount="indefinite" type="rotate" attributeName="transform"></animateTransform></circle></g></svg>'''
    quill.on \text-change, (d, od, src) ~>
      text = quill.getText!
      json = quill.getContents!
      html = quill.root.innerHTML
      @value {json, text, html}
      view.render <[remains]>
      hash = {}
      list = d.ops
        .filter (o) -> uploader.need-upload (o.insert or {}).image
        .map (o) ->
          key = uploader.key!
          image = o.insert.image
          placeholder = "data:image/svg+xml;base64," + btoa("""<svg data-key="#key" #{uploader.loader}""")
          sig = uploader.get-sig(placeholder)
          uploader.sig[sig] = true
          hash[image] = {sig, image, placeholder}
      if !list.length => return
      nd = quill.getContents!
      nd.ops.map (o) -> if (r = hash[(o.insert or {}).image]) => o.insert.image = r.placeholder
      <~ debounce 0 .then _
      quill.setContents nd, \silent

      convert-images list
        .then (list) ~> upload-files list, uploader.insert
        .then ~>
          json = quill.getContents!
          text = quill.getText!
          html = quill.root.innerHTML
          @value {json, text, html}

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
    return (typeof(v) == \undefined) or v == null or !((v.text or '').trim!)
  is-equal: (u, v) ->
    eu = @is-empty u
    ev = @is-empty v
    if eu xor ev => return false
    if eu and ev => return true
    return JSON.stringify(u) == JSON.stringify(v)
  content: (v) -> v or {json: {}, text: ""}
  adapt: (opt) ->
    @mod.child._upload = opt.upload
    @render!
  opsets: [
  * id: "richtext"
    i18n: {}
    convert: (v) -> return v
    ops:
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
  ]
