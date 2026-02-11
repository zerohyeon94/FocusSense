import Header from './components/Header'; // 1. 헤더 불러오기

function App() {
  return (
    <div>
      {/* 2. 헤더 배치하기 */}
      <Header />
      
      {/* 임시 본문 (헤더에 가려지지 않게 여백 추가) */}
      <main style={{ paddingTop: '80px', textAlign: 'center' }}>
        <h2>메인 화면이 들어갈 자리입니다.</h2>
      </main>
    </div>
  );
}

export default App;