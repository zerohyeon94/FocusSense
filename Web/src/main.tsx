/**
 * ============================================================
 * main.tsx — React 앱의 진입점 (JavaScript Entry Point)
 * ============================================================
 * index.html의 <div id="root">에 React 앱 전체를 마운트합니다.
 * Vite가 이 파일부터 시작해 모든 import를 번들링합니다.
 * ============================================================
 */

/**
 * StrictMode: React 개발 도구
 * - 개발 환경에서만 동작하며 프로덕션 빌드에는 영향을 주지 않습니다.
 * - 잠재적인 문제를 감지하기 위해 컴포넌트를 두 번 렌더링합니다.
 * - 더 이상 사용되지 않는(deprecated) API 경고를 표시합니다.
 */
import { StrictMode } from 'react'

/**
 * createRoot: React 18의 새로운 루트 생성 API
 * - 기존 ReactDOM.render() 를 대체합니다.
 * - Concurrent Mode(동시성 모드)를 활성화하여 렌더링 성능을 개선합니다.
 */
import { createRoot } from 'react-dom/client'

/**
 * index.css: 전역(Global) 스타일시트
 * - CSS 변수(Custom Properties), 리셋, 공통 유틸리티 클래스 등을 포함합니다.
 * - 모든 컴포넌트에 자동으로 적용됩니다.
 */
import './index.css'

/**
 * App: 최상위 컴포넌트
 * - 다크모드 상태 관리, 헤더/메인/푸터 레이아웃을 담당합니다.
 */
import App from './App.tsx'

/**
 * createRoot(element): 지정한 DOM 요소를 React 루트로 설정
 * - document.getElementById('root'): index.html의 <div id="root">를 찾습니다.
 * - !: TypeScript의 Non-null assertion. null이 아님을 개발자가 보장합니다.
 *
 * .render(): 루트에 JSX 컴포넌트를 실제 DOM으로 렌더링합니다.
 */
createRoot(document.getElementById('root')!).render(
  <StrictMode>
    {/* App 컴포넌트가 전체 페이지를 구성합니다 */}
    <App />
  </StrictMode>,
)
