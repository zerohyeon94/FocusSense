/**
 * ============================================================
 * App.tsx — 최상위(Root) 컴포넌트
 * ============================================================
 * 전체 페이지의 레이아웃을 담당합니다.
 * - 다크모드 상태를 전역으로 관리하고 하위 컴포넌트에 전달합니다.
 * - Header → main(각 섹션들) → footer 순으로 구성됩니다.
 * ============================================================
 */

/**
 * React Hooks import
 * - useState : 컴포넌트 내부 상태(state)를 관리하는 Hook
 * - useEffect: 렌더링 후 실행되는 사이드 이펙트를 처리하는 Hook
 *   (API 호출, DOM 조작, 이벤트 등록 등에 사용)
 */
import { useState, useEffect } from 'react';

/* ── 각 섹션 컴포넌트 import ── */
import Header from './components/Header';       // 상단 고정 네비게이션 바
import Hero from './components/Hero';           // 메인 히어로 섹션 (랜딩 첫 화면)
import Features from './components/Features';   // 핵심 기능 소개 섹션
import HowItWorks from './components/HowItWorks'; // AI 작동 원리 설명 섹션
import Philosophy from './components/Philosophy'; // 앱 방향성/철학 섹션
import Guide from './components/Guide';         // 기기 배치 가이드 섹션
import Download from './components/Download';   // 다운로드 CTA 섹션

/**
 * App 컴포넌트
 * 다크모드 상태를 소유(own)하고, Header에 토글 함수를 prop으로 전달합니다.
 */
function App() {
  /**
   * useState<boolean>(false): 다크모드 상태
   * - isDarkMode  : 현재 다크모드 여부 (true = 다크, false = 라이트)
   * - setIsDarkMode: 상태를 변경하는 setter 함수
   * - 초기값은 false(라이트모드)이며, 아래 useEffect에서 시스템 설정에 맞게 덮어씁니다.
   */
  const [isDarkMode, setIsDarkMode] = useState(false);

  /**
   * useEffect #1 — 시스템 다크모드 설정 감지
   * - 의존성 배열이 [] (빈 배열)이므로 컴포넌트가 처음 마운트될 때 한 번만 실행됩니다.
   * - window.matchMedia: 미디어 쿼리를 JavaScript에서 확인하는 Web API
   * - 'prefers-color-scheme: dark': OS/브라우저의 다크모드 설정 여부를 쿼리합니다.
   */
  useEffect(() => {
    // System preference detection
    // .matches: 해당 미디어 쿼리가 현재 일치하면 true를 반환합니다.
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    setIsDarkMode(prefersDark);
  }, []); // 의존성 배열이 비어있으면 마운트 시 1회만 실행

  /**
   * useEffect #2 — 다크모드 상태를 DOM에 반영
   * - 의존성 배열에 [isDarkMode]가 있으므로, isDarkMode 값이 바뀔 때마다 실행됩니다.
   * - document.body.classList: <body> 태그의 CSS 클래스를 조작합니다.
   * - 'dark' 클래스 추가/제거로 index.css의 body.dark { ... } 변수를 적용/해제합니다.
   */
  useEffect(() => {
    if (isDarkMode) {
      document.body.classList.add('dark');    // <body class="dark"> → 다크모드 CSS 변수 적용
    } else {
      document.body.classList.remove('dark'); // <body class="">    → 라이트모드 CSS 변수 적용
    }
  }, [isDarkMode]); // isDarkMode가 변경될 때마다 실행

  return (
    /* 최상위 wrapper div — CSS 변수로 배경색/텍스트색을 설정하고 부드럽게 전환 */
    <div style={{ backgroundColor: 'var(--bg-main)', color: 'var(--text-primary)', transition: 'background-color 0.3s, color 0.3s' }}>

      {/*
        Header: 상단 고정 네비게이션
        - isDarkMode  : 현재 테마를 Header가 알아야 배경 투명도 등을 조절할 수 있습니다.
        - setIsDarkMode: 토글 버튼 클릭 시 호출되어 상태를 변경합니다.
        이렇게 부모가 자식에게 값과 함수를 전달하는 방식을 "Props Drilling"이라 합니다.
      */}
      <Header isDarkMode={isDarkMode} setIsDarkMode={setIsDarkMode} />

      {/* main: 시맨틱 HTML — 페이지의 주요 콘텐츠 영역 */}
      <main>
        <Hero />        {/* 1. 히어로 섹션: 헤드라인, 폰 목업, 통계 */}
        <Features />    {/* 2. 기능 섹션: 6개 핵심 기능 카드 그리드 */}
        <HowItWorks />  {/* 3. 작동 원리: 4단계 AI 분석 프로세스 */}
        <Philosophy />  {/* 4. 방향성: 앱의 철학과 핵심 원칙 */}
        <Guide />       {/* 5. 배치 가이드: 올바른 사용법 안내 */}
        <Download />    {/* 6. 다운로드: App Store CTA */}
      </main>

      {/* footer: 시맨틱 HTML — 페이지 하단 정보 */}
      <footer style={{
        padding: '48px 0',
        borderTop: '1px solid var(--border)',      // 상단에 구분선 추가
        backgroundColor: 'var(--bg-main)',
        transition: 'background-color 0.3s',       // 다크모드 전환 시 부드러운 색상 변화
      }}>
        {/* container: 최대 너비 제한 + 좌우 패딩 (index.css에서 정의) */}
        <div className="container" style={{
          display: 'flex',
          justifyContent: 'space-between', // 로고 / 저작권 / 링크를 양쪽으로 배치
          alignItems: 'center',
          flexWrap: 'wrap',                 // 좁은 화면에서 줄바꿈 허용
          gap: '20px',
        }}>

          {/* 푸터 로고 — 작은 아이콘 + 브랜드명 */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{
              width: '28px', height: '28px',
              borderRadius: '7px',
              background: 'linear-gradient(135deg, #007AFF 0%, #4DA3FF 100%)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: 'white' }} />
            </div>
            <span style={{ fontWeight: 700, fontSize: '0.95rem', color: 'var(--text-primary)' }}>FocusSense</span>
          </div>

          {/* 저작권 표시 */}
          <p style={{ color: 'var(--text-tertiary)', fontSize: '0.85rem' }}>
            © 2026 FocusSense Project. Built with Vision + CoreML.
          </p>

          {/* 섹션 바로가기 링크 목록 */}
          <div style={{ display: 'flex', gap: '20px' }}>
            {/*
              배열.map(): 배열의 각 항목을 JSX 요소로 변환합니다.
              삼항 연산자(? :)로 한국어 라벨을 영어 앵커 ID로 매핑합니다.
              key={item}: React가 리스트 항목을 구별하기 위한 고유 식별자입니다.
            */}
            {['기능', '작동 원리', '방향성', '배치 가이드'].map(item => (
              <a
                key={item}
                href={`#${item === '기능' ? 'features' : item === '작동 원리' ? 'how-it-works' : item === '방향성' ? 'philosophy' : 'guide'}`}
                style={{ fontSize: '0.82rem', color: 'var(--text-tertiary)', transition: 'color 0.2s' }}
                {/* 마우스 오버 시 텍스트 색상을 강조색으로 변경 */}
                onMouseEnter={e => (e.target as HTMLElement).style.color = 'var(--text-primary)'}
                onMouseLeave={e => (e.target as HTMLElement).style.color = 'var(--text-tertiary)'}
              >
                {item}
              </a>
            ))}
          </div>
        </div>
      </footer>
    </div>
  );
}

/* 다른 파일에서 import App from './App' 으로 사용할 수 있도록 export */
export default App;
