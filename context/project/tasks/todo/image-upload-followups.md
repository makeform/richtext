# richtext 圖片上傳 — 後續項目

v0.5.0 修完 placeholder 重傳、送件擋制、游標／lost update 之後，剩下這些已知但當時
判斷「先不動」的項目。共同背景見 `src/index.ls` 的 `uploader` / `upload-files` /
`build-value` 一帶。


## 上傳是序列的，多張圖等待時間線性累加

`upload-files` 用遞迴 `_(idx + 1)` 一張做完才做下一張。貼 10 張圖就是 10 倍等待，
而這段期間 widget 是 status 2，整份表單都送不出去。

改成併發不難，但會動到兩個假設：

 - `insert` 目前依序被呼叫，併發後完成順序不固定。實際上 `replace-image` 是用 sig
   比對而非位置，所以順序本來就不影響正確性 —— 但要確認沒有其他地方依賴它。
 - 失敗處理現在是「一張失敗就整批 reject，`remove-images` 清掉整批 placeholder」。
   併發後應該改成逐張處理成敗，只清掉失敗的那張。

要做的話順帶想一下要不要限制併發數（後端可能不喜歡一次收 10 個 POST）。


## 貼上瞬間 value 裡是原始 base64

`text-change` 的順序是「先 `@value build-value!`，之後才在 `debounce 0` 後把 data url
換成 placeholder」。中間那一個 tick，value 裡是使用者貼上的原始 base64。

目前不影響，因為 grantdash 的存檔要使用者主動按按鈕，不可能剛好落在那一個 tick 內；
就算真的存進去了，下次載入會被 `need-upload` 偵測、上傳、替換掉，所以會自癒。

**但如果之後改成自動存檔 / 即時同步（協作、定期回填），這就會變成真的問題**：
base64 會被寫進 DB，而且每次自動存檔都可能抓到不同的中間狀態。

真要修的話，把 `@value build-value!` 也移到 `debounce 0` 之後即可，代價是所有文字編輯
的 value 更新都延後一個 tick。或者讓 `build-value` 濾掉尚未處理的 data url —— 但那會
讓「貼上後、上傳失敗」的圖完全不出現在 value 裡，要一併想清楚。

相關：同一個架構變動也會讓 `@on \change` 的問題浮現 —— 外部推值時會把上傳中的
placeholder 洗掉，上傳完成後 `replace-image` 找不到目標，圖靜默消失。目前只有初次載入
和 `_grantdashimporter` 會推值，所以碰不到。
