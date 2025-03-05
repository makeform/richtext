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

module.exports =
  pkg:
    name: "@makeform/richtext", extend: {name: "@makeform/common"}
    i18n:
      en: {}
      "zh-TW": {}
    dependencies: [
    # quilljs uses css such as @support which isn't handled correctly by csscope.
    # this leads to incorrect list numbering (requires correct counter-reset style to solve)
    # which leads to separated list numbered as a single one.
    # before we fix this issue in csscope, we resolve this problem programmatically.
    * url: \https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.js
    * name: "ldcolor", version: "main", path: "index.min.js", async: false
    * name: "@loadingio/ldcolorpicker", version: "main", path: "index.min.js"
    * name: "@loadingio/ldcolorpicker", version: "main", path: "index.min.css", global: true
    * name: \ldfile
    ]
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)
mod = ({root, ctx, data, parent, t}) ->
  {ldview, Quill, ldcolor, ldcolorpicker, ldfile} = ctx
  init: ->
    # workaround: @plotdb/csscope doesn't inject quill-css correctly so we do it here manually.
    if !quill-css.node =>
      quill-css.node = link = document.createElement \link
      link.setAttribute \rel, \stylesheet
      link.setAttribute \href, \https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.snow.css
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
      handler: content: ({node}) -> node.innerHTML = quill.root.innerHTML
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
                files = [files.0]
                input.value = null
                key = uploader.key!
                placeholder = "data:image/svg+xml;base64," + btoa("""<svg data-key="#key" #{uploader.loader}""")
                sig = uploader.get-sig(placeholder)
                uploader.sig[sig] = true
                quill.insertEmbed quill.getSelection!index, \image, placeholder
                upload-files(files.map((blob)->{blob, sig}), uploader.insert)
              input.click!

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
      ps = list.map (o) ->
        (r) <- ldfile.fromURL o.image, \blob .then _
        {blob: r.file, sig: o.sig}
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
    return (typeof(v) == \undefined) or v == null or !v.text
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
