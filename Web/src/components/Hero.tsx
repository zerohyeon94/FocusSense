import { useEffect, useRef, useState } from 'react';
import { motion } from 'framer-motion';

const FOCUS_STATES = [
  { label: '집중 중', color: '#30D158', bg: 'rgba(48, 209, 88, 0.15)', icon: '👁️' },
  { label: '주의', color: '#FFD60A', bg: 'rgba(255, 214, 10, 0.15)', icon: '⚠️' },
  { label: '졸음 감지', color: '#FF453A', bg: 'rgba(255, 69, 58, 0.15)', icon: '😴' },
  { label: '집중 중', color: '#30D158', bg: 'rgba(48, 209, 88, 0.15)', icon: '👁️' },
];

function PhoneMockup() {
  const [stateIndex, setStateIndex] = useState(0);
  const [time, setTime] = useState(0);
  const [focusRate, setFocusRate] = useState(87);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    timerRef.current = setInterval(() => {
      setTime(t => t + 1);
    }, 1000);
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, []);

  useEffect(() => {
    const cycleInterval = setInterval(() => {
      setStateIndex(i => (i + 1) % FOCUS_STATES.length);
      setFocusRate(r => {
        const next = r + Math.floor(Math.random() * 5 - 2);
        return Math.max(60, Math.min(98, next));
      });
    }, 2400);
    return () => clearInterval(cycleInterval);
  }, []);

  const state = FOCUS_STATES[stateIndex];
  const h = String(Math.floor(time / 3600)).padStart(2, '0');
  const m = String(Math.floor((time % 3600) / 60)).padStart(2, '0');
  const s = String(time % 60).padStart(2, '0');
  const netTime = Math.floor(time * (focusRate / 100));
  const nm = String(Math.floor(netTime / 60)).padStart(2, '0');
  const ns = String(netTime % 60).padStart(2, '0');

  return (
    <div style={{
      width: '220px',
      height: '440px',
      borderRadius: '44px',
      background: 'linear-gradient(180deg, #1a1a2e 0%, #0f0f1a 100%)',
      border: '8px solid #2a2a3a',
      position: 'relative',
      overflow: 'hidden',
      boxShadow: '0 40px 80px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.06) inset',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      padding: '20px 16px 24px',
      gap: '12px',
    }}>
      {/* Notch */}
      <div style={{
        width: '80px', height: '6px',
        backgroundColor: '#2a2a3a',
        borderRadius: '3px',
        flexShrink: 0,
      }} />

      {/* Status Pill */}
      <motion.div
        key={stateIndex}
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.3 }}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
          padding: '6px 14px',
          borderRadius: '50px',
          background: state.bg,
          border: `1px solid ${state.color}40`,
        }}
      >
        <span style={{ fontSize: '0.75rem' }}>{state.icon}</span>
        <span style={{ fontSize: '0.7rem', fontWeight: 700, color: state.color }}>{state.label}</span>
      </motion.div>

      {/* Timer */}
      <div style={{ textAlign: 'center', flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: '12px' }}>
        <div style={{
          fontFamily: 'SF Mono, Menlo, monospace',
          fontSize: '2.4rem',
          fontWeight: 200,
          color: 'white',
          letterSpacing: '0.02em',
          lineHeight: 1,
        }}>
          {h}:{m}:{s}
        </div>

        <div style={{
          display: 'flex',
          gap: '16px',
          justifyContent: 'center',
          padding: '10px 16px',
          background: 'rgba(255,255,255,0.05)',
          borderRadius: '12px',
        }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '0.6rem', color: 'rgba(255,255,255,0.5)', marginBottom: '2px' }}>순수 집중</div>
            <div style={{ fontFamily: 'monospace', fontSize: '0.9rem', color: '#30D158', fontWeight: 600 }}>
              {nm}:{ns}
            </div>
          </div>
          <div style={{ width: '1px', background: 'rgba(255,255,255,0.1)' }} />
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '0.6rem', color: 'rgba(255,255,255,0.5)', marginBottom: '2px' }}>집중률</div>
            <motion.div
              key={focusRate}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              style={{ fontFamily: 'monospace', fontSize: '0.9rem', color: focusRate >= 80 ? '#30D158' : '#FFD60A', fontWeight: 600 }}
            >
              {focusRate}%
            </motion.div>
          </div>
        </div>

        {/* EAR Visualization */}
        <div style={{
          padding: '10px',
          background: 'rgba(255,255,255,0.04)',
          borderRadius: '10px',
          textAlign: 'left',
        }}>
          <div style={{ fontSize: '0.55rem', color: 'rgba(255,255,255,0.4)', marginBottom: '6px', letterSpacing: '0.05em', textTransform: 'uppercase' }}>
            AI 분석
          </div>
          {[
            { label: 'EAR 비율', value: 0.78, color: '#30D158' },
            { label: 'CoreML 점수', value: 0.15, color: '#007AFF' },
          ].map(item => (
            <div key={item.label} style={{ marginBottom: '4px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '2px' }}>
                <span style={{ fontSize: '0.55rem', color: 'rgba(255,255,255,0.5)' }}>{item.label}</span>
                <span style={{ fontSize: '0.55rem', color: item.color }}>{(item.value * 100).toFixed(0)}%</span>
              </div>
              <div style={{ height: '2px', background: 'rgba(255,255,255,0.08)', borderRadius: '1px' }}>
                <div style={{ height: '100%', width: `${item.value * 100}%`, background: item.color, borderRadius: '1px', transition: 'width 0.5s' }} />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Play Button */}
      <div style={{
        width: '52px', height: '52px',
        borderRadius: '50%',
        background: 'linear-gradient(135deg, #007AFF, #4DA3FF)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 8px 20px rgba(0,122,255,0.4)',
        flexShrink: 0,
      }}>
        <div style={{
          width: 0, height: 0,
          borderTop: '8px solid transparent',
          borderBottom: '8px solid transparent',
          borderLeft: '14px solid white',
          marginLeft: '3px',
        }} />
      </div>
    </div>
  );
}

export default function Hero() {
  return (
    <section style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      paddingTop: '64px',
      background: 'var(--bg-main)',
      position: 'relative',
      overflow: 'hidden',
    }}>
      {/* Background Glow */}
      <div style={{
        position: 'absolute',
        top: '10%', left: '50%',
        transform: 'translateX(-50%)',
        width: '800px', height: '600px',
        background: 'radial-gradient(ellipse, rgba(0,122,255,0.08) 0%, transparent 70%)',
        pointerEvents: 'none',
      }} />

      <div className="container" style={{
        display: 'flex',
        alignItems: 'center',
        gap: '80px',
        padding: '80px 24px',
        flexWrap: 'wrap',
        justifyContent: 'center',
      }}>
        {/* Left: Text */}
        <motion.div
          initial={{ opacity: 0, x: -30 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.7, ease: 'easeOut' }}
          style={{ flex: '1 1 400px', maxWidth: '540px' }}
        >
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '8px',
            padding: '6px 14px',
            borderRadius: '50px',
            border: '1px solid rgba(0,122,255,0.25)',
            background: 'rgba(0,122,255,0.06)',
            marginBottom: '28px',
          }}>
            <span style={{
              width: '6px', height: '6px',
              borderRadius: '50%',
              background: '#30D158',
              boxShadow: '0 0 8px #30D158',
              display: 'inline-block',
            }} />
            <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--primary)' }}>
              온디바이스 AI · Vision + CoreML
            </span>
          </div>

          <h1 style={{
            fontSize: 'clamp(2.4rem, 5vw, 3.8rem)',
            fontWeight: 900,
            letterSpacing: '-0.04em',
            lineHeight: 1.05,
            marginBottom: '24px',
            color: 'var(--text-primary)',
          }}>
            당신의 몰입을<br />
            <span className="gradient-text">완성하는 시간</span>
          </h1>

          <p style={{
            fontSize: '1.15rem',
            color: 'var(--text-secondary)',
            lineHeight: 1.7,
            marginBottom: '40px',
            maxWidth: '440px',
          }}>
            AI가 카메라로 눈 상태를 실시간 분석하여, 진짜 집중한 시간만 측정합니다.
            졸음이 감지되면 자동 일시정지. 서버 없이, 기기 안에서만.
          </p>

          <div style={{ display: 'flex', gap: '14px', flexWrap: 'wrap' }}>
            <a href="#download" className="btn-primary" style={{ fontSize: '1rem', padding: '14px 28px' }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              App Store
            </a>
            <a href="#features" className="btn-secondary" style={{ fontSize: '1rem', padding: '14px 28px' }}>
              기능 살펴보기
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <path d="M5 12h14M12 5l7 7-7 7" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </a>
          </div>

          {/* Stats */}
          <div style={{
            display: 'flex',
            gap: '32px',
            marginTop: '52px',
            paddingTop: '32px',
            borderTop: '1px solid var(--border)',
          }}>
            {[
              { value: '70%', label: 'Vision Framework' },
              { value: '30%', label: 'CoreML 모델' },
              { value: '3s', label: '자리비움 감지' },
            ].map(stat => (
              <div key={stat.label}>
                <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--primary)', letterSpacing: '-0.03em' }}>
                  {stat.value}
                </div>
                <div style={{ fontSize: '0.78rem', color: 'var(--text-tertiary)', marginTop: '2px' }}>
                  {stat.label}
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Right: Phone Mockup */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.2, ease: 'easeOut' }}
          style={{
            flex: '0 0 auto',
            display: 'flex',
            justifyContent: 'center',
            position: 'relative',
          }}
        >
          {/* Glow under phone */}
          <div style={{
            position: 'absolute',
            bottom: '-40px',
            left: '50%',
            transform: 'translateX(-50%)',
            width: '200px', height: '80px',
            background: 'radial-gradient(ellipse, rgba(0,122,255,0.3) 0%, transparent 70%)',
            filter: 'blur(20px)',
            pointerEvents: 'none',
          }} />
          <PhoneMockup />
        </motion.div>
      </div>
    </section>
  );
}
