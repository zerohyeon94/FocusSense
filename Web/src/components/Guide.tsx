/**
 * ============================================================
 * Guide.tsx — 기기 배치 및 시작 가이드 섹션
 * ============================================================
 * 앱을 올바르게 사용하기 위한 4단계 환경 설정 방법을 안내합니다.
 * 두 개의 서브 컴포넌트로 구성됩니다:
 *   1. PhoneMockupStand — 거치대에 올린 스마트폰 정적 일러스트
 *   2. Guide (default export) — 단계 목록 + 폰 목업 레이아웃
 * ============================================================
 */

import { motion } from 'framer-motion';

/**
 * steps: 사용 시작 단계 데이터
 * number: 단계 번호 (원형 배지에 표시)
 * icon  : 이모지 아이콘 (제목 왼쪽에 표시)
 * tip   : 팁 뱃지에 표시되는 단축 조언
 */
const steps = [
  {
    number: '01',
    icon: '📱',
    title: '거치대에 스마트폰 고정',
    description: '시선과 비슷한 높이에 스마트폰을 거치해 주세요. 전면 카메라가 얼굴을 정면으로 바라볼수록 감지 정확도가 높아집니다.',
    tip: '책상 위 거치대 또는 모니터 옆 추천',
  },
  {
    number: '02',
    icon: '💡',
    title: '적절한 조명 확보',
    description: '너무 어두운 환경에서는 눈 인식 정확도가 낮아질 수 있습니다. 스탠드나 자연광으로 얼굴이 밝게 보이도록 해주세요.',
    tip: '역광 환경 (창문 뒤) 은 피해주세요',
  },
  {
    number: '03',
    icon: '🎯',
    title: '캘리브레이션 실행',
    description: '처음 사용 시 앱 내 "위치 설정" 버튼을 눌러 개인 눈 기준값을 교정해 주세요. 이 과정이 측정 정확도를 크게 높여줍니다.',
    tip: '안경 착용자도 캘리브레이션 후 정확 감지',
  },
  {
    number: '04',
    icon: '▶️',
    title: '타이머 시작',
    description: 'AI가 실시간으로 집중 상태를 분석합니다. 졸음이 감지되면 자동으로 일시정지되고, 돌아오면 알림 후 재개됩니다.',
    tip: '세션 후 "AI 분석 보기"로 상세 데이터 확인',
  },
];

/**
 * PhoneMockupStand 컴포넌트
 * 거치대(스탠드)에 올려진 스마트폰을 CSS로 묘사한 정적 일러스트입니다.
 * 구성 요소:
 *   - Ambient glow  : 배경 발광 효과
 *   - Phone body    : 스마트폰 본체
 *   - Camera feed   : 카메라 뷰파인더 시뮬레이션
 *   - Face outline  : 얼굴 감지 오버레이
 *   - Corner lines  : 스캔 UI 모서리 선
 *   - Stand neck    : 거치대 기둥
 *   - Stand base    : 거치대 받침
 *   - Desk surface  : 책상 표면 선
 */
