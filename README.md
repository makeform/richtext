# @makeform/richtext

Richtext input widget. Based on Quilljs.


## Config

 - `hint`: an object controlling the character count hint display.
   - `enabled`: boolean, default `false`. when `true`, shows a small hint below the editor indicating how many characters remain or have been written, based on any active `text-length` term.
 - `preset`: which tools the editor offers. default `basic`.
   - `minimal`: bold, italic, underline, lists, link.
   - `basic`: header, bold, italic, underline, lists, align, link, image, table, fullscreen.
   - `full`: `basic` plus strike, text color and blockquote; the table menu adds freeze rows / columns, caption, header cells and width switch.
 - `tools`: turn single tools on / off on top of the preset, e.g. `{table: false, color: true}`.
   - tools: `header bold italic underline strike color list align blockquote link image table fullscreen`.
   - this only shows / hides toolbar buttons: shortcuts and pasted content still bring any format in, so stored values keep what they have.
     with `image` off, dropped / pasted image files are ignored.
 - `strict`: boolean, default `false`. limit the formats to the enabled tools: pasted formats outside them are dropped,
   and so are such formats in stored values when loaded. read once, at init.
 - `table`: an object controlling tables.
   - `enabled`: boolean. older switch for `tools.table` ( `tools` wins ).
   - `menu`: items of the table's context menu: `basic`, `full` ( default from the preset ), or a list of names from
     quill-table-up's `tableMenuTools` ( `Break` is a divider ). read once, at init.
   - the table engine is loaded either way: pasted tables stay tables, and stored ones stay editable when the button is off.
 - `fullscreen`: an object. `enabled`: older switch for `tools.fullscreen` ( `tools` wins ).
 - `image`: an object controlling image handling behavior.
   - `compress`: an object controlling image compression before upload. when omitted entirely, compression is enabled with default values.
     - `enabled`: boolean, default `true`. when `false`, disables compression and uploads images as-is.
     - `pixel`: number, default `1200`. maximum width or height in pixels. images exceeding this are scaled down proportionally.
     - `filesize`: number, default `500`. maximum file size in KB after compression. quality is reduced via binary search until the image fits within this limit.


## Value

`{json, text, html, images, table}`:

 - `json`: quill delta. `text`: plain text. `html`: sanitized html. `images`: meta of uploaded images.
 - `table`: id of the table engine that wrote the tables in `json` ( e.g. `table-up@3` ). only present when there is a table.
   - table engines keep tables in their own delta formats, which other engines can't read. a value written by another engine
     ( or holding tables while this build has none ) is loaded from `html` instead, and saved in the current format on the next edit.
     cells, merged cells and text convert well this way; column widths may not.
   - the engine is chosen in code ( `table-engine` in `src/index.ls` ); currently `quill-table-up`.

Images: click one to resize it by the handle at its bottom right ( double click the handle to reset ). the width is kept as a percentage in the image's `width` attribute.


## Opset

this widget provides one additional opset `richtext` with following 2 ops:

 - `image-count`: limit how many images users can insert in this widget.
   - config:
     - `min`: number, minimal image count
     - `max`: number, maximal image count
 - `text-length`: limit text length
   - config:
     - `min`: number, minimal char/word count
     - `max`: number, maximal char/word count
     - `method`: string, default `char`. can be either `char` or `simple-word`.
       - `char`: counts every character
       - `simple-word`: counts words, splitting on whitespace and punctuation, with CJK characters each counted individually


## License

@makeform/richtext is released under MIT License.
QuillJS 2.0.2 is released under BSD-3 License. see LICENSE.Quill for more information.
