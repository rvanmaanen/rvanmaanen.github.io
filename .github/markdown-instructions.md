---
applyTo: "**/*.md"
---

# Instructions for AI models when generating markdown files

If you have not read them, fetch `/workspaces/tech/.github/copilot-instructions.md` and use these instructions as well.

## Terminology

- Excerpt: The excerpt is the most important part of the introduction, summarizing the main point or highlight. It must always appear at the very start of the introduction and be immediately followed by the `<!--excerpt_end-->` code.
- Introduction: The introduction can be as long as needed and follows the excerpt. It provides additional context, background, or details about the magazine and should include the author's name. The introduction always starts with the excerpt and `<!--excerpt_end-->`, then continues with further content.
- Summary: The summary refers to the section after the introduction, which briefly describes each article in the magazine, preferably grouped by topic.

## Markdown Rules

1. Use well-structured markdown.
2. For lists:
    - Place a single blank line before and after the entire list.
    - Do not add blank lines between list items.
    - List items must start with a dash and a space (e.g., `- item`).
3. For headings:
    - Place a single blank line before and after each heading.
    - Headings must start with one or more hash symbols followed by a space (e.g., `# Heading`, `## Subheading`).
4. End the file with a single blank line.
5. Do not leave trailing spaces at the end of any line.
6. Do not use tab characters; use spaces for indentation.
7. Ensure there is exactly one blank line between blocks (e.g., between headings, lists, paragraphs, and code blocks).
8. Do not use more than one consecutive blank line anywhere in the file.
9. All headings must increment by only one level at a time (e.g., do not jump from `#` to `###`).
10. Do not use inline HTML unless absolutely necessary.

## Jekyll/Markdown Content Generation Rules

1. Start with the Front-Matter, then follow with the rest of the content.
2. Follow the Front-Matter with an introduction (excerpt) of the collection (max 200 words), mentioning the main contents and the author's name. End the excerpt with `<!--excerpt_end-->`.
3. Write excerpts that are informative and engaging.
4. After the excerpt and a blank line, provide a summary of the entire content provided.
5. If the viewing_mode is "internal" and the file is not in the `_videos` directory, end the content with a line that looks like this: `[Read the entire article here]([canonical_url]).` Replace `[canonical_url]` with the canonical URL.

## Front-Matter

1. Include all relevant front-matter fields found in other markdown files in the same folder such as: layout, title, description, author, categories, tags, date, canonical_url, permalink, **and any others present**.
2. Do not start descriptions with phrases like "In this article", "In this post", etc. Start with the main topic or key point.
3. Dates should be formatted as YYYY-MM-DD.
4. The filename format is: `YYYY-MM-DD-Article-Title.md`.
5. Use the following fields in the front-matter at the top of the file:
    - `layout`: Always set to `post`.
    - `title`: Extract from the article or ask the user if not clear.
    - `description`: Write a concise summary of the article's main points and topics (max 100 words). Do not start with phrases like "In this article" or similar.
    - `author`: Extract from the article or ask the user if not clear.
    - `excerpt_separator`: Always set to `<!--excerpt_end-->`.
    - `canonical_url`: Use the provided URL, but remove any querystring parameters. Do not change the rest of the URL.
    - `tags`: Array of relevant keywords from the article. Do not use generic terms like 'news' or 'update'. At least 10 if possible, but only if they really fit. Don't make up things.
    - `categories`: Array of strings. Use 'AI' and 'GitHub Copilot'. Both or neither, based on the article content. If you include 'GitHub  Copilot', always include 'AI' as well. If unsure, leave empty.
    - `feed_name`: Use provided feed name. Omit if not provided.
    - `feed_url`: Use provided feed url. Omit if not provided.
    - `permalink`: Is `/section/filename.html`. Replace `.md` with `.html` from the filename. The section is the target directory, without an underscore (e.g. `magazines`, `news`, `videos`, etc).
6. Example Front-Matter can be seen below. This is an example, always look at the other .md files in the directory to determine how the front-matter should look and which properties to include, but do not copy property values and determine them yourself based on the content provided.

### Front-Matter Example

```yaml
---
layout: "post"
title: "Introducing automatic documentation comment generation in Visual Studio"
description: "Copilot is now integrated in Visual Studio's editor to automatically generate function doc comments, streamlining documentation for GitHub Copilot subscribers."
author: "Sinem Akinci, Allie Barry"
excerpt_separator: <!--excerpt_end-->
canonical_url: "https://devblogs.microsoft.com/visualstudio/introducing-automatic-documentation-comment-generation-in-visual-studio/"
tags: [AI,Artificial Intelligence,code comments,Docs,documentation,GitHub Copilot,IDE integration,Productivity,Visual Studio]
categories: [AI,GitHub Copilot]
feed_name: "DevBlog Copilot"
feed_url: "https://devblogs.microsoft.com/visualstudio/tag/copilot/feed/"
date: 2025-03-17
permalink: "/news/2025-03-17-Introducing-automatic-documentation-comment-generation-in-Visual-Studio.html"
---
```
