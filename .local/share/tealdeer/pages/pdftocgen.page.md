# pdftocgen

> Automatically generate table of contents for PDF documents using font/layout recipe matching.
> More information: <https://krasjet.com/tools/pdf-tocgen/>.

- Generate TOC recipe from document heading patterns:
  `pdftocgen {{document.pdf}} < {{recipe.toml}}`

- Extract font and styling metadata from PDF:
  `pdfxmeta {{document.pdf}}`
