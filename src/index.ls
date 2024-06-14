module.exports =
  pkg:
    name: "@makeform/richtext", extend: {name: "@makeform/common"}
    i18n:
      en: {}
      "zh-TW": {}
    dependencies: [
    * url: \https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.snow.css, type: \css, global: true
    * url: \https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.js
    * name: "ldcolor", version: "main", path: "index.min.js", async: false
    * name: "@loadingio/ldcolorpicker", version: "main", path: "index.min.js"
    * name: "@loadingio/ldcolorpicker", version: "main", path: "index.min.css", global: true
    ]
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)
mod = ({root, ctx, data, parent, t}) ->
  {ldview, Quill, ldcolor, ldcolorpicker} = ctx
  init: ->
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
                _ = (idx) ~>
                  file = files[idx]
                  if !file => return Promise.resolve!
                  #_uploading true, 0
                  @mod.child._upload {file, progress}
                    .then (f) ->
                      f = [{} <<< f <<< {blob: file}]
                      (if ext.detail => ext.detail(f) else Promise.resolve f)
                    .then (f) ->
                      f = f.0
                      delete f.blob
                      if !lc.file => lc.file = []
                      else if !Array.isArray(lc.file) => lc.file = [lc.file]
                      lc.file.push f
                      range = quill.getSelection!
                      quill.insertEmbed range.index, \image, f.url
                      _(idx + 1)
                _(0)
              input.click!

    quill.on \text-change, (d, od, src) ~>
      text = quill.getText!
      json = quill.getContents!
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
