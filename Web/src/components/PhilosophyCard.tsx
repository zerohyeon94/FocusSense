import { motion } from 'framer-motion';

interface CardProps {
  icon: string;
  title: string;
  description: string;
  delay?: number;
  color: string;
  bg: string;
}

export default function PhilosophyCard({ icon, title, description, delay = 0, color, bg }: CardProps) {
  return (
    <motion.div
      className="card"
      style={{ padding: '40px 32px', textAlign: 'center', cursor: 'default', flex: '1 1 260px' }}
      initial={{ opacity: 0, y: 40 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-50px' }}
      transition={{ duration: 0.6, delay, ease: 'easeOut' }}
      whileHover={{ y: -6, boxShadow: '0 16px 40px rgba(0,0,0,0.1)' }}
    >
      <div style={{
        width: '72px', height: '72px',
        borderRadius: '20px',
        background: bg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: '2rem',
        margin: '0 auto 24px',
      }}>
        {icon}
      </div>

      <h3 style={{
        fontSize: '1.2rem',
        fontWeight: 700,
        color: 'var(--text-primary)',
        marginBottom: '12px',
        letterSpacing: '-0.02em',
      }}>
        {title}
      </h3>

      <p style={{
        fontSize: '0.9rem',
        color: 'var(--text-secondary)',
        lineHeight: 1.7,
      }}>
        {description}
      </p>

      <div style={{
        marginTop: '24px',
        width: '32px',
        height: '3px',
        borderRadius: '2px',
        background: color,
        margin: '24px auto 0',
      }} />
    </motion.div>
  );
}
