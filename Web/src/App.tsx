import Header from './components/Header';
import Hero from './components/Hero';
import Philosophy from './components/Philosophy';
import Guide from './components/Guide'; // 1. 불러오기

function App() {
  return (
    <div>
      <Header />
      <main>
        <Hero 
          title="당신의 몰입을 완성하는 시간" 
          subtitle="FocusSense - AI 기반 집중도 분석으로 학습 효율을 극대화하세요." 
        />
        <Philosophy />
        
        {/* 2. 가이드 섹션 배치 */}
        <Guide />
        
      </main>
      
      {/* 3. 간단한 푸터 추가 */}
      <footer style={{ padding: '50px 0', borderTop: '1px solid #eee', textAlign: 'center', color: '#86868b', fontSize: '0.9rem' }}>
        <p>© 2026 FocusSense Project. Built with React & TypeScript.</p>
      </footer>
    </div>
  );
}

export default App;