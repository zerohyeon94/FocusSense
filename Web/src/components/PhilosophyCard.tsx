interface CardProps {
  icon: string;
  title: string;
  description: string;
}

export default function PhilosophyCard({ icon, title, description }: CardProps) {
  return (
    <div style={styles.card}>
      <div style={styles.icon}>{icon}</div>
      <h3 style={styles.title}>{title}</h3>
      <p style={styles.description}>{description}</p>
    </div>
  );
}

const styles = {
  card: {
    backgroundColor: 'var(--card-bg)', // 고정값이 아닌 변수 사용
    padding: '40px 30px',
    borderRadius: '20px',
    textAlign: 'center' as 'center',
    boxShadow: '0 4px 20px rgba(0,0,0,0.05)',
    transition: 'transform 0.3s ease',
    flex: 1, // 카드들이 동일한 너비를 갖도록 설정
    minWidth: '280px',
  },
  icon: {
    fontSize: '3rem',
    marginBottom: '20px',
  },
  title: {
    fontSize: '1.4rem',
    fontWeight: 700,
    marginBottom: '15px',
    color: 'var(--text-primary)',
  },
  description: {
    fontSize: '1rem',
    color: 'var(--text-secondary)',
    lineHeight: 1.6,
  },
};