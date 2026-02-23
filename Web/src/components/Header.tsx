/**
 * ============================================================
 * Header.tsx — 상단 고정 네비게이션 바
 * ============================================================
 * 기능:
 * - 페이지 상단에 고정(sticky)되어 항상 보입니다.
 * - 스크롤 시 반투명 유리(glassmorphism) 효과가 적용됩니다.
 * - 다크모드 토글 버튼을 포함합니다.
 * - 모바일에서는 햄버거 메뉴로 전환됩니다.
 * ============================================================
 */

/**
 * useState  : 스크롤 상태, 모바일 메뉴 열림 상태 관리
 * useEffect : 스크롤 이벤트 리스너 등록/해제
 */
import { useState, useEffect } from 'react';

/**
 * framer-motion: 애니메이션 라이브러리
 * - motion.div  : 일반 div에 애니메이션 기능을 추가한 컴포넌트
 * - AnimatePresence: 컴포넌트가 마운트/언마운트될 때 애니메이션을 처리합니다.
 *                    (예: 모바일 메뉴가 열리고 닫힐 때 fade 효과)
 */
import { motion, AnimatePresence } from 'framer-motion';

/**
 * TypeScript 인터페이스 — Props 타입 정의
 * App.tsx에서 Header에 전달하는 props의 타입을 명시합니다.
 * 이를 통해 잘못된 타입의 값이 전달되면 컴파일 오류가 발생합니다.
 */
interface HeaderProps {
  isDarkMode: boolean;                    // 현재 다크모드 여부
  setIsDarkMode: (value: boolean) => void; // 다크모드 상태를 변경하는 함수
}

/**
 * Header 컴포넌트
 * Props를 구조 분해 할당(Destructuring)으로 받습니다.
 * ({ isDarkMode, setIsDarkMode }) 형식은 HeaderProps 객체에서 바로 꺼내 씁니다.
 */
