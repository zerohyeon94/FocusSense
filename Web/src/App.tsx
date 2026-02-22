import { useState, useEffect } from 'react';
import Header from './components/Header';
import Hero from './components/Hero';
import Features from './components/Features';
import HowItWorks from './components/HowItWorks';
import Philosophy from './components/Philosophy';
import Guide from './components/Guide';
import Download from './components/Download';

function App() {
  const [isDarkMode, setIsDarkMode] = useState(false);

  useEffect(() => {
    // System preference detection
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    setIsDarkMode(prefersDark);
  }, []);

  useEffect(() => {
    if (isDarkMode) {
      document.body.classList.add('dark');
    } else {
      document.body.classList.remove('dark');
    }
  }, [isDarkMode]);

  return (
    <div style={{ backgroundColor: 'var(--bg-main)', color: 'var(--text-primary)', transition: 'background-color 0.3s, color 0.3s' }}>
      <Header isDarkMode={isDarkMode} setIsDarkMode={setIsDarkMode} />

      <main>
        <Hero />
        <Features />
        <HowItWorks />
        <Philosophy />
        <Guide />
        <Download />
      </main>

      <footer style={{
        padding: '48px 0',
        borderTop: '1px solid var(--border)',
        backgroundColor: 'var(--bg-main)',
        transition: 'background-color 0.3s',
      }}>
        <div className="container" style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '20px',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{
              width: '28px', height: '28px',
              borderRadius: '7px',
              background: 'linear-gradient(135deg, #007AFF 0%, #4DA3FF 100%)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: 'white' }} />
            </div>
            <span style={{ fontWeight: 700, fontSize: '0.95rem', color: 'var(--text-primary)' }}>FocusSense</span>
          </div>

          <p style={{ color: 'var(--text-tertiary)', fontSize: '0.85rem' }}>
            © 2026 FocusSense Project. Built with Vision + CoreML.
          </p>

          <div style={{ display: 'flex', gap: '20px' }}>
            {['기능', '작동 원리', '방향성', '배치 가이드'].map(item => (
              <a
                key={item}
                href={`#${item === '기능' ? 'features' : item === '작동 원리' ? 'how-it-works' : item === '방향성' ? 'philosophy' : 'guide'}`}
                style={{ fontSize: '0.82rem', color: 'var(--text-tertiary)', transition: 'color 0.2s' }}
                onMouseEnter={e => (e.target as HTMLElement).style.color = 'var(--text-primary)'}
                onMouseLeave={e => (e.target as HTMLElement).style.color = 'var(--text-tertiary)'}
              >
                {item}
              </a>
            ))}
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;
