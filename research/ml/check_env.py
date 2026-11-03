"""
FocusSense ML 환경 검증 스크립트

ML 파이프라인 실행 전 필수 라이브러리들이 올바르게 설치되어 있는지 확인합니다.
이 스크립트를 먼저 실행하여 개발 환경이 준비되었는지 점검하세요.

실행 방법:
    python check_env.py
"""

import sys
import importlib.util


def check_library(name, alias=None):
    """
    단일 라이브러리의 설치 여부와 버전을 확인합니다.

    Args:
        name (str): 표시할 라이브러리 이름 (예: "torch", "cv2")
        alias (str, optional): 실제 import 시 사용하는 모듈명.
                               패키지명과 import명이 다를 때 사용
                               (예: opencv-python은 'cv2'로 import)

    Returns:
        bool: 설치되어 있으면 True, 아니면 False
    """
    # alias가 지정되면 그것으로, 없으면 name으로 import 시도
    module_name = alias if alias else name
    try:
        # importlib으로 모듈 경로 탐색 (실제 import 없이 존재 여부 먼저 확인)
        spec = importlib.util.find_spec(module_name)
        if spec is None:
            raise ImportError

        # 실제 모듈 import
        module = __import__(module_name)

        # __version__ 속성으로 버전 정보 읽기 (없는 경우 대체 텍스트 표시)
        version = getattr(module, '__version__', '버전 정보 없음')
        print(f"✅ [성공] {name:<15} : v{version}")
        return True
    except ImportError:
        # 모듈이 설치되지 않은 경우
        print(f"❌ [실패] {name:<15} : 설치되지 않음")
        return False
    except Exception as e:
        # import는 되었지만 그 외 오류 발생
        print(f"⚠️ [에러] {name:<15} : {e}")
        return False


# Python 버전 출력 (ML 라이브러리들은 Python 3.8+ 권장)
print(f"🐍 Python Version: {sys.version.split()[0]}")
print("-" * 40)

# ---------------------------------------------------------------
# 검사할 라이브러리 목록
# (표시명, 실제 import명) 쌍으로 구성
# import명이 None이면 표시명을 그대로 사용
# ---------------------------------------------------------------
libraries = [
    ("dlib", None),          # 얼굴/랜드마크 검출 (EAR 계산에 사용)
    ("torch", None),          # PyTorch: 딥러닝 학습 프레임워크
    ("cv2", "cv2"),           # OpenCV: 이미지 처리 (pip: opencv-python)
    ("mediapipe", None),      # Google MediaPipe: 실시간 얼굴/눈 검출
    ("numpy", None),          # NumPy: 수치 연산 배열
    ("pandas", None),         # Pandas: 데이터 분석 및 CSV 처리
    ("PIL", "PIL"),           # Pillow: 이미지 입출력 (pip: pillow)
    ("coremltools", None),    # Apple CoreML 변환 도구 (macOS 전용)
]

# ---------------------------------------------------------------
# 검사 실행 - 모든 라이브러리를 순서대로 확인
# ---------------------------------------------------------------
all_success = True
for lib_name, lib_alias in libraries:
    if not check_library(lib_name, lib_alias):
        all_success = False  # 하나라도 실패하면 전체 실패로 표시

print("-" * 40)

# 최종 결과 출력
if all_success:
    print("🎉 축하합니다! 모든 핵심 라이브러리가 정상입니다.")
    print("이제 개발을 시작하셔도 좋습니다.")
else:
    print("😢 일부 라이브러리에 문제가 있습니다. 다시 확인해주세요.")
    print("\n설치 명령어 예시:")
    print("  pip install torch torchvision torchaudio")
    print("  pip install opencv-python mediapipe numpy pandas pillow")
    print("  pip install coremltools  # macOS 환경에서만 설치 가능")
