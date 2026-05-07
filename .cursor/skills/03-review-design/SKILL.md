---
name: review-design
description: Provides comprehensive design review covering usability, visual design, accessibility, and Material Design compliance, and writes a timestamped markdown file under docs/design-reviews/ (readable via editor Markdown preview). Use when you want a fresh perspective on a design before sharing it with stakeholders.
---

# Review Design

Get a comprehensive design review covering usability, visual design, accessibility, and Google Material Design compliance.

## When to Use This Skill

- Before sharing a prototype with stakeholders
- When you want a fresh perspective on your design
- To catch usability or accessibility issues early

## Inputs

Provide a file or directory path to review (e.g., `src/app/Dashboard/Dashboard.tsx`).

## Deliverable (required)

When you run this skill and produce a design review, you **must** also **write a markdown document** so the review is durable and shareable.

1. **Timestamp** — Before finalizing the document, obtain the current date and time from the environment (for example run `date '+%Y-%m-%d %H:%M:%S %Z'` in the project shell) and record that value **verbatim** in the document under a heading or table row labeled **Review skill run** (or **Review completed**). Include timezone if the command prints it.
2. **Location** — Save the file under **`docs/design-reviews/`** (create the directory if it does not exist).
3. **Filename** — Use **`design-review-YYYY-MM-DD-HHmmss.md`** where the date and time match the timestamp above (24-hour `HHmmss`, no colons), e.g. `design-review-2026-04-22-130618.md`. If a collision occurs, append a short suffix (e.g. `-b`).
4. **Contents** — The document must include:
   - The **Review skill run** date/time (from step 1)
   - Reference to this skill path (`.cursor/skills/03-review-design/SKILL.md`)
   - **Scope reviewed** (paths, feature names, or screens)
   - The full structured output defined in **What You'll Get** below (overall assessment, detailed feedback table or list, recommendations by priority, what to do next)

In chat, briefly point the user to the new file path. Do not skip the file because the review was already summarized in the conversation.

## Context

- Project: App UI and user flows (adapt to the repo you are in)
- Design standards: **Google Material Design** (prefer **Material Design 3**, M3) and **WCAG 2.1 AA**
- **Material Design documentation**: Use current official guidance from [Material Design 3](https://m3.material.io/) (foundations, styles, components, patterns) and, where relevant, [Accessibility — Material Design](https://m3.material.io/foundations/accessibility/overview). If the implementation uses Flutter, also align feedback with [Material Design for Flutter](https://docs.flutter.dev/ui/design/material) and the project’s actual widgets and theme.

## Your Role

You're providing a fresh perspective on the design, like having another designer review your work. You'll check usability, visual polish, accessibility, and whether it follows Material Design standards.

## Important

Reference the latest Material Design guidance (M3 on m3.material.io and platform docs such as Flutter/Material when applicable) so feedback aligns with current design system standards and best practices.

## What Gets Reviewed

Think of this as a design critique covering multiple perspectives:

### User Experience
- **Is it intuitive?** Can users figure out what to do without instructions?
- **Is it efficient?** Can users complete tasks quickly?
- **Is the hierarchy clear?** Do important things stand out?
- **Are interactions obvious?** Do buttons, links, and controls look clickable?
- **Is there helpful feedback?** Do users know what's happening?
- **Does it handle errors well?** Are error messages helpful and constructive?

### Visual Design
- **Does it look professional?** Is the visual design polished?
- **Is the hierarchy clear?** Do headings, body text, and labels have clear distinction?
- **Is spacing consistent?** Does everything feel balanced and organized (including keylines, padding, and component internal spacing per Material)?
- **Are colors used well?** Is color helping or distracting? (Dynamic Color, roles, and state layers where M3 applies)
- **Do icons make sense?** Are icons clear and consistent (Material Symbols / iconography guidance)?

### Content & Messaging
- **Is the copy clear?** Is text easy to understand?
- **Is the tone appropriate?** Does it sound professional but approachable?
- **Are labels helpful?** Do buttons and links say what they do?
- **Are empty states good?** When there's no data, does it explain why and what to do?

### Accessibility
- **Can everyone use it?** Does it work with keyboard and screen readers?
- **Is contrast good?** Is text easy to read?
- **Are interactive elements clear?** Can you tell what's clickable?
- **Touch targets and focus**: Sufficient size and visible focus where applicable

### Material Design compliance
- **Does it match the design system?** Correct use of Material components, tokens, typography scale, elevation/shadow, motion, and layout patterns for the stack in use (e.g., Material widgets and `ThemeData` on Flutter).
- **Is it consistent?** Does it look coherent across screens?
- **Are we using the right components?** Could standard Material components or patterns simplify or improve the UI?

## What You'll Get

1. **Overall Assessment**
   - **The Good**: What's working well
   - **The Concerns**: What needs attention
   - **The Verdict**: Ready to go / Needs some fixes / Needs rework

2. **Detailed Feedback**
   
   For each issue:
   - **What's the problem**: Plain description
   - **Where**: Which part of the page
   - **Why it matters**: Impact on users
   - **How to improve**: Specific suggestions
   - **Priority**: Must fix / Should fix / Consider for later

3. **Recommendations by Priority**
   
   **Fix Now** (High Priority)
   - Issues that seriously impact usability or accessibility
   
   **Fix Soon** (Medium Priority)
   - Polish and consistency improvements
   
   **Consider Later** (Nice to Have)
   - Enhancements for future iterations

4. **What to Do Next**
   Clear action items, starting with the most important improvements.

Note: This review covers usability, visual design, accessibility, and Material Design compliance all in one go. The agent can implement any of the suggested fixes—just let me know which ones you want to tackle.

Remember: always produce the **`docs/design-reviews/design-review-YYYY-MM-DD-HHmmss.md`** deliverable with **Review skill run** date/time included, as specified in **Deliverable (required)** above.
