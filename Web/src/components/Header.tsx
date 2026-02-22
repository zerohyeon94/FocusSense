import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface HeaderProps {
  isDarkMode: boolean;
  setIsDarkMode: (value: boolean) => void;
}

export default function Header({ isDarkMode, setIsDarkMode }: HeaderProps) {
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { label: '기능', href: '#features' },
    { label: '작동 원리', href: '#how-it-works' },
    { label: '방향성', href: '#philosophy' },
    { label: '배치 가이드', href: '#guide' },
  ];

  return (
    <header style={{
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      zIndex: 1000,
      height: '64px',
      display: 'flex',
      alignItems: 'center',
      transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
      backgroundColor: scrolled
        ? (isDarkMode ? 'rgba(15, 15, 26, 0.85)' : 'rgba(255, 255, 255, 0.85)')
        : 'transparent',
      backdropFilter: scrolled ? 'blur(20px) saturate(180%)' : 'none',
      WebkitBackdropFilter: scrolled ? 'blur(20px) saturate(180%)' : 'none',
      borderBottom: scrolled
        ? `1px solid ${isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)'}`
        : '1px solid transparent',
    }}>
      <div className="container" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
        {/* Logo */}
        <a href="#" style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            width: '32px',
            height: '32px',
            borderRadius: '8px',
            background: 'linear-gradient(135deg, #007AFF 0%, #4DA3FF 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(0, 122, 255, 0.3)',
          }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="3" fill="white" />
              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z" fill="white" opacity="0.5" />
              <path d="M12 6c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6zm0 10c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4z" fill="white" opacity="0.3" />
            </svg>
          </div>
          <span style={{
            fontSize: '1.15rem',
            fontWeight: 700,
            color: 'var(--text-primary)',
            letterSpacing: '-0.02em',
          }}>
            FocusSense
          </span>
        </a>

        {/* Desktop Nav */}
        <nav style={{ display: 'flex', alignItems: 'center', gap: '8px' }} className="desktop-nav">
          {navLinks.map(link => (
            <a
              key={link.href}
              href={link.href}
              style={{
                padding: '7px 14px',
                borderRadius: '50px',
                fontSize: '0.875rem',
                fontWeight: 500,
                color: 'var(--text-secondary)',
                transition: 'all 0.2s',
              }}
              onMouseEnter={e => {
                (e.target as HTMLElement).style.color = 'var(--text-primary)';
                (e.target as HTMLElement).style.backgroundColor = 'var(--bg-sub)';
              }}
              onMouseLeave={e => {
                (e.target as HTMLElement).style.color = 'var(--text-secondary)';
                (e.target as HTMLElement).style.backgroundColor = 'transparent';
              }}
            >
              {link.label}
            </a>
          ))}
        </nav>

        {/* Right Actions */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          {/* Dark Mode Toggle */}
          <button
            onClick={() => setIsDarkMode(!isDarkMode)}
            aria-label="다크모드 전환"
            style={{
              width: '38px',
              height: '38px',
              borderRadius: '50%',
              border: `1px solid var(--border)`,
              background: 'var(--bg-sub)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '1rem',
              transition: 'all 0.2s',
              flexShrink: 0,
            }}
          >
            {isDarkMode ? '☀️' : '🌙'}
          </button>

          {/* App Store CTA */}
          <a
            href="#download"
            className="btn-primary"
            style={{ padding: '8px 18px', fontSize: '0.875rem' }}
          >
            앱 다운로드
          </a>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="메뉴"
            className="mobile-menu-btn"
            style={{
              width: '38px',
              height: '38px',
              borderRadius: '50%',
              border: `1px solid var(--border)`,
              background: 'var(--bg-sub)',
              cursor: 'pointer',
              display: 'none',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
            }}
          >
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <span style={{ width: '16px', height: '1.5px', background: 'var(--text-primary)', borderRadius: '2px', display: 'block', transition: 'all 0.2s', transform: mobileMenuOpen ? 'translateY(5.5px) rotate(45deg)' : 'none' }} />
              <span style={{ width: '16px', height: '1.5px', background: 'var(--text-primary)', borderRadius: '2px', display: 'block', transition: 'all 0.2s', opacity: mobileMenuOpen ? 0 : 1 }} />
              <span style={{ width: '16px', height: '1.5px', background: 'var(--text-primary)', borderRadius: '2px', display: 'block', transition: 'all 0.2s', transform: mobileMenuOpen ? 'translateY(-5.5px) rotate(-45deg)' : 'none' }} />
            </div>
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.2 }}
            style={{
              position: 'absolute',
              top: '64px',
              left: 0,
              right: 0,
              backgroundColor: isDarkMode ? 'rgba(15, 15, 26, 0.97)' : 'rgba(255, 255, 255, 0.97)',
              backdropFilter: 'blur(20px)',
              WebkitBackdropFilter: 'blur(20px)',
              borderBottom: `1px solid var(--border)`,
              padding: '16px 24px 24px',
            }}
          >
            {navLinks.map(link => (
              <a
                key={link.href}
                href={link.href}
                onClick={() => setMobileMenuOpen(false)}
                style={{
                  display: 'block',
                  padding: '14px 0',
                  fontSize: '1.05rem',
                  fontWeight: 500,
                  color: 'var(--text-primary)',
                  borderBottom: `1px solid var(--border)`,
                }}
              >
                {link.label}
              </a>
            ))}
          </motion.div>
        )}
      </AnimatePresence>

      <style>{`
        @media (max-width: 768px) {
          .desktop-nav { display: none !important; }
          .mobile-menu-btn { display: flex !important; }
        }
      `}</style>
    </header>
  );
}