export default function Header({ isDarkMode, setIsDarkMode }: HeaderProps) {
  /**
   * scrolled: 스크롤 여부 상태
   * - false: 페이지 최상단 → 헤더 배경이 투명
   * - true : 스크롤 발생  → 헤더에 반투명 유리 효과 적용
   */
  const [scrolled, setScrolled] = useState(false);

  /**
   * mobileMenuOpen: 모바일 햄버거 메뉴 열림 상태
   * - false: 메뉴 닫힘 → 햄버거 아이콘 표시
   * - true : 메뉴 열림 → X 아이콘 표시, 메뉴 드롭다운 표시
   */
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  /**
   * useEffect — 스크롤 이벤트 리스너 등록
   *
   * [등록 과정]
   * handleScroll: 스크롤 위치(window.scrollY)가 20px 초과이면 scrolled를 true로 설정
   * window.addEventListener('scroll', handler, { passive: true })
   *   - passive: true → 스크롤 성능 최적화 옵션
   *              브라우저에게 "이 핸들러에서 preventDefault()를 호출하지 않겠다"고 알립니다.
   *
   * [정리(Cleanup) 함수]
   * return () => window.removeEventListener(...)
   * 컴포넌트가 언마운트될 때 이벤트 리스너를 제거합니다.
   * 제거하지 않으면 메모리 누수(memory leak)가 발생할 수 있습니다.
   *
   * 의존성 배열 []  → 마운트 시 한 번만 실행
   */
  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  /**
   * 네비게이션 링크 데이터
   * 배열로 관리하면 새 항목 추가/삭제 시 JSX를 수정할 필요가 없습니다.
   * href의 '#features' 등은 해당 section의 id 속성과 연결됩니다. (앵커 링크)
   */
  const navLinks = [
    { label: '기능', href: '#features' },
    { label: '작동 원리', href: '#how-it-works' },
    { label: '방향성', href: '#philosophy' },
    { label: '배치 가이드', href: '#guide' },
  ];

  return (
    <header style={{
      position: 'fixed',  /* 스크롤해도 화면 상단에 고정 */
      top: 0,
      left: 0,
      right: 0,
      zIndex: 1000,       /* 다른 요소 위에 표시 (z-index가 클수록 앞에 표시됨) */
      height: '64px',
      display: 'flex',
      alignItems: 'center',
      transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',

      /* 스크롤 여부(scrolled)에 따라 배경색 변경
         삼항 연산자: scrolled ? (스크롤 시 배경) : (최상단 배경) */
      backgroundColor: scrolled
        ? (isDarkMode ? 'rgba(15, 15, 26, 0.85)' : 'rgba(255, 255, 255, 0.85)')
        : 'transparent', /* 최상단에서는 투명 */

      /* backdropFilter: 헤더 뒤 콘텐츠를 블러(흐림) 처리하여 유리 효과 구현
         blur(20px): 20픽셀 블러
         saturate(180%): 채도 180%로 선명하게 */
      backdropFilter: scrolled ? 'blur(20px) saturate(180%)' : 'none',
      WebkitBackdropFilter: scrolled ? 'blur(20px) saturate(180%)' : 'none', /* Safari 접두사 */

      /* 스크롤 시 하단 구분선 표시 */
      borderBottom: scrolled
        ? `1px solid ${isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)'}`
        : '1px solid transparent',
    }}>

      {/* 최대 너비 제한 컨테이너 */}
      <div className="container" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>

        {/* ── 로고 영역 ──
            a href="#": 클릭 시 페이지 최상단으로 이동 */}
        <a href="#" style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          {/* 아이콘 컨테이너 — 파란 그라디언트 배경의 둥근 박스 */}
          <div style={{
            width: '32px',
            height: '32px',
            borderRadius: '8px',
            background: 'linear-gradient(135deg, #007AFF 0%, #4DA3FF 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(0, 122, 255, 0.3)',
          }}>
            {/* SVG 아이콘: 눈(eye) 모양 — FocusSense의 "집중 감지" 개념을 표현 */}
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
              {/* 눈의 동공 (중앙 원) */}
              <circle cx="12" cy="12" r="3" fill="white" />
              {/* 눈의 외곽 (큰 원, 반투명) */}
              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z" fill="white" opacity="0.5" />
              {/* 눈의 홍채 (중간 원, 더 반투명) */}
              <path d="M12 6c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6zm0 10c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4z" fill="white" opacity="0.3" />
            </svg>
          </div>
          {/* 브랜드명 텍스트 */}
          <span style={{
            fontSize: '1.15rem',
            fontWeight: 700,
            color: 'var(--text-primary)',
            letterSpacing: '-0.02em',
          }}>
            FocusSense
          </span>
        </a>

        {/* ── 데스크톱 네비게이션 ──
            className="desktop-nav": 768px 이하에서 display:none (하단 <style> 참고) */}
        <nav style={{ display: 'flex', alignItems: 'center', gap: '8px' }} className="desktop-nav">
          {/* navLinks 배열을 map()으로 순회하여 링크 생성 */}
          {navLinks.map(link => (
            <a
              key={link.href}   /* React 리스트의 고유 key — href를 ID로 사용 */
              href={link.href}
              style={{
                padding: '7px 14px',
                borderRadius: '50px',
                fontSize: '0.875rem',
                fontWeight: 500,
                color: 'var(--text-secondary)',
                transition: 'all 0.2s',
              }}
              {/* onMouseEnter/Leave: CSS :hover를 JS로 구현 (인라인 스타일 한계) */}
              onMouseEnter={e => {
                (e.target as HTMLElement).style.color = 'var(--text-primary)';
                (e.target as HTMLElement).style.backgroundColor = 'var(--bg-sub)';
              }}
              onMouseLeave={e => {
                (e.target as HTMLElement).style.color = 'var(--text-secondary)';
                (e.target as HTMLElement).style.backgroundColor = 'transparent';
              }}
            >
              {link.label}
            </a>
          ))}
        </nav>

        {/* ── 우측 액션 버튼 영역 ── */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>

          {/* 다크모드 토글 버튼
              aria-label: 스크린리더(시각 장애인 보조 기술)를 위한 레이블
              onClick: !isDarkMode로 현재 값을 반전시켜 토글 동작 구현 */}
          <button
            onClick={() => setIsDarkMode(!isDarkMode)}
            aria-label="다크모드 전환"
            style={{
              width: '38px',
              height: '38px',
              borderRadius: '50%',
              border: `1px solid var(--border)`,
              background: 'var(--bg-sub)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '1rem',
              transition: 'all 0.2s',
              flexShrink: 0, /* flex 컨테이너에서 이 버튼이 줄어들지 않도록 */
            }}
          >
            {/* isDarkMode에 따라 아이콘 전환: 다크모드면 ☀️, 라이트모드면 🌙 */}
            {isDarkMode ? '☀️' : '🌙'}
          </button>

          {/* 앱 다운로드 CTA (Call To Action) 버튼
              className="btn-primary": index.css에서 정의한 파란 버튼 스타일 적용 */}
          <a
            href="#download"
            className="btn-primary"
            style={{ padding: '8px 18px', fontSize: '0.875rem' }}
          >
            앱 다운로드
          </a>

          {/* 모바일 햄버거 메뉴 버튼
              className="mobile-menu-btn": 768px 이하에서만 display:flex로 표시 */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="메뉴"
            className="mobile-menu-btn"
            style={{
              width: '38px',
              height: '38px',
              borderRadius: '50%',
              border: `1px solid var(--border)`,
              background: 'var(--bg-sub)',
              cursor: 'pointer',
              display: 'none', /* 기본은 숨김, 모바일에서 display:flex로 변경 */
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
            }}
          >
            {/* 햄버거 아이콘 (3개의 선)
                mobileMenuOpen 상태에 따라 CSS transform으로 X 아이콘으로 변형됩니다. */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              {/* 첫 번째 선: 열리면 아래로 내려가며 45도 회전 */}
              <span style={{ width: '16px', height: '1.5px', background: 'var(--text-primary)', borderRadius: '2px', display: 'block', transition: 'all 0.2s', transform: mobileMenuOpen ? 'translateY(5.5px) rotate(45deg)' : 'none' }} />
              {/* 가운데 선: 열리면 투명하게 (opacity: 0) */}
              <span style={{ width: '16px', height: '1.5px', background: 'var(--text-primary)', borderRadius: '2px', display: 'block', transition: 'all 0.2s', opacity: mobileMenuOpen ? 0 : 1 }} />
              {/* 세 번째 선: 열리면 위로 올라가며 -45도 회전 */}
              <span style={{ width: '16px', height: '1.5px', background: 'var(--text-primary)', borderRadius: '2px', display: 'block', transition: 'all 0.2s', transform: mobileMenuOpen ? 'translateY(-5.5px) rotate(-45deg)' : 'none' }} />
            </div>
          </button>
        </div>
      </div>

      {/* ── 모바일 드롭다운 메뉴 ──
          AnimatePresence: 자식 컴포넌트가 React DOM에서 제거될 때(exit)
                           애니메이션이 완료될 때까지 기다렸다가 제거합니다.
          mobileMenuOpen이 false면 컴포넌트가 렌더링되지 않습니다. */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            /* initial: 처음 마운트될 때의 상태 (불투명도 0, 10px 위에서 시작) */
            initial={{ opacity: 0, y: -10 }}
            /* animate: 최종 상태 (불투명도 1, 원래 위치) */
            animate={{ opacity: 1, y: 0 }}
            /* exit: 언마운트될 때의 상태 (다시 불투명도 0, 위로 이동) */
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.2 }} /* 0.2초 동안 애니메이션 */
            style={{
              position: 'absolute',  /* 헤더 기준으로 절대 위치 */
              top: '64px',           /* 헤더 바로 아래에 표시 */
              left: 0,
              right: 0,
              backgroundColor: isDarkMode ? 'rgba(15, 15, 26, 0.97)' : 'rgba(255, 255, 255, 0.97)',
              backdropFilter: 'blur(20px)',
              WebkitBackdropFilter: 'blur(20px)',
              borderBottom: `1px solid var(--border)`,
              padding: '16px 24px 24px',
            }}
          >
            {navLinks.map(link => (
              <a
                key={link.href}
                href={link.href}
                /* 링크 클릭 시 메뉴를 닫습니다 */
                onClick={() => setMobileMenuOpen(false)}
                style={{
                  display: 'block', /* 블록 요소로 각 링크가 한 줄을 차지 */
                  padding: '14px 0',
                  fontSize: '1.05rem',
                  fontWeight: 500,
                  color: 'var(--text-primary)',
                  borderBottom: `1px solid var(--border)`, /* 링크 사이 구분선 */
                }}
              >
                {link.label}
              </a>
            ))}
          </motion.div>
        )}
      </AnimatePresence>

      {/* 인라인 <style>: 미디어 쿼리를 JSX 내부에 직접 작성
          768px 이하에서 데스크톱 네비 숨기고 모바일 버튼 보이게 합니다.
          !important: 인라인 스타일보다 우선순위를 높입니다. */}
      <style>{`
        @media (max-width: 768px) {
          .desktop-nav { display: none !important; }
          .mobile-menu-btn { display: flex !important; }
        }
      `}</style>
    </header>
  );
}
