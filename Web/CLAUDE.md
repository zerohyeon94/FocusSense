# Web/CLAUDE.md

Guidance for working on the FocusSense landing page.
Also read the root `CLAUDE.md` for repository-wide conventions.

## Tech Stack

| Tool | Version | Role |
|------|---------|------|
| React | 19 | UI library |
| TypeScript | ~5.9 | Type safety |
| Vite | 7 | Dev server + build |
| Framer Motion | 12 | Animations |
| ESLint | — | Linting |

## Dev Commands

```bash
cd Web
npm install       # install dependencies
npm run dev       # start dev server (http://localhost:5173)
npm run build     # type-check + production build
npm run preview   # preview production build locally
npm run lint      # run ESLint
```

## Project Structure

```
Web/src/
├── App.tsx              - Root component, composes page sections
├── main.tsx             - React entry point
├── index.css            - Global styles
├── App.css              - App-level styles
└── components/          - One file per page section
    ├── Header.tsx        - Navigation bar
    ├── Hero.tsx          - Hero / above-the-fold section
    ├── HowItWorks.tsx    - Feature explanation
    ├── Guide.tsx         - User guide steps
    ├── Features.tsx      - Features showcase
    ├── Download.tsx      - App download CTA
    ├── Philosophy.tsx    - Project philosophy section
    └── PhilosophyCard.tsx - Reusable card for philosophy items
```

## Code Style

- One component per file; file name matches the exported component name
- Use TypeScript strict types — no `any`
- Use Framer Motion for all entrance/scroll animations (already installed)
- Keep components focused; split into sub-components when a file exceeds ~100 lines
- CSS: prefer `index.css` globals for design tokens, inline Tailwind/module CSS for component-specific styles
- Do not install additional animation libraries — Framer Motion covers all needs

## Dependency Notes

- `react` and `react-dom` are already at v19 — do not downgrade
- `framer-motion` v12 has updated API; check docs before using deprecated motion props
- Do not add `react-router-dom` unless multi-page routing is explicitly requested
