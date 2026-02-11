// Props 타입을 정의하여 Swift의 파라미터처럼 사용할 수 있습니다.
interface HeroProps {
  title: string;
  subtitle: string;
}

export default function Hero({ title, subtitle }: HeroProps) {
  return (
    <section style={styles.hero}>
      <div style={styles.container}>
        <h2 style={styles.title}>{title}</h2>
        <p style={styles.subtitle}>{subtitle}</p>
        <div style={styles.ctaGroup}>
          <button style={styles.primaryBtn}>자세히 알아보기</button>
          <button style={styles.secondaryBtn}>데모 보기</button>
        </div>
      </div>
    </section>
  );
}

const styles = {
  hero: {
    height: '80vh', // 화면 높이의 80%
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: 'var(--bg-main)', // 혹은 테마별 그라데이션 변수 생성
    transition: '0.3s',
    textAlign: 'center' as 'center',
  },
  container: {
    maxWidth: '800px',
    padding: '0 20px',
  },
  title: {
    fontSize: '3.5rem',
    fontWeight: 800,
    letterSpacing: '-0.02em',
    marginBottom: '20px',
    color: 'var(--text-primary)',
  },
  subtitle: {
    fontSize: '1.5rem',
    fontWeight: 400,
    color: '#86868b',
    marginBottom: '40px',
    lineHeight: 1.4,
  },
  ctaGroup: {
    display: 'flex',
    gap: '15px',
    justifyContent: 'center',
  },
  primaryBtn: {
    backgroundColor: '#007AFF',
    color: 'white',
    border: 'none',
    padding: '12px 24px',
    borderRadius: '25px',
    fontSize: '1rem',
    fontWeight: 600,
    cursor: 'pointer',
  },
  secondaryBtn: {
    backgroundColor: 'transparent',
    color: '#007AFF',
    border: '1px solid #007AFF',
    padding: '12px 24px',
    borderRadius: '25px',
    fontSize: '1rem',
    fontWeight: 600,
    cursor: 'pointer',
  }
};