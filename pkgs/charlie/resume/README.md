# r-sum-

A series of [Pandoc][pandoc] templates that converts a single Markdown resume into an
HTML, PDF, and plaintext resume.

## Usage

1. Install [pandoc][pandoc] and Google Chrome
1. Clone or fork
1. Edit `resume.md`
1. Create `NAME`, `EMAIL`, `PHONE`, and `VERSION`
1. Run `make`

View your freshly built resume in `build/`

## Considerations

Why use Google Chrome for rendering HTML & CSS as a PDF? I tried using a number
of HTML & CSS to PDF renderers, such as the following:

- <https://wkhtmltopdf.org/>
- <https://weasyprint.org/>

And others featured on <https://print-css.rocks/>. I found that most don't
properly support various common CSS features (such as Flexbox). Chrome's
`--headless --disable-gpu --print-to-pdf=FILE --print-to-pdf-no-header`
command-line option does exactly what I need for this project.

## Inspiration

- <https://mszep.github.io/pandoc_resume/>
- <https://resume.chmd.fr/>

[pandoc]: <https://pandoc.org/>
