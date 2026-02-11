import { useState, useEffect } from 'react'; // 1. useState 훅 불러오기
import Header from './components/Header';
import Hero from './components/Hero';
import Philosophy from './components/Philosophy';
import Guide from './components/Guide';

function App() {
  // 2. 다크모드 상태 정의 (SwiftUI의 @State isDarkMode = false와 같습니다)
  const [isDarkMode, setIsDarkMode] = useState(false);

  // useEffect를 사용해 상태가 바뀔 때마다 body의 class를 관리합니다.
  useEffect(() => {
    if (isDarkMode) {
      document.body.classList.add('dark');
    } else {
      document.body.classList.remove('dark');
    }
  }, [isDarkMode]);

  return (
    <div style={{ backgroundColor: 'var(--bg-main)', color: 'var(--text-primary)', transition: '0.3s' }}>
      <Header isDarkMode={isDarkMode} setIsDarkMode={setIsDarkMode} />
      <main>
        <Hero 
          title="당신의 몰입을 완성하는 시간" 
          subtitle="FocusSense - AI 기반 집중도 분석으로 학습 효율을 극대화하세요." 
        />
        <Philosophy />
        <Guide />
      </main>
      <footer style={{ padding: '50px 0', borderTop: '1px solid var(--bg-sub)', textAlign: 'center' }}>
        <p>© 2026 FocusSense Project.</p>
      </footer>
    </div>
  );
}

export default App;