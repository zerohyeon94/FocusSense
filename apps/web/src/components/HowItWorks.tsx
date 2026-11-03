/**
 * ============================================================
 * HowItWorks.tsx — AI 작동 원리 섹션
 * ============================================================
 * FocusSense의 집중도 측정 4단계 프로세스를 설명합니다:
 *   STEP 01: 얼굴 감지 (Face Detection)
 *   STEP 02: EAR 계산 (Eye Aspect Ratio)
 *   STEP 03: CoreML 검증 (AI Hybrid Analysis)
 *   STEP 04: 상태 판정 (Focus Level Decision)
 * 하단에는 하이브리드 점수 계산 공식을 시각화합니다.
 * ============================================================
 */

import { motion } from 'framer-motion';

/**
 * steps: AI 분석 단계 데이터 배열
 * 각 단계는 단계 번호, 색상, 제목, 영문 부제목, 설명, 기술 상세를 포함합니다.
 *
 * detail: 실제 알고리즘 공식이나 임계값을 코드 스타일로 표시
 *         (모노스페이스 폰트 + 단계 색상 적용)
 */
const steps = [
  {
    number: '01',
    color: '#007AFF', /* 파란색 — Vision Framework 단계 */
    title: '얼굴 감지',
    subtitle: 'Face Detection',
    description: 'Vision Framework가 전면 카메라에서 얼굴을 실시간으로 감지합니다. 얼굴이 없으면 즉시 "자리 비움" 상태로 전환됩니다.',
    detail: '3초 이상 감지 안 되면 자동 일시정지',
    /* stroke 스타일 SVG: fill="none" + stroke로 아웃라인 아이콘 */
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none">
        {/* strokeLinecap="round": 선 끝을 둥글게 처리 */}
        <path d="M9 3H5a2 2 0 00-2 2v4m6-6h10a2 2 0 012 2v4M9 3v18m0 0h10a2 2 0 002-2V9M9 21H5a2 2 0 01-2-2V9m0 0h18" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
        <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.5"/>
      </svg>
    ),
  },
  {
    number: '02',
    color: '#30D158', /* 초록색 — EAR 계산 단계 */
    title: 'EAR 계산',
    subtitle: 'Eye Aspect Ratio',
    description: '68개의 얼굴 랜드마크를 이용해 EAR 값을 계산합니다. 개인별 캘리브레이션으로 보정된 비율로 졸음을 판단합니다.',
    /* EAR 공식: 눈의 세로 길이 합 / (2 × 가로 길이) */
    detail: 'EAR = (|p2-p6| + |p3-p5|) / (2 × |p1-p4|)',
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none">
        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
        <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.5"/>
      </svg>
    ),
  },
  {
    number: '03',
    color: '#BF5AF2', /* 보라색 — CoreML AI 모델 단계 */
    title: 'CoreML 검증',
    subtitle: 'AI Hybrid Analysis',
    description: '온디바이스 CoreML 모델이 추가 검증을 수행합니다. Vision 70% + CoreML 30%의 가중 평균으로 최종 졸음 점수를 산출합니다.',
    /* 하이브리드 가중 평균 공식 */
    detail: '결합 점수 = 0.7 × Vision + 0.3 × CoreML',
    /* 레이어 아이콘 — AI 모델의 레이어 구조를 표현 */
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none">
        {/* strokeLinejoin="round": 꺾임 부분을 둥글게 */}
        <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    ),
  },
  {
    number: '04',
    color: '#FF9F0A', /* 주황색 — 최종 판정 단계 */
    title: '상태 판정',
    subtitle: 'Focus Level Decision',
    description: '결합 점수를 기반으로 집중 / 주의 / 졸음 상태를 판정합니다. 2초 이상 졸음이 지속되면 타이머가 자동 일시정지됩니다.',
    /* 임계값(Threshold) — 0.3과 0.6을 기준으로 3단계 구분 */
    detail: '< 0.3 집중 | 0.3~0.6 주의 | > 0.6 졸음',
    /* 체크 아이콘 — 최종 판정/확인 의미 */
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none">
        <path d="M22 11.08V12a10 10 0 11-5.93-9.14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
        <path d="M22 4L12 14.01l-3-3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    ),
  },
];

/**
 * HowItWorks 컴포넌트
 * id="how-it-works": '#how-it-works' 앵커 링크와 연결
 */
