import { motion } from 'framer-motion';
import PhilosophyCard from './PhilosophyCard';

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

export default function Philosophy() {
  return (
    <section id="philosophy" className="section" style={{ backgroundColor: 'var(--bg-sub)', transition: 'background-color 0.3s' }}>
      <div className="container">
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

        {/* Core Principle Callout */}
        <motion.div
          initial={{ opacity: 0, scale: 0.97 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true, margin: '-60px' }}
          transition={{ duration: 0.5 }}
          style={{
            padding: '32px 40px',
            borderRadius: '20px',
            background: 'linear-gradient(135deg, rgba(0,122,255,0.08) 0%, rgba(191,90,242,0.08) 100%)',
            border: '1px solid rgba(0,122,255,0.15)',
            marginBottom: '48px',
            textAlign: 'center',
          }}
        >
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
          <p style={{
            fontSize: '0.875rem',
            color: 'var(--text-secondary)',
            marginTop: '12px',
          }}>
            모니터를 보며 코딩 중인 당신 → 집중 중 ✅
          </p>
        </motion.div>

        <div style={{ display: 'flex', gap: '24px', flexWrap: 'wrap', justifyContent: 'center' }}>
          {items.map((item, i) => (
            <PhilosophyCard
              key={i}
              icon={item.icon}
              title={item.title}
              description={item.description}
              delay={i * 0.15}
              color={item.color}
              bg={item.bg}
            />
          ))}
        </div>
      </div>
    </section>
  );
}
