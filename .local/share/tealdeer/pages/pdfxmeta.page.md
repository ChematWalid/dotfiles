# pdfxmeta

> Extract font, position, and layout metadata from a PDF file to assist pdftocgen recipe creation.

- Extract layout metadata from the entire PDF:
  `pdfxmeta {{document.pdf}}`

- Extract metadata from specific pages:
  `pdfxmeta -p {{1,2,3}} {{document.pdf}}`