export default function HowItWorks() {
  return (
    <section id="how-it-works" className="section" style={{ backgroundColor: 'var(--bg-main)', transition: 'background-color 0.3s' }}>
      <div className="container">

        {/* ── 섹션 헤더 ── */}
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-80px' }}
          transition={{ duration: 0.6 }}
          style={{ textAlign: 'center', marginBottom: '72px' }}
        >
          <span className="section-label">작동 원리</span>
          <h2 className="section-title">어떻게 집중도를 측정하나요?</h2>
          <p className="section-subtitle" style={{ margin: '0 auto' }}>
            Vision Framework와 CoreML의 하이브리드 방식으로 정확하고 빠르게,
            그리고 완전히 오프라인으로 처리됩니다.
          </p>
        </motion.div>

        {/* ── 단계 카드 영역 ── */}
        <div style={{ position: 'relative' }}>

          {/* 단계 연결선 (데스크톱 전용, 현재 display:none)
              카드 상단을 가로지르는 그라디언트 선으로 흐름을 시각화합니다.
              display:none이어서 현재는 보이지 않습니다. */}
          <div style={{
            position: 'absolute',
            top: '40px',
            left: '40px',
            right: '40px',
            height: '2px',
            background: 'linear-gradient(90deg, #007AFF, #30D158, #BF5AF2, #FF9F0A)',
            opacity: 0.2,
            display: 'none', /* 현재 비활성 */
          }} className="step-line" />

          {/* 4단계 카드 그리드
              minmax(220px, 1fr): 각 카드 최소 220px, 남은 공간 균등 분배 */}
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
            gap: '24px',
          }}>
            {steps.map((step, i) => (
              <motion.div
                key={step.number}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-60px' }}
                /* 각 카드를 120ms 간격으로 순차 등장 */
                transition={{ duration: 0.5, delay: i * 0.12 }}
                style={{
                  padding: '32px 24px',
                  borderRadius: '20px',
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border)',
                  position: 'relative',
                  overflow: 'hidden', /* 배경 accent 원이 카드 밖으로 나가지 않도록 */
                  transition: 'all 0.3s',
                }}
                /* whileHover: 마우스 올림 시 위로 6px 이동 + 그림자 */
                whileHover={{ y: -6, boxShadow: '0 16px 40px rgba(0,0,0,0.1)' }}
              >
                {/* 우상단 배경 장식 원
                    position:absolute로 카드 우측 상단에 배치
                    ${step.color}10: hex 색상 + 10(hex) = 6.25% 투명도 */}
                <div style={{
                  position: 'absolute',
                  top: '-30px', right: '-30px',
                  width: '100px', height: '100px',
                  borderRadius: '50%',
                  background: `${step.color}10`,
                }} />

                {/* 단계 번호 레이블 */}
                <div style={{
                  fontSize: '0.7rem',
                  fontWeight: 800,
                  color: step.color,
                  letterSpacing: '0.1em',
                  marginBottom: '16px',
                  fontFamily: 'monospace', /* 코드 느낌의 모노스페이스 폰트 */
                }}>
                  STEP {step.number}
                </div>

                {/* 단계 아이콘 박스
                    ${step.color}15: hex + 15(hex) = 8.2% 투명도 배경 */}
                <div style={{
                  width: '56px', height: '56px',
                  borderRadius: '14px',
                  background: `${step.color}15`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: step.color, /* SVG의 currentColor에 영향 */
                  marginBottom: '20px',
                }}>
                  {step.icon}
                </div>

                {/* 단계 제목 */}
                <h3 style={{
                  fontSize: '1.15rem',
                  fontWeight: 700,
                  color: 'var(--text-primary)',
                  marginBottom: '4px',
                  letterSpacing: '-0.02em',
                }}>
                  {step.title}
                </h3>

                {/* 영문 부제목 — 기술 용어를 함께 표시 */}
                <div style={{
                  fontSize: '0.72rem',
                  color: step.color,
                  fontWeight: 600,
                  marginBottom: '12px',
                  letterSpacing: '0.02em',
                }}>
                  {step.subtitle}
                </div>

                {/* 단계 설명 본문 */}
                <p style={{
                  fontSize: '0.875rem',
                  color: 'var(--text-secondary)',
                  lineHeight: 1.65,
                  marginBottom: '16px',
                }}>
                  {step.description}
                </p>

                {/* 기술 상세 (코드 블록 스타일)
                    실제 알고리즘 공식이나 임계값을 개발자 친화적으로 표시 */}
                <div style={{
                  padding: '8px 12px',
                  borderRadius: '8px',
                  background: 'var(--bg-sub)',
                  fontFamily: 'SF Mono, Menlo, monospace', /* 코드용 모노스페이스 */
                  fontSize: '0.72rem',
                  color: step.color,
                  letterSpacing: '0.01em',
                }}>
                  {step.detail}
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        {/* ── 하이브리드 점수 계산 시각화 ──
            스크롤이 완료된 후 0.3초 delay로 등장합니다. */}
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-60px' }}
          transition={{ duration: 0.6, delay: 0.3 }}
          style={{
            marginTop: '48px',
            padding: '40px',
            borderRadius: '24px',
            background: 'var(--bg-sub)',
            border: '1px solid var(--border)',
          }}
        >
          <h3 style={{
            fontSize: '1.1rem',
            fontWeight: 700,
            color: 'var(--text-primary)',
            textAlign: 'center',
            marginBottom: '32px',
            letterSpacing: '-0.02em',
          }}>
            하이브리드 점수 계산 방식
          </h3>

          {/* 70% + 30% = 결합 점수 시각화
              flexWrap: wrap — 좁은 화면에서 세로로 쌓임 */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '16px',
            flexWrap: 'wrap',
          }}>
            {/* Vision EAR 70% 카드 */}
            <div style={{ textAlign: 'center', padding: '20px 28px', background: 'var(--bg-card)', borderRadius: '16px', border: '1px solid var(--border)', minWidth: '140px' }}>
              <div style={{ fontSize: '2rem', fontWeight: 800, color: '#007AFF', marginBottom: '4px' }}>70%</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Vision EAR</div>
            </div>

            {/* + 연산자 */}
            <div style={{ fontSize: '1.5rem', color: 'var(--text-tertiary)', fontWeight: 300 }}>+</div>

            {/* CoreML 30% 카드 */}
            <div style={{ textAlign: 'center', padding: '20px 28px', background: 'var(--bg-card)', borderRadius: '16px', border: '1px solid var(--border)', minWidth: '140px' }}>
              <div style={{ fontSize: '2rem', fontWeight: 800, color: '#BF5AF2', marginBottom: '4px' }}>30%</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>CoreML 모델</div>
            </div>

            {/* = 연산자 */}
            <div style={{ fontSize: '1.5rem', color: 'var(--text-tertiary)', fontWeight: 300 }}>=</div>

            {/* 결합 점수 결과 카드 — 두 색상의 그라디언트 배경과 텍스트 */}
            <div style={{ textAlign: 'center', padding: '20px 28px', background: 'linear-gradient(135deg, rgba(0,122,255,0.1), rgba(191,90,242,0.1))', borderRadius: '16px', border: '1px solid rgba(0,122,255,0.2)', minWidth: '140px' }}>
              {/* 그라디언트 텍스트 — gradient-text 클래스와 동일한 기법을 인라인으로 구현 */}
              <div style={{ fontSize: '2rem', fontWeight: 800, background: 'linear-gradient(135deg, #007AFF, #BF5AF2)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', marginBottom: '4px' }}>결합</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>최종 졸음 점수</div>
            </div>
          </div>

          {/* ── 임계값 기준 색상 바 ──
              0~1 사이 점수를 3구간으로 색상 구분하여 시각화합니다.
              linear-gradient의 하드 스톱(color-stop):
              - 30%까지 초록 (#30D158)
              - 30%~60% 노란 (#FFD60A)
              - 60%~100% 빨간 (#FF453A) */}
          <div style={{ marginTop: '32px', maxWidth: '500px', margin: '32px auto 0' }}>
            {/* 눈금 레이블 */}
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
              <span style={{ fontSize: '0.78rem', color: 'var(--text-tertiary)' }}>0</span>
              <span style={{ fontSize: '0.78rem', color: 'var(--text-tertiary)' }}>0.3</span>
              <span style={{ fontSize: '0.78rem', color: 'var(--text-tertiary)' }}>0.6</span>
              <span style={{ fontSize: '0.78rem', color: 'var(--text-tertiary)' }}>1.0</span>
            </div>
            {/* 색상 그라디언트 바 — 동일 색상이 연속되어 하드 스톱 효과 */}
            <div style={{ height: '12px', borderRadius: '6px', background: 'linear-gradient(90deg, #30D158 0%, #30D158 30%, #FFD60A 30%, #FFD60A 60%, #FF453A 60%, #FF453A 100%)', position: 'relative' }}>
            </div>
            {/* 상태 레이블 */}
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '8px' }}>
              <span style={{ fontSize: '0.75rem', color: '#30D158', fontWeight: 600 }}>집중 중</span>
              <span style={{ fontSize: '0.75rem', color: '#FFD60A', fontWeight: 600 }}>주의</span>
              <span style={{ fontSize: '0.75rem', color: '#FF453A', fontWeight: 600 }}>졸음 감지</span>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
