# Web/CLAUDE.md

ZipJoong 랜딩 페이지 작업 시 참고하는 가이드입니다.
저장소 전체 규칙은 루트 `CLAUDE.md`를 함께 참고해주세요.

## 기술 스택

| 도구 | 버전 | 역할 |
|------|------|------|
| React | 19 | UI 라이브러리 |
| TypeScript | ~5.9 | 타입 안전성 |
| Vite | 7 | 개발 서버 + 빌드 |
| Framer Motion | 12 | 애니메이션 |
| ESLint | — | 린팅 |

## 개발 명령어

```bash
cd Web
npm install       # 의존성 설치
npm run dev       # 개발 서버 실행 (http://localhost:5173)
npm run build     # 타입 체크 + 프로덕션 빌드
npm run preview   # 프로덕션 빌드 로컬 미리보기
npm run lint      # ESLint 실행
```

## 프로젝트 구조

```
Web/src/
├── App.tsx              - 루트 컴포넌트, 페이지 섹션 구성
├── main.tsx             - React 진입점
├── index.css            - 전역 스타일
├── App.css              - App 레벨 스타일
└── components/          - 페이지 섹션별 파일
    ├── Header.tsx        - 네비게이션 바
    ├── Hero.tsx          - 히어로 / 첫 화면 섹션
    ├── HowItWorks.tsx    - 기능 설명
    ├── Guide.tsx         - 사용자 가이드 단계
    ├── Features.tsx      - 기능 쇼케이스
    ├── Download.tsx      - 앱 다운로드 CTA
    ├── Philosophy.tsx    - 프로젝트 철학 섹션
    └── PhilosophyCard.tsx - 철학 항목용 재사용 카드
```

## 코드 스타일

- 컴포넌트당 하나의 파일; 파일명과 export 컴포넌트명 일치
- TypeScript strict 타입 사용 — `any` 금지
- 모든 진입/스크롤 애니메이션에 Framer Motion 사용 (이미 설치됨)
- 컴포넌트를 간결하게 유지; 파일이 ~100줄을 초과하면 하위 컴포넌트로 분리
- CSS: 디자인 토큰은 `index.css` 전역 스타일, 컴포넌트별 스타일은 인라인 또는 모듈 CSS 사용
- 추가 애니메이션 라이브러리 설치 금지 — Framer Motion으로 충분

## 의존성 주의사항

- `react`와 `react-dom`은 이미 v19 — 다운그레이드 금지
- `framer-motion` v12는 API가 변경됨; deprecated된 motion props 사용 전 문서 확인
- `react-router-dom`은 멀티 페이지 라우팅이 명시적으로 요청되지 않는 한 추가 금지
