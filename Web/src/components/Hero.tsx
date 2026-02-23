/**
 * ============================================================
 * Hero.tsx — 메인 히어로 섹션
 * ============================================================
 * 랜딩 페이지 첫 화면(Above the fold)을 구성합니다.
 * 두 개의 서브 컴포넌트로 나뉩니다:
 *   1. PhoneMockup  — 앱 동작을 시뮬레이션하는 인터랙티브 폰 목업
 *   2. Hero (default export) — 텍스트 영역 + PhoneMockup을 배치하는 섹션
 * ============================================================
 */

/**
 * useEffect: 타이머/사이클 interval 등록 및 정리
 * useRef   : setInterval ID를 컴포넌트 리렌더링 없이 저장
 * useState : 상태 관리
 */
import { useEffect, useRef, useState } from 'react';
import { motion } from 'framer-motion';

/**
 * FOCUS_STATES: 앱의 집중 상태 목록 (상수 배열)
 * PhoneMockup 내부에서 일정 시간마다 순환하며 화면에 표시됩니다.
 * 배열 마지막에 '집중 중'을 한 번 더 추가해 자주 노출되도록 합니다.
 *
 * color: 텍스트/테두리 색상 (hex)
 * bg   : 배경 색상 (rgba — 낮은 투명도로 반투명 효과)
 */
const FOCUS_STATES = [
  { label: '집중 중',  color: '#30D158', bg: 'rgba(48, 209, 88, 0.15)',  icon: '👁️' },
  { label: '주의',    color: '#FFD60A', bg: 'rgba(255, 214, 10, 0.15)', icon: '⚠️' },
  { label: '졸음 감지', color: '#FF453A', bg: 'rgba(255, 69, 58, 0.15)',  icon: '😴' },
  { label: '집중 중',  color: '#30D158', bg: 'rgba(48, 209, 88, 0.15)',  icon: '👁️' },
];

/**
 * PhoneMockup 컴포넌트
 * 실제 앱처럼 동작하는 인터랙티브 데모 UI를 렌더링합니다.
 * - 1초마다 타이머가 증가합니다.
 * - 2.4초마다 집중 상태와 집중률이 변경됩니다.
 */
