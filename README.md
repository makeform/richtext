# @makeform/richtext

Richtext input widget. Based on Quilljs.


## Config

 - `hint`: an object controlling the character count hint display.
   - `enabled`: boolean, default `false`. when `true`, shows a small hint below the editor indicating how many characters remain or have been written, based on any active `text-length` term.
 - `image`: an object controlling image handling behavior.
   - `compress`: an object controlling image compression before upload. when omitted entirely, compression is enabled with default values.
     - `enabled`: boolean, default `true`. when `false`, disables compression and uploads images as-is.
     - `pixel`: number, default `1200`. maximum width or height in pixels. images exceeding this are scaled down proportionally.
     - `filesize`: number, default `500`. maximum file size in KB after compression. quality is reduced via binary search until the image fits within this limit.


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
