// React 컴포넌트는 항상 대문자로 시작하는 함수입니다.
export default function Header() {
  return (
    <header style={styles.header}>
      <div style={styles.container}>
        <h1 style={styles.logo}>Focus Sense</h1>
        <nav>
          <ul style={styles.navList}>
            <li><a href="#philosophy">방향성</a></li>
            <li><a href="#guide">배치 가이드</a></li>
            <li>
              <a href="#download" style={styles.downloadBtn}>앱 다운로드</a>
            </li>
          </ul>
        </nav>
      </div>
    </header>
  );
}

// CSS-in-JS 방식 (스타일 객체)
// 나중에는 CSS 모듈이나 Tailwind 등으로 고도화할 수 있습니다.
const styles = {
  header: {
    height: '60px',
    backgroundColor: 'rgba(255, 255, 255, 0.8)',
    backdropFilter: 'blur(10px)',
    position: 'fixed' as 'fixed', // TypeScript 타입 단언
    width: '100%',
    top: 0,
    zIndex: 1000,
    borderBottom: '1px solid rgba(0,0,0,0.1)',
    display: 'flex',
    alignItems: 'center',
  },
  container: {
    maxWidth: '1000px',
    width: '100%',
    margin: '0 auto',
    padding: '0 20px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  logo: {
    fontSize: '1.2rem',
    fontWeight: 700,
  },
  navList: {
    display: 'flex',
    gap: '20px',
    alignItems: 'center',
    fontSize: '0.9rem',
    fontWeight: 500,
  },
  downloadBtn: {
    backgroundColor: '#007AFF',
    color: 'white',
    padding: '8px 16px',
    borderRadius: '20px',
    fontSize: '0.85rem',
    transition: 'background 0.3s',
  }
};