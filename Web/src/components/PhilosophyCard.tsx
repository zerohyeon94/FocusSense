/**
 * ============================================================
 * PhilosophyCard.tsx — 철학/가치 카드 컴포넌트
 * ============================================================
 * Philosophy.tsx에서 반복 사용하는 카드 UI를 별도 컴포넌트로 분리합니다.
 *
 * 컴포넌트 분리의 장점:
 * - 재사용 가능 (다른 섹션에서도 사용 가능)
 * - 단일 책임 원칙 (카드 UI만 담당)
 * - 코드 가독성 향상
 * ============================================================
 */

import { motion } from 'framer-motion';

/**
 * CardProps: 이 컴포넌트가 받는 Props의 TypeScript 인터페이스
 *
 * 인터페이스(interface): 객체의 구조를 미리 정의합니다.
 * ?  (선택적 속성): delay?는 전달하지 않아도 됩니다.
 *                  전달하지 않으면 기본값(= 0)이 사용됩니다.
 */
interface CardProps {
  icon: string;          /* 이모지 문자열 (예: '🎯', '📊', '🔒') */
  title: string;         /* 카드 제목 */
  description: string;   /* 카드 설명 본문 */
  delay?: number;        /* 등장 애니메이션 딜레이 (초 단위, 선택적) */
  color: string;         /* 하단 강조 바 색상 (hex) */
  bg: string;            /* 아이콘 배경 색상 (rgba) */
}

/**
 * PhilosophyCard 컴포넌트
 * Props를 구조 분해(Destructuring)하며, delay의 기본값을 0으로 설정합니다.
 * { delay = 0 }: delay가 undefined일 때 0을 사용합니다.
 */
export default function PhilosophyCard({ icon, title, description, delay = 0, color, bg }: CardProps) {
  return (
    /*
      motion.div + className="card":
      - className="card": index.css의 카드 스타일 (둥근 모서리, 테두리, 호버 효과)
      - motion.div: framer-motion 애니메이션 래퍼

      flex: '1 1 260px':
      - 1(grow): 남은 공간을 채우도록 늘어날 수 있음
      - 1(shrink): 필요시 줄어들 수 있음
      - 260px: 기본(기준) 크기
      → flex 컨테이너에서 최소 260px를 유지하며 공간에 맞게 조절됩니다.

      initial → whileInView 애니메이션:
      - y: 40 → 0: 40px 아래에서 위로 올라오며 등장
      - opacity: 0 → 1: 투명에서 불투명으로

      whileHover: 마우스 오버 시 위로 6px 이동 + 그림자
    */
    <motion.div
      className="card"
      style={{ padding: '40px 32px', textAlign: 'center', cursor: 'default', flex: '1 1 260px' }}
      initial={{ opacity: 0, y: 40 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-50px' }}
      transition={{ duration: 0.6, delay, ease: 'easeOut' }} /* delay prop 사용 */
      whileHover={{ y: -6, boxShadow: '0 16px 40px rgba(0,0,0,0.1)' }}
    >
      {/* 이모지 아이콘 컨테이너
          margin: '0 auto 24px': 가운데 정렬 + 하단 여백 24px */}
      <div style={{
        width: '72px', height: '72px',
        borderRadius: '20px',
        background: bg,              /* 반투명 컬러 배경 */
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: '2rem',            /* 이모지 크기 조절 */
        margin: '0 auto 24px',
      }}>
        {icon} {/* 이모지 문자 렌더링 */}
      </div>

      {/* 카드 제목 */}
      <h3 style={{
        fontSize: '1.2rem',
        fontWeight: 700,
        color: 'var(--text-primary)',
        marginBottom: '12px',
        letterSpacing: '-0.02em',
      }}>
        {title}
      </h3>

      {/* 카드 설명 본문 */}
      <p style={{
        fontSize: '0.9rem',
        color: 'var(--text-secondary)',
        lineHeight: 1.7, /* 넉넉한 행간으로 가독성 향상 */
      }}>
        {description}
      </p>

      {/* 하단 색상 강조 바
          CSS 트릭: marginTop과 margin을 모두 선언하면
          나중에 선언된 margin: '24px auto 0' 이 우선 적용됩니다.
          → 결과: 상단 24px 여백 + 좌우 auto(가운데 정렬) + 하단 0 */}
      <div style={{
        marginTop: '24px',
        width: '32px',
        height: '3px',
        borderRadius: '2px',
        background: color, /* props로 받은 색상 적용 */
        margin: '24px auto 0',
      }} />
    </motion.div>
  );
}
