/**
 * ============================================================
 * Features.tsx — 핵심 기능 소개 섹션
 * ============================================================
 * 앱의 6가지 주요 기능을 카드 그리드로 표시합니다.
 * - CSS Grid의 auto-fit/minmax를 사용해 반응형 레이아웃을 구성합니다.
 * - 각 카드는 스크롤 시 순차적으로 나타나는 애니메이션이 적용됩니다.
 * ============================================================
 */

import { motion } from 'framer-motion';

/**
 * features: 기능 카드 데이터 배열
 * UI 데이터(텍스트, 색상, 아이콘)를 컴포넌트 밖에 분리하면:
 * - 기능 추가/수정 시 데이터만 변경하면 됩니다.
 * - JSX 코드가 간결해집니다.
 *
 * 각 항목의 속성:
 * - icon       : SVG 컴포넌트 (JSX 표현식)
 * - color      : 아이콘/텍스트/뱃지의 주 색상 (hex)
 * - bg         : 아이콘 배경색 (rgba 반투명)
 * - title      : 기능 제목
 * - description: 기능 설명
 * - badge      : 기술 카테고리 레이블
 */
const features = [
  {
    /* 눈 모양 아이콘 — EAR 분석 기능을 시각적으로 표현 */
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
        {/* fill="currentColor": 부모 요소의 color CSS 속성 값을 그대로 사용 */}
        <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z" fill="currentColor"/>
      </svg>
    ),
    color: '#007AFF',
    bg: 'rgba(0,122,255,0.1)',
    title: '실시간 눈 상태 분석',
    description: 'EAR(Eye Aspect Ratio) 알고리즘으로 눈 개폐 비율을 실시간 측정. 졸음 여부를 0.3초 단위로 감지합니다.',
    badge: 'Vision Framework',
  },
  {
    /* 재생 버튼 아이콘 — 자동 일시정지/재개 기능 */
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 14.5v-9l6 4.5-6 4.5z" fill="currentColor"/>
      </svg>
    ),
    color: '#FF9F0A',
    bg: 'rgba(255,159,10,0.1)',
    title: '자동 일시정지 / 재개',
    description: '졸음이 2초 이상 지속되거나 자리를 3초 이상 비우면 타이머가 자동으로 일시정지됩니다. 돌아오면 자동 재개.',
    badge: '스마트 감지',
  },
  {
    /* 바 차트 아이콘 — 데이터 분석/통계 */
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
        <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM9 17H7v-7h2v7zm4 0h-2V7h2v10zm4 0h-2v-4h2v4z" fill="currentColor"/>
      </svg>
    ),
    color: '#30D158',
    bg: 'rgba(48,209,88,0.1)',
    title: '집중 패턴 분석',
    description: '세션별 집중률, 순수 집중 시간, GitHub 스타일 잔디 그래프로 언제 가장 집중이 잘 되는지 패턴을 파악합니다.',
    badge: '데이터 인사이트',
  },
  {
    /* 자물쇠 아이콘 — 보안/프라이버시 */
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
        <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z" fill="currentColor"/>
      </svg>
    ),
    color: '#BF5AF2',
    bg: 'rgba(191,90,242,0.1)',
    title: '완전한 프라이버시',
    description: '모든 AI 분석은 기기 내부에서만 처리됩니다. 카메라 영상과 분석 데이터는 서버로 전송되지 않습니다.',
    badge: '온디바이스 AI',
  },
  {
    /* 별 아이콘 — 개인화/맞춤 설정 */
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" fill="currentColor"/>
      </svg>
    ),
    color: '#FF6B6B',
    bg: 'rgba(255,107,107,0.1)',
    title: '사용자 캘리브레이션',
    description: '개인별 눈 기준값을 교정하여 정확도를 높입니다. 작은 눈, 안경 착용자도 정확하게 감지합니다.',
    badge: '개인 맞춤',
  },
  {
    /* 벨 아이콘 — 알림 시스템 */
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
        <path d="M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z" fill="currentColor"/>
      </svg>
    ),
    color: '#64D2FF',
    bg: 'rgba(100,210,255,0.1)',
    title: '스마트 알림',
    description: '공부 시작 시간, 목표 달성, 주간 리포트를 iOS 알림으로 받아보세요. 계획한 스케줄도 자동으로 리마인드.',
    badge: '알림 시스템',
  },
];