function PhoneMockup() {
  /* 현재 표시 중인 집중 상태의 배열 인덱스 */
  const [stateIndex, setStateIndex] = useState(0);

  /* 경과 시간 (초 단위) — 1초마다 +1 증가 */
  const [time, setTime] = useState(0);

  /* 집중률 (%) — 60~98 범위에서 랜덤하게 변동 */
  const [focusRate, setFocusRate] = useState(87);

  /**
   * useRef: DOM 참조 또는 렌더링과 무관한 값을 저장
   * setInterval의 반환값(interval ID)을 저장합니다.
   * useState와 달리 값이 바뀌어도 리렌더링을 유발하지 않습니다.
   * ReturnType<typeof setInterval>: setInterval의 반환 타입을 자동 추론
   */
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  /**
   * useEffect #1 — 1초 타이머
   * setInterval: 지정한 밀리초(1000ms = 1초)마다 콜백을 반복 실행합니다.
   * setTime(t => t + 1): 함수형 업데이터 — 이전 값을 기반으로 새 값을 계산합니다.
   *   (클로저 문제를 피하기 위해 직접 상태값 대신 함수형 업데이터를 사용)
   *
   * cleanup: 컴포넌트 언마운트 시 clearInterval로 타이머를 정리합니다.
   */
  useEffect(() => {
    timerRef.current = setInterval(() => {
      setTime(t => t + 1);
    }, 1000);
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, []);

  /**
   * useEffect #2 — 집중 상태 순환 사이클 (2.4초)
   * % FOCUS_STATES.length: 나머지 연산으로 배열 범위를 벗어나지 않고 순환
   *
   * 집중률 업데이트:
   * Math.random() * 5 - 2: -2 ~ +3 사이의 랜덤 변화량
   * Math.floor(): 소수점을 버려 정수로 변환
   * Math.max(60, Math.min(98, next)): 60~98 범위로 클램핑(clamping)
   */
  useEffect(() => {
    const cycleInterval = setInterval(() => {
      setStateIndex(i => (i + 1) % FOCUS_STATES.length);
      setFocusRate(r => {
        const next = r + Math.floor(Math.random() * 5 - 2);
        return Math.max(60, Math.min(98, next)); // 60~98 범위로 제한
      });
    }, 2400);
    return () => clearInterval(cycleInterval);
  }, []);

  /* 현재 표시할 집중 상태 객체 */
  const state = FOCUS_STATES[stateIndex];

  /* ── 시간 포맷팅: 총 초(time)를 HH:MM:SS 형식으로 변환 ──
     padStart(2, '0'): 한 자리 숫자를 '01', '09' 처럼 두 자리로 맞춤 */
  const h = String(Math.floor(time / 3600)).padStart(2, '0');          // 시간
  const m = String(Math.floor((time % 3600) / 60)).padStart(2, '0');   // 분 (3600으로 나눈 나머지를 60으로 나눔)
  const s = String(time % 60).padStart(2, '0');                        // 초

  /* 순수 집중 시간 계산: 전체 시간 × (집중률 / 100) */
  const netTime = Math.floor(time * (focusRate / 100));
  const nm = String(Math.floor(netTime / 60)).padStart(2, '0');
  const ns = String(netTime % 60).padStart(2, '0');

  return (
    /* 폰 외형 컨테이너 — 어두운 그라디언트 배경, 둥근 모서리로 스마트폰 느낌 */
    <div style={{
      width: '220px',
      height: '440px',
      borderRadius: '44px',          /* 폰의 특유의 크게 둥근 모서리 */
      background: 'linear-gradient(180deg, #1a1a2e 0%, #0f0f1a 100%)',
      border: '8px solid #2a2a3a',   /* 폰 베젤(테두리) 색상 */
      position: 'relative',
      overflow: 'hidden',             /* 자식 요소가 폰 밖으로 나가지 않도록 */
      /* 복합 box-shadow: 큰 아래 그림자 + 미묘한 안쪽 하이라이트 */
      boxShadow: '0 40px 80px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.06) inset',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      padding: '20px 16px 24px',
      gap: '12px',
    }}>

      {/* 노치(Notch) — 폰 상단 중앙의 카메라 영역 표시 */}
      <div style={{
        width: '80px', height: '6px',
        backgroundColor: '#2a2a3a',
        borderRadius: '3px',
        flexShrink: 0, /* flex 컨테이너에서 크기 축소 방지 */
      }} />

      {/* 집중 상태 뱃지 (Status Pill)
          key={stateIndex}: 상태가 바뀔 때마다 새 motion.div로 인식되어
                            initial → animate 애니메이션이 다시 실행됩니다. */}
      <motion.div
        key={stateIndex}
        initial={{ scale: 0.8, opacity: 0 }}  /* 작게 시작하며 투명 */
        animate={{ scale: 1, opacity: 1 }}     /* 원래 크기로 나타남 */
        transition={{ duration: 0.3 }}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
          padding: '6px 14px',
          borderRadius: '50px',
          background: state.bg,
          /* 테두리 색상에 40 (hex) = 25% 투명도 추가 */
          border: `1px solid ${state.color}40`,
        }}
      >
        <span style={{ fontSize: '0.75rem' }}>{state.icon}</span>
        <span style={{ fontSize: '0.7rem', fontWeight: 700, color: state.color }}>{state.label}</span>
      </motion.div>

      {/* 타이머 및 통계 영역 */}
      <div style={{ textAlign: 'center', flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: '12px' }}>

        {/* 메인 타이머 디스플레이 — 모노스페이스 폰트로 숫자 너비 일정하게 */}
        <div style={{
          fontFamily: 'SF Mono, Menlo, monospace',
          fontSize: '2.4rem',
          fontWeight: 200,         /* 얇은 폰트 웨이트 — 미니멀한 느낌 */
          color: 'white',
          letterSpacing: '0.02em',
          lineHeight: 1,
        }}>
          {h}:{m}:{s}
        </div>

        {/* 순수 집중 시간 / 집중률 통계 카드 */}
        <div style={{
          display: 'flex',
          gap: '16px',
          justifyContent: 'center',
          padding: '10px 16px',
          background: 'rgba(255,255,255,0.05)', /* 매우 연한 반투명 배경 */
          borderRadius: '12px',
        }}>
          {/* 순수 집중 시간 */}
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '0.6rem', color: 'rgba(255,255,255,0.5)', marginBottom: '2px' }}>순수 집중</div>
            <div style={{ fontFamily: 'monospace', fontSize: '0.9rem', color: '#30D158', fontWeight: 600 }}>
              {nm}:{ns}
            </div>
          </div>

          {/* 세로 구분선 */}
          <div style={{ width: '1px', background: 'rgba(255,255,255,0.1)' }} />

          {/* 집중률 — 값이 바뀔 때 fade 애니메이션
              key={focusRate}: 값 변경 시 새 컴포넌트로 인식 → initial 애니메이션 재실행 */}
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '0.6rem', color: 'rgba(255,255,255,0.5)', marginBottom: '2px' }}>집중률</div>
            <motion.div
              key={focusRate}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              /* 80% 이상이면 초록, 미만이면 노란색 */
              style={{ fontFamily: 'monospace', fontSize: '0.9rem', color: focusRate >= 80 ? '#30D158' : '#FFD60A', fontWeight: 600 }}
            >
              {focusRate}%
            </motion.div>
          </div>
        </div>

        {/* AI 분석 데이터 시각화 (EAR 비율 + CoreML 점수)
            실제 앱의 디버그 패널을 모방한 미니 프로그레스 바 UI */}
        <div style={{
          padding: '10px',
          background: 'rgba(255,255,255,0.04)',
          borderRadius: '10px',
          textAlign: 'left',
        }}>
          <div style={{ fontSize: '0.55rem', color: 'rgba(255,255,255,0.4)', marginBottom: '6px', letterSpacing: '0.05em', textTransform: 'uppercase' }}>
            AI 분석
          </div>
          {/* 두 개의 메트릭을 map()으로 반복 렌더링 */}
          {[
            { label: 'EAR 비율',    value: 0.78, color: '#30D158' }, /* EAR 0.78 → 눈을 잘 뜨고 있는 상태 */
            { label: 'CoreML 점수', value: 0.15, color: '#007AFF' }, /* 0.15 → 졸음 점수 낮음 (집중 중) */
          ].map(item => (
            <div key={item.label} style={{ marginBottom: '4px' }}>
              {/* 레이블과 퍼센트 값을 양쪽 끝에 배치 */}
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '2px' }}>
                <span style={{ fontSize: '0.55rem', color: 'rgba(255,255,255,0.5)' }}>{item.label}</span>
                {/* toFixed(0): 소수점 0자리 — 정수로 표시 */}
                <span style={{ fontSize: '0.55rem', color: item.color }}>{(item.value * 100).toFixed(0)}%</span>
              </div>
              {/* 프로그레스 바: 회색 트랙 위에 색상 막대 */}
              <div style={{ height: '2px', background: 'rgba(255,255,255,0.08)', borderRadius: '1px' }}>
                {/* width를 item.value * 100%로 설정하여 값에 비례한 막대 길이 표현 */}
                <div style={{ height: '100%', width: `${item.value * 100}%`, background: item.color, borderRadius: '1px', transition: 'width 0.5s' }} />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 재생 버튼 — CSS로 삼각형(▶) 만들기
          CSS 트릭: width/height = 0, border로 삼각형 생성
          borderTop/Bottom: 위아래 투명 테두리로 높이 결정
          borderLeft: 왼쪽 색상 테두리가 삼각형의 "면"이 됩니다. */}
      <div style={{
        width: '52px', height: '52px',
        borderRadius: '50%',
        background: 'linear-gradient(135deg, #007AFF, #4DA3FF)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 8px 20px rgba(0,122,255,0.4)',
        flexShrink: 0,
      }}>
        <div style={{
          width: 0, height: 0,
          borderTop: '8px solid transparent',
          borderBottom: '8px solid transparent',
          borderLeft: '14px solid white', /* 이 흰색 왼쪽 테두리가 삼각형이 됨 */
          marginLeft: '3px',              /* 시각적으로 정중앙 정렬 보정 */
        }} />
      </div>
    </div>
  );
}

