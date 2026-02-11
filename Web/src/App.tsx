import Header from './components/Header';
import Hero from './components/Hero'; // 1. Hero 불러오기

function App() {
  return (
    <div>
      <Header />
      <main>
        {/* 2. Hero 배치 및 데이터 전달 (SwiftUI의 View 아규먼트와 비슷합니다) */}
        <Hero 
          title="당신의 몰입을 완성하는 시간" 
          subtitle="FocusSense - AI 기반 집중도 분석으로 학습 효율을 극대화하세요." 
        />
        
        {/* 나중에 다른 섹션들이 들어올 자리 */}
        <section style={{ height: '500px', padding: '50px', textAlign: 'center' }}>
          <h3>다음 섹션: 방향성(Philosophy)</h3>
        </section>
      </main>
    </div>
  );
}

export default App;