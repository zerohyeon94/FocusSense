/**
 * ============================================================
 * Download.tsx — 다운로드 CTA(Call To Action) 섹션
 * ============================================================
 * 페이지 마지막 섹션으로, 앱 다운로드를 유도합니다.
 * - 앱 아이콘
 * - App Store / GitHub 다운로드 버튼
 * - 요구사항 뱃지 (iOS 버전, 가격, 프라이버시, 언어)
 *
 * framer-motion의 whileHover/whileTap 애니메이션으로
 * 버튼에 인터랙티브한 피드백을 제공합니다.
 * ============================================================
 */

import { motion } from 'framer-motion';

/**
 * Download 컴포넌트 (기본 export)
 * id="download": Header의 '#download' 앵커 링크와 연결
 * position: relative: 배경 장식 요소의 absolute 기준점
 * overflow: hidden  : 배경 글로우가 섹션 밖으로 나가지 않도록 클리핑
 */
export default function Download() {
  return (
    <section
      id="download"
      className="section"
      style={{
        backgroundColor: 'var(--bg-sub)',
        transition: 'background-color 0.3s',
        position: 'relative',
        overflow: 'hidden', /* 배경 글로우 클리핑 */
      }}
    >
      {/* 배경 장식 — 상단에 걸쳐있는 파란 방사형 그라디언트
          top: -100px: 섹션 위쪽으로 살짝 튀어나오게 배치
          pointerEvents: none: 클릭 이벤트를 방해하지 않음 */}
      <div style={{
        position: 'absolute',
        top: '-100px', left: '50%',
        transform: 'translateX(-50%)',
        width: '600px', height: '400px',
        background: 'radial-gradient(ellipse, rgba(0,122,255,0.1) 0%, transparent 70%)',
        pointerEvents: 'none',
      }} />

      {/* position: relative — 배경 장식(absolute) 위에 콘텐츠 표시 */}
      <div className="container" style={{ position: 'relative' }}>

        {/* 전체 콘텐츠를 감싸는 motion.div
            y: 32 → 0: 아래에서 위로 32px 이동하며 등장
            maxWidth + margin: auto: 가운데 정렬 */}
        <motion.div
          initial={{ opacity: 0, y: 32 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-80px' }}
          transition={{ duration: 0.7 }}
          style={{
            textAlign: 'center',
            maxWidth: '600px',
            margin: '0 auto',
          }}
        >
          {/* ── 앱 아이콘 ──
              3색 대각선 그라디언트(파란 → 연파란 → 보라)로 앱스토어 아이콘 스타일 표현
              boxShadow: 파란색 글로우로 입체감 부여 */}
          <div style={{
            width: '100px',
            height: '100px',
            borderRadius: '24px', /* iOS 앱 아이콘의 특유의 둥근 모서리 */
            background: 'linear-gradient(135deg, #007AFF 0%, #4DA3FF 50%, #BF5AF2 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            margin: '0 auto 32px',
            boxShadow: '0 20px 50px rgba(0,122,255,0.35)',
          }}>
            {/* 눈 모양 SVG 아이콘 — Header 로고보다 크게 52×52 */}
            <svg width="52" height="52" viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="4" fill="white" />
              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z" fill="white" opacity="0.4" />
              <path d="M12 6c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6zm0 10c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4z" fill="white" opacity="0.25" />
            </svg>
          </div>

          {/* 섹션 레이블, 제목, 설명 */}
          <span className="section-label">다운로드</span>

          <h2 className="section-title" style={{ marginBottom: '16px' }}>
            지금 시작하세요
          </h2>

          <p style={{
            fontSize: '1.1rem',
            color: 'var(--text-secondary)',
            lineHeight: 1.6,
            marginBottom: '48px',
          }}>
            AI가 측정하는 진짜 집중 시간.<br />
            FocusSense로 당신의 학습 효율을 극대화해 보세요.
          </p>

          {/* ── 다운로드 버튼 그룹 ── */}
          <div style={{ display: 'flex', gap: '16px', justifyContent: 'center', flexWrap: 'wrap', marginBottom: '48px' }}>

            {/* App Store 버튼 (검정 배경)
                motion.a: <a> 태그에 framer-motion 애니메이션 적용
                whileHover: 마우스 오버 시 scale 1.03배 확대 + 3px 위로 이동
                whileTap  : 클릭 시 살짝 줄어드는 피드백 효과 */}
            <motion.a
              href="#"
              whileHover={{ scale: 1.03, y: -3 }}
              whileTap={{ scale: 0.97 }}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                padding: '14px 28px',
                borderRadius: '16px',
                /* 검정/흰색 배경 — 다크모드에서 var(--text-primary)는 흰색이 됨 */
                background: 'var(--text-primary)',
                color: 'var(--bg-main)',            /* 배경과 반대 색상으로 텍스트 */
                border: '1px solid var(--border)',
                textDecoration: 'none',
                transition: 'box-shadow 0.2s',
                minWidth: '180px',
              }}
            >
              {/* 애플 로고 SVG — flexShrink: 0으로 크기 유지 */}
              <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" style={{ flexShrink: 0 }}>
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              {/* 2줄 텍스트: 작은 부제 + 굵은 앱스토어 이름 */}
              <div style={{ textAlign: 'left' }}>
                <div style={{ fontSize: '0.65rem', opacity: 0.7, lineHeight: 1 }}>다운로드</div>
                <div style={{ fontSize: '1rem', fontWeight: 700, letterSpacing: '-0.01em' }}>App Store</div>
              </div>
            </motion.a>

            {/* GitHub 버튼 (아웃라인 스타일)
                background: transparent + border 로 비어있는 버튼 스타일 */}
            <motion.a
              href="#"
              whileHover={{ scale: 1.03, y: -3 }}
              whileTap={{ scale: 0.97 }}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                padding: '14px 28px',
                borderRadius: '16px',
                background: 'transparent',
                color: 'var(--text-primary)',
                border: '1.5px solid var(--border-strong)', /* 더 진한 테두리 */
                textDecoration: 'none',
                minWidth: '180px',
              }}
            >
              {/* GitHub 로고 SVG — stroke(아웃라인) 스타일 */}
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ flexShrink: 0 }}>
                <path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              <div style={{ textAlign: 'left' }}>
                <div style={{ fontSize: '0.65rem', opacity: 0.6, lineHeight: 1 }}>오픈소스</div>
                <div style={{ fontSize: '1rem', fontWeight: 700, letterSpacing: '-0.01em' }}>GitHub</div>
              </div>
            </motion.a>
          </div>

          {/* ── 요구사항 뱃지 목록 ──
              배열.map()으로 4개의 뱃지를 렌더링합니다.
              key={item.label}: 레이블을 고유 key로 사용 */}
          <div style={{
            display: 'flex',
            gap: '24px',
            justifyContent: 'center',
            flexWrap: 'wrap', /* 좁은 화면에서 줄바꿈 */
          }}>
            {[
              { icon: '📱', label: 'iOS 17.0+' },    /* 최소 iOS 버전 요구사항 */
              { icon: '🆓', label: '무료 다운로드' }, /* 가격 정보 */
              { icon: '🔒', label: '프라이버시 보호' }, /* 온디바이스 AI 강조 */
              { icon: '🌐', label: '한국어 지원' },   /* 지원 언어 */
            ].map(item => (
              <div key={item.label} style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '8px 14px',
                borderRadius: '50px',          /* pill 모양 뱃지 */
                background: 'var(--bg-card)',
                border: '1px solid var(--border)',
              }}>
                <span style={{ fontSize: '0.9rem' }}>{item.icon}</span>
                <span style={{ fontSize: '0.8rem', fontWeight: 500, color: 'var(--text-secondary)' }}>{item.label}</span>
              </div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
