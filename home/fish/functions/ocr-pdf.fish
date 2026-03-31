function ocr-pdf
  ocrmypdf \
  --rotate-pages \
  --deskew \
  --clean \
  --force-ocr \
  $argv[1] \
  $argv[1]
end