/**
 * Features 컴포넌트
 * id="features": Header의 '#features' 앵커 링크와 연결됩니다.
 */
export default function Features() {
  return (
    <section id="features" className="section" style={{ backgroundColor: 'var(--bg-sub)', transition: 'background-color 0.3s' }}>
      <div className="container">

        {/* ── 섹션 헤더 (타이틀 영역) ──
            whileInView: 요소가 뷰포트에 들어올 때 애니메이션을 실행합니다.
            viewport={{ once: true }}: 한 번만 실행 (스크롤 반복해도 재실행 안 함)
            margin: '-80px': 요소가 화면 하단 80px 안쪽으로 들어올 때 트리거 */}
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-80px' }}
          transition={{ duration: 0.6 }}
          style={{ textAlign: 'center', marginBottom: '64px' }}
        >
          {/* section-label: index.css의 대문자 소형 레이블 스타일 */}
          <span className="section-label">핵심 기능</span>
          <h2 className="section-title">AI가 측정하는 진짜 집중</h2>
          {/* margin: '0 auto': 최대 너비(max-width: 560px)를 유지하며 가운데 정렬 */}
          <p className="section-subtitle" style={{ margin: '0 auto' }}>
            단순히 시간을 재는 것이 아닙니다. FocusSense는 당신이 실제로
            집중하고 있는 시간만 정확하게 기록합니다.
          </p>
        </motion.div>

        {/* ── 기능 카드 그리드 ──
            CSS Grid 레이아웃:
            - gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))'
              → auto-fit: 화면 너비에 맞게 열 수를 자동 결정
              → minmax(300px, 1fr): 각 열이 최소 300px, 남은 공간을 균등 분할(1fr)
              → 결과: 넓은 화면은 3열, 좁으면 2열, 모바일은 1열로 자동 조절 */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
          gap: '20px',
        }}>
          {/* features 배열을 순회하여 카드 렌더링
              i: 현재 인덱스 — delay 계산에 사용 */}
          {features.map((feature, i) => (
            <motion.div
              key={feature.title}     /* 제목을 고유 key로 사용 */
              className="card"         /* index.css의 카드 기본 스타일 적용 */
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: '-60px' }}
              /* delay: i * 0.08 — 카드마다 80ms씩 늦게 등장하여 순차 효과 */
              transition={{ duration: 0.5, delay: i * 0.08 }}
              style={{ padding: '32px', cursor: 'default' }}
            >
              {/* 아이콘 컨테이너 — 기능의 주 색상을 배경으로 사용 */}
              <div style={{
                width: '56px', height: '56px',
                borderRadius: '14px',
                background: feature.bg,      /* 반투명 배경 */
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: feature.color,         /* SVG의 currentColor에 영향 */
                marginBottom: '20px',
              }}>
                {feature.icon} {/* JSX로 정의된 SVG 아이콘 */}
              </div>

              {/* 기술 카테고리 뱃지 */}
              <div style={{
                display: 'inline-block',
                padding: '3px 10px',
                borderRadius: '50px',
                background: feature.bg,
                fontSize: '0.7rem',
                fontWeight: 700,
                color: feature.color,
                marginBottom: '12px',
                letterSpacing: '0.03em',
              }}>
                {feature.badge}
              </div>

              {/* 기능 제목 */}
              <h3 style={{
                fontSize: '1.1rem',
                fontWeight: 700,
                color: 'var(--text-primary)',
                marginBottom: '10px',
                letterSpacing: '-0.02em',
              }}>
                {feature.title}
              </h3>

              {/* 기능 설명 */}
              <p style={{
                fontSize: '0.9rem',
                color: 'var(--text-secondary)',
                lineHeight: 1.65,
              }}>
                {feature.description}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
