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
        "image-uploading": "圖片上傳中，請稍候。"
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
    # quill has XSS issues in <= 2.0.3; we hotfix in forked module
    * name: \@plotdb/quill, version: \main, path: \dist/quill.js
    * name: "dompurify", version: \main, path: \dist/purify.min.js
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
  {ldview, Quill, ldcolor, ldcolorpicker, ldfile, DOMPurify} = ctx
  image-meta = {}
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
      quill.setContents json, \silent
      view.render <[remains]>
      # write the cleaned document back, so such a record is repaired on its next save rather
      # than carrying the dead placeholder until the user happens to edit the field.
      if dropped => @value build-value!
    lc.view = view = new ldview do
      root: root
      handler:
        content: ({node}) -> node.innerHTML = DOMPurify.sanitize quill.root.innerHTML
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
                files = input.files
                if !(files and files.length) => return
                file = files.0
                input.value = null
                sel = quill.getSelection!index
                opts = compress-opts!
                done = mark-pending!
                (if opts.enabled => compress-image(file, opts.pixel, opts.filesize) else Promise.resolve(file))
                  .then (blob) -> get-image-meta(blob).then (meta) -> {blob, meta}
                  .then ({blob, meta}) -> check-image-terms(meta).then -> {blob, meta}
                  .then ({blob, meta}) ->
                    key = uploader.key!
                    placeholder = uploader.placeholder key
                    sig = uploader.get-sig(placeholder)
                    image-meta[sig] = meta
                    quill.insertEmbed sel, \image, placeholder
                    upload-files([{blob, sig}], uploader.insert)
                  .catch (e) -> alert e.message or '檔案規格不符'
                  .finally done
              input.click!

    # view mode must be inert: not editable, thus no text-change, thus no upload.
    sync-mode = ~> quill.enable @_mode == \edit
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
      json: json
      text: quill.getText!
      html: DOMPurify.sanitize node.innerHTML
      images: build-images!

    #files contains object {file, ...} where
    #  - `blob`: the file blob
    #  - `...`: additional info which will be passed to `insert`.
    # `insert` accepts that same object plus `file`: the server's response for the blob.
    upload-files = (files = [], insert) ~>
      _ = (idx = 0) ~>
        file = files[idx]
        if !file => return Promise.resolve!
        @mod.child._upload {file: file.blob, progress}
          .then (f) ->
            if insert => insert file <<< {file: {} <<< f}
            _(idx + 1)
      done = mark-pending!
      (_ 0).finally done

    convert-images = (list) ->
      opts = compress-opts!
      ps = list.map (o) ->
        ldfile.fromURL o.image, \blob
          .then (r) ->
            if opts.enabled => compress-image r.file, opts.pixel, opts.filesize
            else Promise.resolve r.file
          .then (blob) -> get-image-meta(blob).then (meta) -> {blob, meta}
          .then ({blob, meta}) ->
            check-image-terms(meta)
              .then ->
                image-meta[o.sig] = meta
                {blob, sig: o.sig}
              .catch (e) ->
                remove-images [o.sig]
                alert e.message or '檔案規格不符'
                null
      Promise.all(ps).then (list) -> list.filter -> it

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
      # only a user edit (typing / pasting / dropping) may start an upload. other sources are
      # our own bookkeeping (see the silent setContents calls) or programmatic updates.
      if src != \user => return
      hash = {}
      list = d.ops
        .filter (o) -> uploader.need-upload (o.insert or {}).image
        .map (o) ->
          key = uploader.key!
          image = o.insert.image
          placeholder = uploader.placeholder key
          sig = uploader.get-sig(placeholder)
          hash[image] = {sig, image, placeholder}
      if !list.length => return
      done = mark-pending!
      <~ debounce 0 .then _
      patch-images(
        (url) -> !!hash[url]
        (delta, op) -> delta.delete(1).insert({image: hash[op.insert.image].placeholder}, op.attributes)
      )

      convert-images list
        .then (list) ~> upload-files list, uploader.insert
        .then ~> @value build-value!
        .catch (e) ~>
          console.error e
          # drop only our own placeholders (matched by sig) so a concurrent batch is untouched.
          remove-images list.map (.sig)
          @value build-value!
          alert e.message or '圖片上傳失敗'
        .finally done

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
