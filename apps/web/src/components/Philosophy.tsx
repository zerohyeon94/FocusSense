/**
 * ============================================================
 * Philosophy.tsx — 앱의 방향성/철학 섹션
 * ============================================================
 * FocusSense의 핵심 원칙과 3가지 가치를 소개합니다.
 * - 핵심 원칙 콜아웃 박스 (눈에 띄는 인용구 형태)
 * - 3개의 PhilosophyCard 컴포넌트로 세부 가치 표현
 *
 * 컴포넌트 분리의 예시:
 * Philosophy.tsx  → 데이터와 레이아웃 담당
 * PhilosophyCard  → 반복되는 카드 UI 담당
 * ============================================================
 */

import { motion } from 'framer-motion';
/**
 * PhilosophyCard: 공통 카드 UI 컴포넌트
 * 재사용 가능한 카드를 별도 파일로 분리하여 단일 책임 원칙(SRP)을 따릅니다.
 */
import PhilosophyCard from './PhilosophyCard';

/**
 * items: 철학 카드 데이터 배열
 * 아이콘은 이모지 문자열(string)을 사용합니다.
 * (Features.tsx의 SVG와 달리, 여기서는 이모지로 단순화)
 */
const items = [
  {
    icon: '🎯',
    color: '#007AFF',
    bg: 'rgba(0,122,255,0.1)',
    title: '정확한 측정',
    description: '카메라 방향이 아닌 눈 상태와 존재 여부로만 집중도를 판단합니다. 모니터를 보며 코딩 중인 당신도 "집중 중"으로 인식합니다.',
  },
  {
    icon: '📊',
    color: '#30D158',
    bg: 'rgba(48,209,88,0.1)',
    title: '데이터 인사이트',
    description: '단순 타이머를 넘어, 시간대별·요일별 집중 패턴을 분석해 당신이 언제 가장 효율적인지 데이터로 보여드립니다.',
  },
  {
    icon: '🔒',
    color: '#BF5AF2',
    bg: 'rgba(191,90,242,0.1)',
    title: '완전한 프라이버시',
    description: '모든 AI 분석은 기기 내에서만 처리됩니다. 카메라 영상은 절대 서버로 전송되지 않으며, 당신의 데이터는 당신의 것입니다.',
  },
];

/**
 * Philosophy 컴포넌트
 * id="philosophy": '#philosophy' 앵커와 연결
 */
export default function Philosophy() {
  return (
    <section id="philosophy" className="section" style={{ backgroundColor: 'var(--bg-sub)', transition: 'background-color 0.3s' }}>
      <div className="container">

        {/* ── 섹션 헤더 ── */}
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-80px' }}
          transition={{ duration: 0.6 }}
          style={{ textAlign: 'center', marginBottom: '64px' }}
        >
          <span className="section-label">우리의 방향성</span>
          <h2 className="section-title">FocusSense가 다른 이유</h2>
          <p className="section-subtitle" style={{ margin: '0 auto' }}>
            단순히 시간을 재는 앱이 아닙니다. AI가 진짜 집중을 구분하고,
            당신의 학습을 더 깊이 이해합니다.
          </p>
        </motion.div>

        {/* ── 핵심 원칙 콜아웃 박스 ──
            scale: 0.97 → 1 애니메이션: 살짝 작게 시작했다가 원래 크기로 등장
            두 색상의 diagonal 그라디언트 배경으로 고급스러운 느낌 */}
        <motion.div
          initial={{ opacity: 0, scale: 0.97 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true, margin: '-60px' }}
          transition={{ duration: 0.5 }}
          style={{
            padding: '32px 40px',
            borderRadius: '20px',
            /* 파란→보라 대각선 그라디언트 배경 */
            background: 'linear-gradient(135deg, rgba(0,122,255,0.08) 0%, rgba(191,90,242,0.08) 100%)',
            border: '1px solid rgba(0,122,255,0.15)',
            marginBottom: '48px',
            textAlign: 'center',
          }}
        >
          {/* 핵심 원칙 레이블 */}
          <div style={{
            fontSize: '0.72rem',
            fontWeight: 700,
            letterSpacing: '0.1em',
            color: 'var(--primary)',
            textTransform: 'uppercase',
            marginBottom: '12px',
          }}>
            핵심 원칙
          </div>

          {/* 원칙 인용구
              <span> 인라인 요소로 일부 텍스트에만 색상을 적용합니다.
              clamp(): 화면 크기에 따라 폰트 크기가 1rem~1.3rem 사이에서 조절 */}
          <p style={{
            fontSize: 'clamp(1rem, 2.5vw, 1.3rem)',
            fontWeight: 600,
            color: 'var(--text-primary)',
            lineHeight: 1.5,
            maxWidth: '600px',
            margin: '0 auto',
          }}>
            "카메라 방향이 아닌 <span style={{ color: 'var(--primary)' }}>존재 + 눈 상태</span>로 집중도를 판단합니다"
          </p>

          {/* 구체적 예시 — 인용구를 보완하는 부연 설명 */}
          <p style={{
            fontSize: '0.875rem',
            color: 'var(--text-secondary)',
            marginTop: '12px',
          }}>
            모니터를 보며 코딩 중인 당신 → 집중 중 ✅
          </p>
        </motion.div>

        {/* ── 철학 카드 그룹 ──
            flexWrap: wrap + flex: '1 1 260px' (PhilosophyCard 내부 스타일)로
            화면 너비에 따라 1~3열 자동 조절됩니다.

            items.map()으로 카드 데이터를 순회하며 PhilosophyCard를 렌더링합니다.
            delay={i * 0.15}: 카드마다 150ms 간격으로 순차 등장 */}
        <div style={{ display: 'flex', gap: '24px', flexWrap: 'wrap', justifyContent: 'center' }}>
          {items.map((item, i) => (
            <PhilosophyCard
              key={i}                    /* 인덱스를 key로 사용 (항목 순서가 고정된 경우) */
              icon={item.icon}           /* 이모지 문자열 */
              title={item.title}
              description={item.description}
              delay={i * 0.15}           /* 순차 등장 딜레이 */
              color={item.color}         /* 하단 색상 바에 사용 */
              bg={item.bg}               /* 아이콘 배경 색상 */
            />
          ))}
        </div>
      </div>
    </section>
  );
}
