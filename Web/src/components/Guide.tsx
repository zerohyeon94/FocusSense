import { motion } from 'framer-motion';

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

function PhoneMockupStand() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', position: 'relative' }}>
      {/* Ambient glow */}
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

      {/* Phone */}
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
        {/* Notch */}
        <div style={{ width: '70px', height: '5px', backgroundColor: '#333344', borderRadius: '3px', flexShrink: 0 }} />

        {/* Face detection overlay */}
        <div style={{ width: '100%', flex: 1, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {/* Camera feed simulation */}
          <div style={{
            width: '100%', height: '100%',
            borderRadius: '16px',
            background: 'linear-gradient(180deg, #0a0a14 0%, #151520 100%)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            position: 'relative',
            overflow: 'hidden',
          }}>
            {/* Face outline */}
            <div style={{
              width: '80px', height: '100px',
              borderRadius: '50% / 45% 45% 55% 55%',
              border: '1.5px solid rgba(0,122,255,0.6)',
              boxShadow: '0 0 20px rgba(0,122,255,0.2)',
              position: 'relative',
            }}>
              {/* Eyes */}
              <div style={{ position: 'absolute', top: '35%', left: '18%', width: '18px', height: '7px', borderRadius: '50%', background: 'rgba(0,122,255,0.8)' }} />
              <div style={{ position: 'absolute', top: '35%', right: '18%', width: '18px', height: '7px', borderRadius: '50%', background: 'rgba(0,122,255,0.8)' }} />
              {/* EAR lines */}
              <div style={{ position: 'absolute', top: '29%', left: '16%', width: '22px', height: '1px', background: 'rgba(48,209,88,0.7)' }} />
              <div style={{ position: 'absolute', top: '29%', right: '16%', width: '22px', height: '1px', background: 'rgba(48,209,88,0.7)' }} />
            </div>

            {/* Corner scan lines */}
            {[
              { top: '8px', left: '8px', borderTop: '2px solid #007AFF', borderLeft: '2px solid #007AFF' },
              { top: '8px', right: '8px', borderTop: '2px solid #007AFF', borderRight: '2px solid #007AFF' },
              { bottom: '8px', left: '8px', borderBottom: '2px solid #007AFF', borderLeft: '2px solid #007AFF' },
              { bottom: '8px', right: '8px', borderBottom: '2px solid #007AFF', borderRight: '2px solid #007AFF' },
            ].map((s, i) => (
              <div key={i} style={{ position: 'absolute', width: '16px', height: '16px', ...s }} />
            ))}

            {/* Status bar */}
            <div style={{
              position: 'absolute',
              bottom: '10px', left: '50%', transform: 'translateX(-50%)',
              display: 'flex', alignItems: 'center', gap: '5px',
              padding: '4px 10px',
              borderRadius: '50px',
              background: 'rgba(48,209,88,0.15)',
              border: '1px solid rgba(48,209,88,0.3)',
            }}>
              <div style={{ width: '5px', height: '5px', borderRadius: '50%', background: '#30D158', boxShadow: '0 0 6px #30D158' }} />
              <span style={{ fontSize: '0.6rem', color: '#30D158', fontWeight: 600 }}>집중 중</span>
            </div>
          </div>
        </div>

        {/* EAR value display */}
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
          <span style={{ fontFamily: 'monospace', fontSize: '0.65rem', color: '#30D158', fontWeight: 600 }}>0.82</span>
        </div>
      </div>

      {/* Stand neck */}
      <div style={{
        width: '10px',
        height: '50px',
        background: 'linear-gradient(180deg, #3a3a4a, #2a2a38)',
        zIndex: 1,
        marginTop: '-2px',
      }} />

      {/* Stand base */}
      <div style={{
        width: '160px',
        height: '14px',
        background: 'linear-gradient(180deg, #3a3a4a, #2a2a38)',
        borderRadius: '7px',
        zIndex: 1,
        boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
      }} />

      {/* Desk surface */}
      <div style={{
        width: '220px',
        height: '3px',
        background: 'var(--border)',
        borderRadius: '2px',
        marginTop: '8px',
        zIndex: 1,
      }} />
    </div>
  );
}

export default function Guide() {
  return (
    <section id="guide" className="section" style={{ backgroundColor: 'var(--bg-main)', transition: 'background-color 0.3s' }}>
      <div className="container">
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

        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '80px',
          flexWrap: 'wrap',
          justifyContent: 'center',
        }}>
          {/* Left: Steps */}
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
                transition={{ duration: 0.5, delay: i * 0.1 }}
                style={{
                  display: 'flex',
                  gap: '20px',
                  marginBottom: i < steps.length - 1 ? '32px' : 0,
                  position: 'relative',
                }}
              >
                {/* Connector line */}
                {i < steps.length - 1 && (
                  <div style={{
                    position: 'absolute',
                    left: '21px',
                    top: '44px',
                    width: '2px',
                    height: 'calc(100% + 12px)',
                    background: 'var(--border)',
                  }} />
                )}

                {/* Step number circle */}
                <div style={{
                  width: '44px', height: '44px',
                  borderRadius: '50%',
                  background: 'var(--bg-sub)',
                  border: '2px solid var(--primary)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                  fontSize: '0.75rem',
                  fontWeight: 800,
                  color: 'var(--primary)',
                  fontFamily: 'monospace',
                  zIndex: 1,
                }}>
                  {step.number}
                </div>

                <div style={{ paddingTop: '6px' }}>
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
                  <p style={{
                    fontSize: '0.875rem',
                    color: 'var(--text-secondary)',
                    lineHeight: 1.65,
                    marginBottom: '8px',
                  }}>
                    {step.description}
                  </p>
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

          {/* Right: Visual */}
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
