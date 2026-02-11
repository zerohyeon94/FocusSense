import Header from './components/Header';
import Hero from './components/Hero';
import Philosophy from './components/Philosophy'; // 1. 불러오기

function App() {
  return (
    <div>
      <Header />
      <main>
        <Hero 
          title="당신의 몰입을 완성하는 시간" 
          subtitle="FocusSense - AI 기반 집중도 분석으로 학습 효율을 극대화하세요." 
        />
        
        {/* 2. 방향성 섹션 배치 */}
        <Philosophy />
        
        <section style={{ height: '500px', padding: '100px', textAlign: 'center' }}>
          <h3>다음 섹션: 배치 가이드 (Guide)</h3>
        </section>
      </main>
    </div>
  );
}

export default App;