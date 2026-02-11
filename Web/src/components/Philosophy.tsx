import PhilosophyCard from './PhilosophyCard';

export default function Philosophy() {
  const items = [
    {
      icon: "🎯",
      title: "정교한 측정",
      description: "AI 모델이 사용자의 눈동자와 자세를 분석하여 실제 집중도를 수치화합니다."
    },
    {
      icon: "📊",
      title: "데이터 인사이트",
      description: "단순 타이머를 넘어, 언제 가장 집중이 잘 되는지 패턴을 분석해 드립니다."
    },
    {
      icon: "📱",
      title: "온디바이스 AI",
      description: "개인 정보 보호를 위해 모든 분석은 서버 없이 기기 내에서 안전하게 처리됩니다."
    }
  ];

  return (
    <section id="philosophy" style={styles.section}>
      <div style={styles.container}>
        <h2 style={styles.sectionTitle}>우리의 방향성</h2>
        <div style={styles.cardGrid}>
          {items.map((item, index) => (
            <PhilosophyCard 
              key={index}
              icon={item.icon}
              title={item.title}
              description={item.description}
            />
          ))}
        </div>
      </div>
    </section>
  );
}

const styles = {
  section: {
    padding: '100px 0',
    backgroundColor: '#f5f5f7', // 연한 회색 배경으로 섹션 구분
  },
  container: {
    maxWidth: '1000px',
    margin: '0 auto',
    padding: '0 20px',
  },
  sectionTitle: {
    fontSize: '2.5rem',
    fontWeight: 700,
    textAlign: 'center' as 'center',
    marginBottom: '60px',
    color: '#1d1d1f',
  },
  cardGrid: {
    display: 'flex',
    gap: '30px',
    flexWrap: 'wrap' as 'wrap', // 화면이 좁아지면 카드가 아래로 내려가도록 설정
  },
};