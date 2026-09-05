# Change Logs

## v0.5.3

 - treat content holding only images as non-empty: a required image-only field no longer
   reports `required`, and such a value is now stored at all


## v0.5.2

 - fix: no longer drop placeholders of in-flight uploads when the value is written back
 - flag the widget as busy for the whole image pipeline, not just the upload itself
 - recognize placeholders written before the marker existed, and clean them out on load
 - write the cleaned document back so such a record is repaired on its next save


## v0.5.1

 - patch image embeds with a delta instead of rebuilding the document with setContents
 - keep an uploaded image out of the content if its placeholder was deleted mid-upload
 - drop dead `lc.file` / `ext.detail` bookkeeping inherited from @makeform/upload


## v0.5.0

 - mark loading placeholder with `data-mf-ph` so it's never mistaken for a real image to upload
 - identify placeholder by its `data-key` instead of a truncated url, fixing signature collision
 - drop placeholders from stored data on load, and filter them out of the saved value
 - block upload in view mode and for non-user content changes; disable editor outside edit mode
 - report widget as invalid while uploading, so submit is blocked until uploads finish
 - keep caret across the internal setContents calls, and stop losing input typed during upload
 - remove stale placeholders and notify user when an upload fails


## v0.4.7

 - upgrade dependencies


## v0.4.6

 - remove unnecessary log


## v0.4.5

 - sanitize quill html before using dompurify
 - add additional dependencies


## v0.4.4

 - use @plotdb/quill for hotfix of XSS issue found in quill (<=2.0.3)


## v0.4.3

 - add file-size op


## v0.4.2

 - support image ops in richtext opset.


## v0.4.1

 - remove unnecessary log


## v0.4.0

 - support image compression. enabled by default


## v0.3.0

 - support character hint feature
 - fix incorrect description about text-length opset min / max options in README


## v0.2.1

 - use local quill lib


## v0.2.0

 - add host `@grantdash/composer`
 - inline Quill style to prevent it from affecting composer editor


## v0.1.0

 - tweak DOM based on updated `@makeform/common` DOM structure.
 - fix bug: empty test doesn't work for content containing only newline.


## v0.0.8

 - add dedicated `richtext` opset.


## v0.0.7

 - limit image size to maximal 100% width to prevent overflow


## v0.0.6

 - workaround: @plotdb/csscope doesn't load quilljs css correctly. use programmatically approach to workaround.
 - support image insertion by pasting, dragging along with a upload indicator


## v0.0.5

 - use italic style for `em`, and make `strong` bolder than default value.


## v0.0.4

 - set word-break to break-all to prevent content overflow 


## v0.0.3

 - remove color picker


## v0.0.2

 - tweak toolbar alignment
 - add colorpicker
 - support view mode


## v0.0.1

init release
