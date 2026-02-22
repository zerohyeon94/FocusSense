import { motion } from 'framer-motion';

interface CardProps {
  icon: string;
  title: string;
  description: string;
  delay?: number; // 카드가 여러 개일 때 순차적으로 나타나게 하기 위함
}

export default function PhilosophyCard({ icon, title, description, delay = 0 }: CardProps) {
  return (
    // 2. 일반 div를 motion.div로 변경하고 애니메이션 속성 부여
    <motion.div 
      style={styles.card}
      initial={{ opacity: 0, y: 50 }} // 시작 상태: 투명도 0, 아래로 50px 내려간 상태
      whileInView={{ opacity: 1, y: 0 }} // 화면에 보일 때 상태: 투명도 1, 원래 위치
      viewport={{ once: true, margin: "-50px" }} // 한 번만 실행, 화면에 살짝 들어왔을 때 시작
      transition={{ duration: 0.6, delay: delay, ease: "easeOut" }} // 애니메이션 시간 및 지연
    >
      <div style={styles.icon}>{icon}</div>
      <h3 style={styles.title}>{title}</h3>
      <p style={styles.description}>{description}</p>
    </motion.div>
  );
}

const styles = {
  card: {
    backgroundColor: 'var(--card-bg)',
    padding: '40px 30px',
    borderRadius: '20px',
    textAlign: 'center' as 'center',
    boxShadow: '0 4px 20px rgba(0,0,0,0.05)',
    flex: 1,
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