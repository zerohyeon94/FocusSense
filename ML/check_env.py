import sys
import importlib.util

def check_library(name, alias=None):
    module_name = alias if alias else name
    try:
        # 라이브러리 임포트 시도
        spec = importlib.util.find_spec(module_name)
        if spec is None:
            raise ImportError
        
        module = __import__(module_name)
        
        # 버전 확인 시도
        version = getattr(module, '__version__', '버전 정보 없음')
        print(f"✅ [성공] {name:<15} : v{version}")
        return True
    except ImportError:
        print(f"❌ [실패] {name:<15} : 설치되지 않음")
        return False
    except Exception as e:
        print(f"⚠️ [에러] {name:<15} : {e}")
        return False

print(f"🐍 Python Version: {sys.version.split()[0]}")
print("-" * 40)

# 필수 라이브러리 목록
libraries = [
    ("dlib", None),
    ("torch", None),
    ("cv2", "cv2"),          # opencv-python
    ("mediapipe", None),
    ("numpy", None),
    ("pandas", None),
    ("PIL", "PIL"),          # pillow
    ("coremltools", None),   # 맥 환경이라 중요
]

# 검사 실행
all_success = True
for lib_name, lib_alias in libraries:
    if not check_library(lib_name, lib_alias):
        all_success = False

print("-" * 40)
if all_success:
    print("🎉 축하합니다! 모든 핵심 라이브러리가 정상입니다.")
    print("이제 개발을 시작하셔도 좋습니다.")
else:
    print("😢 일부 라이브러리에 문제가 있습니다. 다시 확인해주세요.")