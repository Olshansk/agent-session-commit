# Email HTML Compatibility Reference <!-- omit in toc -->

Cross-client rules for generating email-safe HTML.
Every element must use inline styles.
Layout must use tables, not divs.

- [Document Structure](#document-structure)
- [Preheader Text](#preheader-text)
- [Layout Rules](#layout-rules)
- [Typography](#typography)
- [Client-Specific Quirks](#client-specific-quirks)
- [Image Rules](#image-rules)
- [Link Styling](#link-styling)
- [Bulletproof Buttons](#bulletproof-buttons)
- [Lists](#lists)
- [Code Blocks](#code-blocks)
- [Blockquotes](#blockquotes)
- [Horizontal Rules](#horizontal-rules)
- [Responsive Email](#responsive-email)
- [Dark Mode](#dark-mode)
- [Things That Break](#things-that-break)

## Document Structure

```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="color-scheme" content="light dark">
  <meta name="supported-color-schemes" content="light dark">
  <title>{{subject}}</title>
  <!--[if mso]>
  <noscript>
    <xml>
      <o:OfficeDocumentSettings>
        <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
  </noscript>
  <![endif]-->
  <style>
    /* Only place <style> is allowed — inside <head> */
    /* Used for responsive @media queries and dark mode */
    body { margin: 0; padding: 0; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table { border-collapse: collapse; mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
    img { border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; }

    @media only screen and (max-width: 620px) {
      .email-container { width: 100% !important; max-width: 100% !important; }
      .fluid { width: 100% !important; max-width: 100% !important; height: auto !important; }
      .stack-column { display: block !important; width: 100% !important; }
      .center-on-narrow { text-align: center !important; display: block !important; margin-left: auto !important; margin-right: auto !important; float: none !important; }
      .padding-mobile { padding-left: 16px !important; padding-right: 16px !important; }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; background-color: {{background-color}}; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%;">
  <!-- PREHEADER (see below) -->
  <!-- WRAPPER TABLE (see Layout Rules) -->
</body>
</html>
```

## Preheader Text

Hidden text that appears in inbox preview but not in the email body:

```html
<div style="display: none; font-size: 1px; line-height: 1px; max-height: 0px; max-width: 0px; opacity: 0; overflow: hidden; mso-hide: all;">
  {{preheader}}
  <!-- Fill remaining preview space with invisible characters to prevent body text leaking in -->
  &zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;
</div>
```

## Layout Rules

- Outer wrapper: 100% width table, `role="presentation"`, `cellpadding="0"`, `cellspacing="0"`, `border="0"`
- Inner content: fixed width via `width` attribute AND `style="max-width: {{content-width}}"`
- Center tables with `align="center"` (not just CSS `margin: auto`)
- Use `valign="top"` on all `<td>` elements
- Vertical spacing: use `<td>` with explicit `height` and `font-size: 0; line-height: 0;` (not margin on tables)
- Never use `<div>` for structural layout — always `<table><tr><td>`
- Every table needs: `role="presentation"`, `cellpadding="0"`, `cellspacing="0"`, `border="0"`

**Outlook max-width fix:**

Outlook ignores `max-width`. Wrap the content table in conditional comments:

```html
<!--[if mso]>
<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="{{content-width-number}}">
<tr><td>
<![endif]-->
<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="max-width: {{content-width}}; margin: 0 auto;" class="email-container">
  <!-- content rows here -->
</table>
<!--[if mso]>
</td></tr>
</table>
<![endif]-->
```

## Typography

**Safe font stacks (pick one):**
- `Arial, Helvetica, sans-serif` (default, most universal)
- `Georgia, 'Times New Roman', Times, serif`
- `'Courier New', Courier, monospace` (code)
- `Verdana, Geneva, sans-serif`

**Rules:**
- Minimum body font size: 14px (mobile readability)
- `line-height` must use px values for Outlook (e.g., `line-height: 24px`, not `1.6`)
- Heading sizes: h1=28px, h2=22px, h3=18px, h4=16px
- Always set `color` explicitly on every text element
- Add `-webkit-text-size-adjust: 100%` and `-ms-text-size-adjust: 100%` on `<body>`
- No Google Fonts in body text — only system/web-safe fonts
- `font-weight` is safe to use (`bold`, `normal`, `600`, etc.)

## Client-Specific Quirks

### Gmail
- Strips ALL `<style>` blocks in `<body>` — only `<head>` styles survive
- Strips class names and rewrites IDs with prefix
- Converts some block-level tags to `<div>`
- Inline styles on every element are mandatory
- Does not support `background-image` on `<body>`

### Outlook (Windows / MSO)
- Uses Microsoft Word rendering engine (not a browser)
- Does NOT support: `max-width`, `background-image` on `<td>` (use VML), `border-radius`, `CSS float`, `padding` on `<p>` tags
- `line-height` needs explicit px (not unitless or em)
- Use conditional comments `<!--[if mso]>` for Outlook-specific code
- `<table>` width must be set via `width` attribute, not just CSS
- `mso-padding-alt` can substitute for padding issues
- `mso-line-height-rule: exactly` forces line-height compliance

### Apple Mail / iOS Mail
- Best rendering support of all clients
- Honors most CSS properties including `border-radius`, `background-image`
- Good dark mode support with `@media (prefers-color-scheme: dark)`
- Supports `<style>` in `<head>` reliably

### Yahoo Mail
- Strips some inline styles unpredictably
- Prefixes class names with `yiv` internally
- Generally decent rendering but test carefully

## Image Rules

- Always set: `width`, `height`, `alt`, `border="0"`, `style="display: block;"`
- Use absolute URLs (fully qualified `https://`)
- Max display width: match `content-width` (typically 600px)
- For retina: serve 2x resolution images, display at 1x via `width` attribute
- Add `style="display: block; outline: none; border: none; text-decoration: none;"`
- Background images: use VML for Outlook support (complex, avoid unless necessary)

```html
<img src="{{url}}" alt="{{alt}}" width="{{width}}" height="{{height}}"
     style="display: block; border: 0; outline: none; text-decoration: none;"
     border="0">
```

## Link Styling

- Always set `color` and `text-decoration` inline on every `<a>` tag
- Gmail may override link colors — use inline styles to fight this
- Add `target="_blank"` for webmail clients

```html
<a href="{{url}}" style="color: {{brand-color}}; text-decoration: underline;" target="_blank">{{text}}</a>
```

## Bulletproof Buttons

Use `<a>` tags with inline styles, NOT `<button>` elements.

**Simple button (works everywhere except Outlook border-radius):**

```html
<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center">
  <tr>
    <td style="border-radius: 6px; background-color: {{brand-color}};">
      <a href="{{url}}" target="_blank"
         style="display: inline-block; padding: 14px 28px; font-family: {{font-family}}; font-size: 16px; font-weight: bold; color: #ffffff; text-decoration: none; border-radius: 6px; background-color: {{brand-color}};">
        {{button-text}}
      </a>
    </td>
  </tr>
</table>
```

**Bulletproof button with VML fallback (Outlook support for rounded corners):**

```html
<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center">
  <tr>
    <td>
      <!--[if mso]>
      <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word"
        href="{{url}}" style="height:48px;v-text-anchor:middle;width:200px;" arcsize="12%" strokecolor="{{brand-color}}" fillcolor="{{brand-color}}">
        <w:anchorlock/>
        <center style="color:#ffffff;font-family:{{font-family}};font-size:16px;font-weight:bold;">{{button-text}}</center>
      </v:roundrect>
      <![endif]-->
      <!--[if !mso]><!-->
      <a href="{{url}}" target="_blank"
         style="display: inline-block; padding: 14px 28px; font-family: {{font-family}}; font-size: 16px; font-weight: bold; color: #ffffff; text-decoration: none; border-radius: 6px; background-color: {{brand-color}};">
        {{button-text}}
      </a>
      <!--<![endif]-->
    </td>
  </tr>
</table>
```

## Lists

- `<ul>` and `<ol>` generally render well but need inline styling
- Outlook needs `style="margin: 0; padding: 0 0 0 24px;"` on the list element
- Add `mso-special-format: bullet` for Outlook bullet rendering
- Set `color` and `font-size` on each `<li>`

```html
<ul style="margin: 0; padding: 0 0 0 24px; font-family: {{font-family}}; font-size: {{font-size}}; color: {{body-color}}; line-height: 26px;">
  <li style="margin-bottom: 8px; padding-left: 4px;">{{item}}</li>
</ul>
```

## Code Blocks

**Inline code:**

```html
<code style="background-color: #f1f1f1; padding: 2px 6px; border-radius: 3px; font-family: 'Courier New', Courier, monospace; font-size: 14px; color: #d63384;">{{code}}</code>
```

**Code block:**

```html
<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
  <tr>
    <td style="background-color: #1e1e1e; padding: 16px; border-radius: 6px;">
      <pre style="margin: 0; font-family: 'Courier New', Courier, monospace; font-size: 13px; line-height: 20px; color: #d4d4d4; white-space: pre-wrap; word-wrap: break-word;">{{code}}</pre>
    </td>
  </tr>
</table>
```

## Blockquotes

```html
<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
  <tr>
    <td style="border-left: 4px solid {{brand-color}}; padding: 12px 16px; background-color: #f8f9fa;">
      <p style="margin: 0; font-family: {{font-family}}; font-size: {{font-size}}; line-height: 26px; color: #555555; font-style: italic;">
        {{quote}}
      </p>
    </td>
  </tr>
</table>
```

## Horizontal Rules

```html
<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
  <tr>
    <td style="padding: 20px 0;">
      <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
        <tr>
          <td style="border-top: 1px solid #e0e0e0; font-size: 0; line-height: 0;">&nbsp;</td>
        </tr>
      </table>
    </td>
  </tr>
</table>
```

## Responsive Email

- `@media` queries ONLY work inside `<style>` in `<head>` (never inline)
- Use `width: 100% !important` overrides for mobile
- Stack columns: `display: block !important; width: 100% !important;` on `<td>`
- Hide elements: `display: none !important`
- Breakpoint: typically `max-width: 620px` (content-width + 20px padding)
- Add class hooks on elements for responsive overrides (e.g., `class="email-container"`, `class="stack-column"`)

## Dark Mode

- Set `<meta name="color-scheme" content="light dark">` in `<head>`
- Set `<meta name="supported-color-schemes" content="light dark">` in `<head>`
- Add `@media (prefers-color-scheme: dark)` rules in `<head>` `<style>`
- Use transparent PNGs where possible (avoid white backgrounds baked into images)
- Dark mode inverts: background goes dark, text goes light
- Some clients (Outlook, older Gmail) ignore dark mode entirely — ensure light theme is always readable

## Things That Break

Never use these in email HTML:

| Feature | Why |
|---|---|
| `position: absolute/relative/fixed` | Ignored or breaks layout |
| `display: flex` / `display: grid` | No email client support |
| `float` | Inconsistent across clients |
| CSS variables (`var()`) | Not supported |
| `<video>` / `<audio>` / `<iframe>` | Blocked by most clients |
| `<form>` / `<input>` / `<button>` | Stripped or non-functional |
| JavaScript | Always blocked |
| External stylesheets (`<link>`) | Stripped |
| `<style>` in `<body>` | Gmail strips it |
| CSS shorthand (`background:`) | Outlook may ignore parts |
| `margin` on `<table>` | Use `align="center"` instead |
| SVG (`<svg>`) | Inconsistent, use PNG/GIF |
| `calc()` | Not supported |
| `rem` / `vh` / `vw` units | Use `px` only |