function PhoneMockupStand() {
  return (
    /* 수직 flex 컨테이너 — 폰 + 거치대 + 책상을 세로로 쌓습니다 */
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', position: 'relative' }}>

      {/* 주변 발광(Ambient Glow) 효과
          position: absolute + zIndex: 0 으로 폰 뒤에 배치
          filter: blur(20px): 흐릿하게 처리하여 은은한 빛 효과
          pointerEvents: none: 마우스 이벤트를 통과시킴 */}
      <div style={{
        position: 'absolute',
        top: '20%', left: '50%',
        transform: 'translateX(-50%)',
        width: '200px', height: '200px',
        background: 'radial-gradient(ellipse, rgba(0,122,255,0.15) 0%, transparent 70%)',
        filter: 'blur(20px)',
        pointerEvents: 'none',
        zIndex: 0,
      }} />

      {/* 스마트폰 본체
          zIndex: 1 — 글로우 효과 위에 표시 */}
      <div style={{
        width: '180px',
        height: '360px',
        borderRadius: '40px',
        background: 'linear-gradient(170deg, #2a2a3a 0%, #1a1a2e 100%)',
        border: '7px solid #333344',
        position: 'relative',
        overflow: 'hidden',
        boxShadow: '0 30px 60px rgba(0,0,0,0.4), 0 0 0 1px rgba(255,255,255,0.05) inset',
        zIndex: 1,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        padding: '16px 14px 20px',
        gap: '10px',
      }}>
        {/* 노치 */}
        <div style={{ width: '70px', height: '5px', backgroundColor: '#333344', borderRadius: '3px', flexShrink: 0 }} />

        {/* 얼굴 감지 오버레이 컨테이너 (카메라 뷰파인더 영역) */}
        <div style={{ width: '100%', flex: 1, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>

          {/* 카메라 피드 시뮬레이션 — 어두운 배경으로 카메라 화면 표현 */}
          <div style={{
            width: '100%', height: '100%',
            borderRadius: '16px',
            background: 'linear-gradient(180deg, #0a0a14 0%, #151520 100%)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            position: 'relative',
            overflow: 'hidden',
          }}>

            {/* 얼굴 윤곽선
                borderRadius: '50% / 45% 45% 55% 55%'
                — X축 50%, Y축 상단 45%/하단 55%의 비대칭 타원으로 얼굴 모양 표현
                  (CSS border-radius의 / 문법: 가로/세로 반경을 각각 지정) */}
            <div style={{
              width: '80px', height: '100px',
              borderRadius: '50% / 45% 45% 55% 55%',
              border: '1.5px solid rgba(0,122,255,0.6)',
              boxShadow: '0 0 20px rgba(0,122,255,0.2)', /* 파란 글로우로 AI 감지 느낌 */
              position: 'relative',
            }}>
              {/* 왼쪽 눈 — 타원형으로 표현 */}
              <div style={{ position: 'absolute', top: '35%', left: '18%', width: '18px', height: '7px', borderRadius: '50%', background: 'rgba(0,122,255,0.8)' }} />
              {/* 오른쪽 눈 */}
              <div style={{ position: 'absolute', top: '35%', right: '18%', width: '18px', height: '7px', borderRadius: '50%', background: 'rgba(0,122,255,0.8)' }} />
              {/* EAR 측정선 (왼쪽) — 초록 가로선으로 눈 위의 측정 포인트 표현 */}
              <div style={{ position: 'absolute', top: '29%', left: '16%', width: '22px', height: '1px', background: 'rgba(48,209,88,0.7)' }} />
              {/* EAR 측정선 (오른쪽) */}
              <div style={{ position: 'absolute', top: '29%', right: '16%', width: '22px', height: '1px', background: 'rgba(48,209,88,0.7)' }} />
            </div>

            {/* 코너 스캔 라인 — 카메라 뷰파인더 UI의 네 모서리 표시
                배열의 스타일 객체를 map()으로 렌더링합니다.
                스프레드 연산자(...s)로 각 모서리의 위치/테두리를 적용합니다. */}
            {[
              { top: '8px',    left: '8px',  borderTop:    '2px solid #007AFF', borderLeft:   '2px solid #007AFF' },
              { top: '8px',    right: '8px', borderTop:    '2px solid #007AFF', borderRight:  '2px solid #007AFF' },
              { bottom: '8px', left: '8px',  borderBottom: '2px solid #007AFF', borderLeft:   '2px solid #007AFF' },
              { bottom: '8px', right: '8px', borderBottom: '2px solid #007AFF', borderRight:  '2px solid #007AFF' },
            ].map((s, i) => (
              <div key={i} style={{ position: 'absolute', width: '16px', height: '16px', ...s }} />
            ))}

            {/* 집중 상태 표시 뱃지 (카메라 화면 하단 중앙)
                position: absolute + left: 50% + transform: translateX(-50%): 수평 중앙 정렬 */}
            <div style={{
              position: 'absolute',
              bottom: '10px', left: '50%', transform: 'translateX(-50%)',
              display: 'flex', alignItems: 'center', gap: '5px',
              padding: '4px 10px',
              borderRadius: '50px',
              background: 'rgba(48,209,88,0.15)',
              border: '1px solid rgba(48,209,88,0.3)',
            }}>
              {/* 초록 점 — boxShadow로 빛나는 효과 */}
              <div style={{ width: '5px', height: '5px', borderRadius: '50%', background: '#30D158', boxShadow: '0 0 6px #30D158' }} />
              <span style={{ fontSize: '0.6rem', color: '#30D158', fontWeight: 600 }}>집중 중</span>
            </div>
          </div>
        </div>

        {/* EAR 값 표시 바 (폰 하단) */}
        <div style={{
          width: '100%',
          padding: '8px 10px',
          background: 'rgba(255,255,255,0.04)',
          borderRadius: '10px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexShrink: 0,
        }}>
          <span style={{ fontSize: '0.6rem', color: 'rgba(255,255,255,0.4)' }}>EAR 비율</span>
          {/* 0.82: 정상 눈뜸 상태의 EAR 값 (정상 ~0.3, 졸음 <0.2 기준 비율) */}
          <span style={{ fontFamily: 'monospace', fontSize: '0.65rem', color: '#30D158', fontWeight: 600 }}>0.82</span>
        </div>
      </div>

      {/* 거치대 기둥(Neck)
          marginTop: -2px: 폰 하단과 자연스럽게 이어지도록 약간 겹침 */}
      <div style={{
        width: '10px',
        height: '50px',
        background: 'linear-gradient(180deg, #3a3a4a, #2a2a38)',
        zIndex: 1,
        marginTop: '-2px',
      }} />

      {/* 거치대 받침(Base) */}
      <div style={{
        width: '160px',
        height: '14px',
        background: 'linear-gradient(180deg, #3a3a4a, #2a2a38)',
        borderRadius: '7px',
        zIndex: 1,
        boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
      }} />

      {/* 책상 표면 선 — 받침 아래의 얇은 가로선 */}
      <div style={{
        width: '220px',
        height: '3px',
        background: 'var(--border)', /* 테마에 따라 색상이 자동 변경 */
        borderRadius: '2px',
        marginTop: '8px',
        zIndex: 1,
      }} />
    </div>
  );
}

/**
 * Guide 컴포넌트 (기본 export)
 * id="guide": '#guide' 앵커와 연결
 * 좌: 4단계 가이드 목록 / 우: PhoneMockupStand 일러스트
 */
export default function Guide() {
  return (
    <section id="guide" className="section" style={{ backgroundColor: 'var(--bg-main)', transition: 'background-color 0.3s' }}>
      <div className="container">

        {/* ── 섹션 헤더 ── */}
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-80px' }}
          transition={{ duration: 0.6 }}
          style={{ textAlign: 'center', marginBottom: '72px' }}
        >
          <span className="section-label">시작 가이드</span>
          <h2 className="section-title">최적의 집중을 위한<br />세팅 방법</h2>
          <p className="section-subtitle" style={{ margin: '0 auto' }}>
            올바른 환경 설정으로 AI 감지 정확도를 최대한으로 높이세요.
          </p>
        </motion.div>

        {/* ── 본문: 좌(단계 목록) + 우(폰 일러스트) ── */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '80px',
          flexWrap: 'wrap',        /* 모바일에서 세로로 쌓임 */
          justifyContent: 'center',
        }}>

          {/* ── 왼쪽: 단계 목록 ──
              x: -24 → 0 (왼쪽에서 오른쪽으로 슬라이드 등장) */}
          <motion.div
            initial={{ opacity: 0, x: -24 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: '-60px' }}
            transition={{ duration: 0.6 }}
            style={{ flex: '1 1 360px', maxWidth: '480px' }}
          >
            {steps.map((step, i) => (
              <motion.div
                key={step.number}
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true, margin: '-40px' }}
                /* 각 단계 100ms 간격 순차 등장 */
                transition={{ duration: 0.5, delay: i * 0.1 }}
                style={{
                  display: 'flex',
                  gap: '20px',
                  /* 마지막 항목은 하단 여백 없음 */
                  marginBottom: i < steps.length - 1 ? '32px' : 0,
                  position: 'relative',
                }}
              >
                {/* 단계 연결선 (세로 점선)
                    마지막 항목(i === steps.length - 1)에는 렌더링하지 않습니다.
                    position: absolute, left: 21px (원형 배지 중앙)
                    height: calc(100% + 12px): 다음 단계까지 이어지는 길이 */}
                {i < steps.length - 1 && (
                  <div style={{
                    position: 'absolute',
                    left: '21px',                    /* 44px 원형 배지의 중앙 */
                    top: '44px',                     /* 원형 배지 아래에서 시작 */
                    width: '2px',
                    height: 'calc(100% + 12px)',     /* 다음 단계까지 연결 */
                    background: 'var(--border)',
                  }} />
                )}

                {/* 단계 번호 원형 배지
                    zIndex: 1 — 연결선 위에 표시 */}
                <div style={{
                  width: '44px', height: '44px',
                  borderRadius: '50%',
                  background: 'var(--bg-sub)',
                  border: '2px solid var(--primary)', /* 파란 테두리 */
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,                      /* flex에서 줄어들지 않도록 */
                  fontSize: '0.75rem',
                  fontWeight: 800,
                  color: 'var(--primary)',
                  fontFamily: 'monospace',
                  zIndex: 1,                          /* 연결선 위 레이어 */
                }}>
                  {step.number}
                </div>

                {/* 단계 콘텐츠 영역 */}
                <div style={{ paddingTop: '6px' }}>
                  {/* 이모지 아이콘 + 제목 */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                    <span style={{ fontSize: '1.1rem' }}>{step.icon}</span>
                    <h3 style={{
                      fontSize: '1.05rem',
                      fontWeight: 700,
                      color: 'var(--text-primary)',
                      letterSpacing: '-0.02em',
                    }}>
                      {step.title}
                    </h3>
                  </div>

                  {/* 단계 설명 */}
                  <p style={{
                    fontSize: '0.875rem',
                    color: 'var(--text-secondary)',
                    lineHeight: 1.65,
                    marginBottom: '8px',
                  }}>
                    {step.description}
                  </p>

                  {/* 팁 뱃지 — 인라인 flex로 💡 + 텍스트 정렬 */}
                  <div style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '4px 10px',
                    borderRadius: '50px',
                    background: 'rgba(0,122,255,0.07)',
                    border: '1px solid rgba(0,122,255,0.15)',
                  }}>
                    <span style={{ fontSize: '0.6rem', color: 'var(--primary)' }}>💡</span>
                    <span style={{ fontSize: '0.72rem', color: 'var(--primary)', fontWeight: 500 }}>{step.tip}</span>
                  </div>
                </div>
              </motion.div>
            ))}
          </motion.div>

          {/* ── 오른쪽: 폰 거치대 일러스트 ──
              x: 24 → 0 (오른쪽에서 왼쪽으로 슬라이드)
              delay: 0.2 → 왼쪽 콘텐츠보다 0.2초 늦게 등장 */}
          <motion.div
            initial={{ opacity: 0, x: 24 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: '-60px' }}
            transition={{ duration: 0.6, delay: 0.2 }}
            style={{ flex: '0 0 auto', display: 'flex', justifyContent: 'center' }}
          >
            <PhoneMockupStand />
          </motion.div>
        </div>
      </div>
    </section>
  );
}
