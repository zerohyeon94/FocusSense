interface HeaderProps {
  isDarkMode: boolean;
  setIsDarkMode: (value: boolean) => void; // 함수 타입 정의
}

export default function Header({ isDarkMode, setIsDarkMode }: HeaderProps) {
  return (
    <header style={{
      ...styles.header,
      backgroundColor: isDarkMode ? 'rgba(0, 0, 0, 0.8)' : 'rgba(255, 255, 255, 0.8)',
      borderBottom: isDarkMode ? '1px solid #333' : '1px solid rgba(0,0,0,0.1)'
    }}>
      <div style={styles.container}>
        <h1 style={{ ...styles.logo, color: isDarkMode ? '#fff' : '#1d1d1f' }}>Focus Sense</h1>
        <nav>
          <ul style={styles.navList}>
            {/* 5. 다크모드 토글 버튼 추가 */}
            <li>
              <button 
                onClick={() => setIsDarkMode(!isDarkMode)} // 클릭 시 상태 반전
                style={{
                  ...styles.themeBtn,
                  backgroundColor: isDarkMode ? '#fff' : '#000',
                  color: isDarkMode ? '#000' : '#fff'
                }}
              >
                {isDarkMode ? '☀️ Light' : '🌙 Dark'}
              </button>
            </li>
            <li style={{ color: isDarkMode ? '#fff' : '#1d1d1f' }}><a href="#philosophy">방향성</a></li>
            <li style={{ color: isDarkMode ? '#fff' : '#1d1d1f' }}><a href="#guide">배치 가이드</a></li>
            <li>
              <a href="#download" style={styles.downloadBtn}>앱 다운로드</a>
            </li>
          </ul>
        </nav>
      </div>
    </header>
  );
}

const styles = {
  // 기존 스타일 유지...
  header: {
    height: '60px',
    backdropFilter: 'blur(10px)',
    position: 'fixed' as 'fixed',
    width: '100%',
    top: 0,
    zIndex: 1000,
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
  themeBtn: {
    border: 'none',
    padding: '5px 12px',
    borderRadius: '15px',
    cursor: 'pointer',
    fontSize: '0.75rem',
    fontWeight: 600,
  },
  downloadBtn: {
    backgroundColor: '#007AFF',
    color: 'white',
    padding: '8px 16px',
    borderRadius: '20px',
    fontSize: '0.85rem',
  }
};