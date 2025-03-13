# @makeform/richtext

Richtext input widget. Based on Quilljs.


## Config


## Opset

this widget provides one additional opset `richtext` with following 2 ops:

 - `image-count`: limit how many images users can insert in this widget.
   - config:
     - `min`: number, minimal image count
     - `max`: number, maximal image count
 - `text-length`: limit text length
   - config:
     - `min`: number, minimal image count
     - `max`: number, maximal image count
     - `method: string, default `char`. can be either `char` or `simple-word`.
       - length calculation will be based on character count if set to `char`.
         when `simple-word` is used, it will try to count by words (ignoring space, punctuations, etc)


## License

MIT