/**
 * Hero 컴포넌트 (기본 export)
 * 화면 왼쪽에 텍스트, 오른쪽에 PhoneMockup을 배치합니다.
 * flexWrap: wrap으로 모바일에서는 세로로 쌓입니다.
 */
export default function Hero() {
  return (
    <section style={{
      minHeight: '100vh',  /* 최소 높이를 뷰포트 전체로 설정 */
      display: 'flex',
      alignItems: 'center',
      paddingTop: '64px',  /* 고정 헤더 높이만큼 상단 패딩 추가 */
      background: 'var(--bg-main)',
      position: 'relative',
      overflow: 'hidden',
    }}>

      {/* 배경 글로우 효과
          radial-gradient: 원형 그라디언트 — 중앙에서 바깥으로 퍼지는 빛 효과
          pointerEvents: none — 마우스 이벤트를 받지 않아 클릭을 방해하지 않음 */}
      <div style={{
        position: 'absolute',
        top: '10%', left: '50%',
        transform: 'translateX(-50%)', /* 수평 중앙 정렬 */
        width: '800px', height: '600px',
        background: 'radial-gradient(ellipse, rgba(0,122,255,0.08) 0%, transparent 70%)',
        pointerEvents: 'none',
      }} />

      <div className="container" style={{
        display: 'flex',
        alignItems: 'center',
        gap: '80px',
        padding: '80px 24px',
        flexWrap: 'wrap',         /* 좁은 화면에서 세로로 쌓임 */
        justifyContent: 'center',
      }}>

        {/* ── 왼쪽 텍스트 영역 ──
            motion.div로 감싸 마운트 시 왼쪽에서 슬라이드인 애니메이션 적용
            initial: x:-30(왼쪽 30px 이동) + opacity:0
            animate: x:0, opacity:1 → 원래 위치로 이동하며 나타남
            flex: '1 1 400px' → 최소 400px, 남은 공간을 채우도록 늘어남 */}
        <motion.div
          initial={{ opacity: 0, x: -30 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.7, ease: 'easeOut' }}
          style={{ flex: '1 1 400px', maxWidth: '540px' }}
        >
          {/* 기술 배지 뱃지 — "라이브" 느낌의 초록 점 + 기술 설명 */}
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '8px',
            padding: '6px 14px',
            borderRadius: '50px',
            border: '1px solid rgba(0,122,255,0.25)',
            background: 'rgba(0,122,255,0.06)',
            marginBottom: '28px',
          }}>
            {/* 초록 점 — box-shadow로 빛나는 효과 (glow effect) */}
            <span style={{
              width: '6px', height: '6px',
              borderRadius: '50%',
              background: '#30D158',
              boxShadow: '0 0 8px #30D158', /* 초록색 글로우 */
              display: 'inline-block',
            }} />
            <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--primary)' }}>
              온디바이스 AI · Vision + CoreML
            </span>
          </div>

          {/* 메인 헤드라인 h1
              clamp(최소, 선호, 최대): 반응형 폰트 크기
              className="gradient-text": index.css의 그라디언트 텍스트 적용 */}
          <h1 style={{
            fontSize: 'clamp(2.4rem, 5vw, 3.8rem)',
            fontWeight: 900,
            letterSpacing: '-0.04em',
            lineHeight: 1.05,
            marginBottom: '24px',
            color: 'var(--text-primary)',
          }}>
            당신의 몰입을<br />
            <span className="gradient-text">완성하는 시간</span>
          </h1>

          {/* 부제목 — 앱의 핵심 가치를 2~3 문장으로 설명 */}
          <p style={{
            fontSize: '1.15rem',
            color: 'var(--text-secondary)',
            lineHeight: 1.7,
            marginBottom: '40px',
            maxWidth: '440px',
          }}>
            AI가 카메라로 눈 상태를 실시간 분석하여, 진짜 집중한 시간만 측정합니다.
            졸음이 감지되면 자동 일시정지. 서버 없이, 기기 안에서만.
          </p>

          {/* CTA 버튼 그룹 */}
          <div style={{ display: 'flex', gap: '14px', flexWrap: 'wrap' }}>
            {/* 주 버튼: App Store 다운로드 */}
            <a href="#download" className="btn-primary" style={{ fontSize: '1rem', padding: '14px 28px' }}>
              {/* SVG 애플 로고 — fill="currentColor"로 부모의 color 속성을 사용 */}
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              App Store
            </a>
            {/* 보조 버튼: 기능 섹션으로 스크롤 이동 */}
            <a href="#features" className="btn-secondary" style={{ fontSize: '1rem', padding: '14px 28px' }}>
              기능 살펴보기
              {/* 화살표 아이콘 — fill="none" + stroke로 아웃라인 스타일 */}
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <path d="M5 12h14M12 5l7 7-7 7" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </a>
          </div>

          {/* 기술 스펙 통계 — 구분선 아래에 3개 수치 표시 */}
          <div style={{
            display: 'flex',
            gap: '32px',
            marginTop: '52px',
            paddingTop: '32px',
            borderTop: '1px solid var(--border)',
          }}>
            {/* 통계 데이터 배열을 map()으로 렌더링 */}
            {[
              { value: '70%', label: 'Vision Framework' },
              { value: '30%', label: 'CoreML 모델' },
              { value: '3s',  label: '자리비움 감지' },
            ].map(stat => (
              <div key={stat.label}>
                <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--primary)', letterSpacing: '-0.03em' }}>
                  {stat.value}
                </div>
                <div style={{ fontSize: '0.78rem', color: 'var(--text-tertiary)', marginTop: '2px' }}>
                  {stat.label}
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* ── 오른쪽 폰 목업 영역 ──
            delay: 0.2 → 텍스트보다 0.2초 늦게 등장하여 순차적 느낌 부여
            initial: y:30(아래) → animate: y:0(원래 위치)으로 위로 올라오는 효과 */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.2, ease: 'easeOut' }}
          style={{
            flex: '0 0 auto',  /* 크기가 내용에 맞게 고정 (늘어나거나 줄어들지 않음) */
            display: 'flex',
            justifyContent: 'center',
            position: 'relative',
          }}
        >
          {/* 폰 아래 글로우 효과
              filter: blur() — 흐릿하게 처리하여 은은한 빛 효과 */}
          <div style={{
            position: 'absolute',
            bottom: '-40px',
            left: '50%',
            transform: 'translateX(-50%)',
            width: '200px', height: '80px',
            background: 'radial-gradient(ellipse, rgba(0,122,255,0.3) 0%, transparent 70%)',
            filter: 'blur(20px)',
            pointerEvents: 'none',
          }} />
          <PhoneMockup />
        </motion.div>
      </div>
    </section>
  );
}
