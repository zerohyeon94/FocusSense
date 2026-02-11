export default function Guide() {
  return (
    <section id="guide" style={styles.section}>
      <div style={styles.container}>
        <div style={styles.contentWrapper}>
          
          {/* 좌측: 텍스트 설명 영역 */}
          <div style={styles.textSide}>
            <h2 style={styles.title}>최적의 집중을 위한<br />배치 가이드</h2>
            
            <div style={styles.step}>
              <span style={styles.stepNumber}>01</span>
              <div>
                <h4 style={styles.stepTitle}>정면 거치대 사용</h4>
                <p style={styles.stepText}>스마트폰을 시선과 비슷한 높이의 거치대에 두세요. 전면 카메라가 얼굴을 정면으로 바라볼 때 가장 정확합니다.</p>
              </div>
            </div>

            <div style={styles.step}>
              <span style={styles.stepNumber}>02</span>
              <div>
                <h4 style={styles.stepTitle}>적절한 조명 유지</h4>
                <p style={styles.stepText}>너무 어두운 곳에서는 AI의 눈동자 인식이 어려울 수 있습니다. 스탠드 조명을 활용해 얼굴을 밝게 해주세요.</p>
              </div>
            </div>
          </div>

          {/* 우측: 시각적 가이드 영역 (아이폰 모형) */}
          <div style={styles.imageSide}>
            <div style={styles.mockupContainer}>
              <div style={styles.iphoneMockup}>
                <div style={styles.cameraHole}></div>
                <div style={styles.screenContent}>
                  <div style={styles.aiCircle}></div>
                  <p style={styles.aiText}>AI Detecting...</p>
                </div>
              </div>
              {/* 거치대 베이스 색상도 변수로 처리 */}
              <div style={styles.standBase}></div>
            </div>
          </div>

        </div>
      </div>
    </section>
  );
}

const styles = {
  section: {
    padding: '120px 0',
    backgroundColor: 'var(--bg-main)', // 배경색 변수 적용
    transition: '0.3s',
  },
  container: {
    maxWidth: '1000px',
    margin: '0 auto',
    padding: '0 20px',
  },
  contentWrapper: {
    display: 'flex',
    alignItems: 'center',
    gap: '60px',
    flexWrap: 'wrap' as 'wrap',
  },
  textSide: {
    flex: 1,
    minWidth: '300px',
  },
  title: {
    fontSize: '2.5rem',
    fontWeight: 700,
    lineHeight: 1.2,
    marginBottom: '50px',
    color: 'var(--text-primary)', // 글자색 변수 적용
  },
  step: {
    display: 'flex',
    gap: '20px',
    marginBottom: '35px',
  },
  stepNumber: {
    fontSize: '1.2rem',
    fontWeight: 700,
    color: 'var(--primary-color)', // iOS 블루
    fontFamily: 'monospace',
  },
  stepTitle: {
    fontSize: '1.2rem',
    fontWeight: 600,
    marginBottom: '8px',
    color: 'var(--text-primary)',
  },
  stepText: {
    fontSize: '1rem',
    color: 'var(--text-secondary)', // 보조 글자색 변수 적용
    lineHeight: 1.5,
  },
  imageSide: {
    flex: 1,
    display: 'flex',
    justifyContent: 'center',
    minWidth: '300px',
  },
  mockupContainer: {
    position: 'relative' as 'relative',
    display: 'flex',
    flexDirection: 'column' as 'column',
    alignItems: 'center',
  },
  iphoneMockup: {
    width: '160px',
    height: '320px',
    backgroundColor: '#1d1d1f', // 아이폰 하우징은 다크 유지 (실제 기기 느낌)
    borderRadius: '30px',
    padding: '10px',
    boxShadow: '0 20px 40px rgba(0,0,0,0.15)',
    position: 'relative' as 'relative',
    zIndex: 2,
    border: '1px solid rgba(255,255,255,0.1)',
  },
  cameraHole: {
    width: '40px',
    height: '4px',
    backgroundColor: '#333',
    margin: '10px auto',
    borderRadius: '2px',
  },
  screenContent: {
    width: '100%',
    height: '270px',
    backgroundColor: '#000', // 화면은 꺼진 느낌 혹은 앱 실행 느낌으로 블랙 유지
    borderRadius: '20px',
    display: 'flex',
    flexDirection: 'column' as 'column',
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  aiCircle: {
    width: '80px',
    height: '80px',
    borderRadius: '50%',
    border: '2px solid var(--primary-color)',
    boxShadow: '0 0 15px var(--primary-color)',
    marginBottom: '20px',
  },
  aiText: {
    color: 'var(--primary-color)',
    fontSize: '0.8rem',
    fontWeight: 600,
  },
  standBase: {
    width: '200px',
    height: '100px',
    backgroundColor: 'var(--bg-sub)', // 거치대는 섹션 배경색과 맞춤
    marginTop: '-40px',
    borderRadius: '10px',
    zIndex: 1,
    border: '1px solid rgba(0,0,0,0.05)',
    transition: '0.3s',
  }
};