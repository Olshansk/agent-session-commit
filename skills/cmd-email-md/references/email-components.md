# Email Component Templates <!-- omit in toc -->

Reusable HTML snippets for email generation.
All use `{{variable}}` placeholders that map to frontmatter fields.

- [Complete Wrapper](#complete-wrapper)
- [Content Row](#content-row)
- [Spacer](#spacer)
- [Header with Logo](#header-with-logo)
- [Hero Section](#hero-section)
- [Heading](#heading)
- [Paragraph](#paragraph)
- [Unordered List](#unordered-list)
- [Ordered List](#ordered-list)
- [Task List](#task-list)
- [Blockquote](#blockquote)
- [Callout Box](#callout-box)
- [Code Block](#code-block)
- [Inline Code](#inline-code)
- [Image](#image)
- [CTA Button](#cta-button)
- [Two Buttons Side by Side](#two-buttons-side-by-side)
- [Horizontal Rule](#horizontal-rule)
- [Centered Text](#centered-text)
- [Footer](#footer)

## Complete Wrapper

The outermost structure that wraps all email content:

```html
<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%"
       style="background-color: {{background-color}};">
  <tr>
    <td align="center" style="padding: 20px 10px;">
      <!--[if mso]>
      <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="{{content-width-number}}">
      <tr><td>
      <![endif]-->
      <table role="presentation" cellpadding="0" cellspacing="0" border="0"
             width="{{content-width-number}}" class="email-container"
             style="max-width: {{content-width}}; margin: 0 auto; background-color: {{content-background}};">
        <!-- ALL CONTENT ROWS GO HERE -->
      </table>
      <!--[if mso]>
      </td></tr>
      </table>
      <![endif]-->
    </td>
  </tr>
</table>
```

## Content Row

Standard wrapper for any content block inside the email container:

```html
<tr>
  <td style="padding: 0 32px;" class="padding-mobile">
    <!-- content element here -->
  </td>
</tr>
```

## Spacer

Vertical spacing between sections:

```html
<tr>
  <td style="height: {{height}}px; font-size: 0; line-height: 0;">&nbsp;</td>
</tr>
```

Default heights: small=12px, medium=24px, large=40px.

## Header with Logo

```html
<tr>
  <td style="padding: 24px 32px; text-align: center;" class="padding-mobile">
    <img src="{{header-logo}}" alt="{{brand-name}}" width="150"
         style="display: block; margin: 0 auto; border: 0; outline: none;">
  </td>
</tr>
```

## Hero Section

Full-width hero with background color, heading, and optional subtitle:

```html
<tr>
  <td style="background-color: {{brand-color}}; padding: 48px 32px; text-align: center;" class="padding-mobile">
    <h1 style="margin: 0 0 12px 0; font-family: {{font-family}}; font-size: 32px; line-height: 40px; font-weight: bold; color: #ffffff;">
      {{hero-title}}
    </h1>
    <p style="margin: 0; font-family: {{font-family}}; font-size: 18px; line-height: 28px; color: rgba(255,255,255,0.9);">
      {{hero-subtitle}}
    </p>
  </td>
</tr>
```

## Heading

Adapt `font-size` and `line-height` per level:

| Level | font-size | line-height | margin-top |
|---|---|---|---|
| h1 | 28px | 36px | 0 |
| h2 | 22px | 30px | 24px |
| h3 | 18px | 26px | 20px |
| h4 | 16px | 24px | 16px |

```html
<tr>
  <td style="padding: 0 32px;" class="padding-mobile">
    <h2 style="margin: 24px 0 8px 0; font-family: {{font-family}}; font-size: 22px; line-height: 30px; font-weight: bold; color: {{heading-color}};">
      {{heading-text}}
    </h2>
  </td>
</tr>
```

## Paragraph

```html
<tr>
  <td style="padding: 0 32px;" class="padding-mobile">
    <p style="margin: 0 0 16px 0; font-family: {{font-family}}; font-size: {{font-size}}; line-height: {{line-height}}; color: {{body-color}};">
      {{text}}
    </p>
  </td>
</tr>
```

## Unordered List

```html
<tr>
  <td style="padding: 0 32px;" class="padding-mobile">
    <ul style="margin: 0 0 16px 0; padding: 0 0 0 24px; font-family: {{font-family}}; font-size: {{font-size}}; line-height: {{line-height}}; color: {{body-color}};">
      <li style="margin-bottom: 8px; padding-left: 4px;">{{item}}</li>
    </ul>
  </td>
</tr>
```

## Ordered List

```html
<tr>
  <td style="padding: 0 32px;" class="padding-mobile">
    <ol style="margin: 0 0 16px 0; padding: 0 0 0 24px; font-family: {{font-family}}; font-size: {{font-size}}; line-height: {{line-height}}; color: {{body-color}};">
      <li style="margin-bottom: 8px; padding-left: 4px;">{{item}}</li>
    </ol>
  </td>
</tr>
```

## Task List

Checkboxes rendered as Unicode characters (email clients don't support `<input>`):

```html
<tr>
  <td style="padding: 0 32px;" class="padding-mobile">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
      <tr>
        <td style="padding: 4px 0; font-family: {{font-family}}; font-size: {{font-size}}; line-height: {{line-height}}; color: {{body-color}};">
          &#9744; {{unchecked-item}}
        </td>
      </tr>
      <tr>
        <td style="padding: 4px 0; font-family: {{font-family}}; font-size: {{font-size}}; line-height: {{line-height}}; color: {{body-color}};">
          &#9745; {{checked-item}}
        </td>
      </tr>
    </table>
  </td>
</tr>
```

## Blockquote

```html
<tr>
  <td style="padding: 0 32px;" class="padding-mobile">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
      <tr>
        <td style="border-left: 4px solid {{brand-color}}; padding: 12px 16px; background-color: #f8f9fa;">
          <p style="margin: 0; font-family: {{font-family}}; font-size: {{font-size}}; line-height: {{line-height}}; color: #555555; font-style: italic;">
            {{quote}}
          </p>
        </td>
      </tr>
    </table>
  </td>
</tr>
```

## Callout Box

Highlighted tip/warning/info box with optional icon:

```html
<tr>
  <td style="padding: 0 32px;" class="padding-mobile">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
      <tr>
        <td style="background-color: {{callout-bg}}; border-left: 4px solid {{callout-border}}; border-radius: 4px; padding: 16px 20px;">
          <p style="margin: 0 0 4px 0; font-family: {{font-family}}; font-size: 14px; font-weight: bold; color: {{callout-border}}; text-transform: uppercase;">
            {{callout-label}}
          </p>
          <p style="margin: 0; font-family: {{font-family}}; font-size: {{font-size}}; line-height: {{line-height}}; color: {{body-color}};">
            {{callout-text}}
          </p>
        </td>
      </tr>
    </table>
  </td>
</tr>
```

**Callout variants:**

| Type | `callout-bg` | `callout-border` | `callout-label` |
|---|---|---|---|
| info | `#e8f4fd` | `#2196f3` | Info |
| tip | `#e8f5e9` | `#4caf50` | Tip |
| warning | `#fff8e1` | `#ff9800` | Warning |
| danger | `#fde8e8` | `#f44336` | Important |

## Code Block

```html
<tr>
  <td style="padding: 0 32px;" class="padding-mobile">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
      <tr>
        <td style="background-color: #1e1e1e; padding: 16px; border-radius: 6px;">
          <pre style="margin: 0; font-family: 'Courier New', Courier, monospace; font-size: 13px; line-height: 20px; color: #d4d4d4; white-space: pre-wrap; word-wrap: break-word;">{{code}}</pre>
        </td>
      </tr>
    </table>
  </td>
</tr>
```

## Inline Code

```html
<code style="background-color: #f1f1f1; padding: 2px 6px; border-radius: 3px; font-family: 'Courier New', Courier, monospace; font-size: 14px; color: #d63384;">{{code}}</code>
```

## Image

```html
<tr>
  <td style="padding: 0 32px; text-align: center;" class="padding-mobile">
    <img src="{{src}}" alt="{{alt}}" width="{{width}}"
         style="display: block; margin: 0 auto; max-width: 100%; height: auto; border: 0; outline: none;"
         class="fluid" border="0">
  </td>
</tr>
```

## CTA Button

Primary call-to-action with Outlook VML fallback:

```html
<tr>
  <td style="padding: 24px 32px; text-align: center;" class="padding-mobile">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center">
      <tr>
        <td>
          <!--[if mso]>
          <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word"
            href="{{url}}" style="height:48px;v-text-anchor:middle;width:200px;" arcsize="12%" strokecolor="{{button-color}}" fillcolor="{{button-color}}">
            <w:anchorlock/>
            <center style="color:#ffffff;font-family:{{font-family}};font-size:16px;font-weight:bold;">{{button-text}}</center>
          </v:roundrect>
          <![endif]-->
          <!--[if !mso]><!-->
          <a href="{{url}}" target="_blank"
             style="display: inline-block; padding: 14px 28px; font-family: {{font-family}}; font-size: 16px; font-weight: bold; color: #ffffff; text-decoration: none; border-radius: 6px; background-color: {{button-color}};">
            {{button-text}}
          </a>
          <!--<![endif]-->
        </td>
      </tr>
    </table>
  </td>
</tr>
```

Default `{{button-color}}` = `{{brand-color}}`.

**Button variants:**

| Variant | Color |
|---|---|
| primary | `{{brand-color}}` |
| secondary | `#6c757d` |
| success | `#28a745` |
| danger | `#dc3545` |
| warning | `#ffc107` (text: `#333`) |

## Two Buttons Side by Side

```html
<tr>
  <td style="padding: 24px 32px; text-align: center;" class="padding-mobile">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center">
      <tr>
        <td style="padding-right: 8px;">
          <a href="{{url1}}" target="_blank"
             style="display: inline-block; padding: 12px 24px; font-family: {{font-family}}; font-size: 14px; font-weight: bold; color: #ffffff; text-decoration: none; border-radius: 6px; background-color: {{brand-color}};">
            {{text1}}
          </a>
        </td>
        <td style="padding-left: 8px;">
          <a href="{{url2}}" target="_blank"
             style="display: inline-block; padding: 12px 24px; font-family: {{font-family}}; font-size: 14px; font-weight: bold; color: #ffffff; text-decoration: none; border-radius: 6px; background-color: #6c757d;">
            {{text2}}
          </a>
        </td>
      </tr>
    </table>
  </td>
</tr>
```

## Horizontal Rule

```html
<tr>
  <td style="padding: 8px 32px;" class="padding-mobile">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
      <tr>
        <td style="border-top: 1px solid #e0e0e0; font-size: 0; line-height: 0;">&nbsp;</td>
      </tr>
    </table>
  </td>
</tr>
```

## Centered Text

```html
<tr>
  <td style="padding: 0 32px; text-align: center;" class="padding-mobile">
    <p style="margin: 0 0 16px 0; font-family: {{font-family}}; font-size: {{font-size}}; line-height: {{line-height}}; color: {{body-color}}; text-align: center;">
      {{text}}
    </p>
  </td>
</tr>
```

## Footer

```html
<tr>
  <td style="padding: 24px 32px; text-align: center; border-top: 1px solid #e0e0e0;" class="padding-mobile">
    <p style="margin: 0; font-family: {{font-family}}; font-size: 12px; line-height: 18px; color: #999999;">
      {{footer-text}}
    </p>
  </td>
</tr>
```
