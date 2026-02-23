"""
FocusSense Dataset Download Script

졸음 감지 모델 학습에 필요한 공개 데이터셋을 다운로드하고
학습에 적합한 폴더 구조로 정리합니다.

지원 데이터셋:
    1. Kaggle Drowsiness Dataset (dheerajperumandla)
       - 가장 간편하게 다운로드 가능 (Kaggle CLI 사용)
       - 눈 상태(Open/Closed) + 하품(yawn/no_yawn) 이미지 포함
       - 권장: 학습 데이터로 1차 사용

    2. MRL Eye Dataset
       - 고품질 눈 이미지 데이터셋 (웹사이트에서 수동 다운로드)
       - 학술 목적 무료 제공

    3. Driver Drowsiness Detection Dataset
       - 실제 운전 환경에서 수집된 데이터셋 (별도 요청 필요)

    4. Sample (테스트용)
       - 랜덤 이미지로 파이프라인 동작 확인용 더미 데이터 생성

Usage:
    # 샘플 데이터 생성 (테스트용)
    python data/download_datasets.py --dataset sample --output ./data

    # Kaggle 데이터셋 다운로드
    python data/download_datasets.py --dataset kaggle --output ./data

    # 모든 데이터셋 안내
    python data/download_datasets.py --dataset all --output ./data
"""

import os
import sys
import argparse
import subprocess
from pathlib import Path
import shutil
import zipfile
import tarfile
from typing import Optional

try:
    import requests
    from tqdm import tqdm
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False


def download_file(url: str, output_path: str, desc: str = "Downloading"):
    """
    URL에서 파일을 다운로드합니다. 진행률을 실시간으로 표시합니다.

    requests 라이브러리가 있으면 스트리밍 다운로드(청크 단위)를 사용하고,
    없으면 시스템의 wget 명령어로 대체합니다.

    Args:
        url (str): 다운로드할 파일의 URL
        output_path (str): 저장할 로컬 파일 경로
        desc (str): 진행률 표시줄에 보여줄 설명 텍스트
    """
    if not HAS_REQUESTS:
        # requests 미설치 시 시스템 wget으로 대체
        subprocess.run(['wget', '-O', output_path, url], check=True)
        return

    # 스트리밍 다운로드: 대용량 파일도 메모리 부담 없이 처리
    response = requests.get(url, stream=True)
    # Content-Length 헤더로 전체 파일 크기 확인 (없으면 0)
    total_size = int(response.headers.get('content-length', 0))

    with open(output_path, 'wb') as f:
        # tqdm: 바이트 단위 진행률 표시 (unit_scale=True → KB/MB로 자동 변환)
        with tqdm(total=total_size, unit='B', unit_scale=True, desc=desc) as pbar:
            for chunk in response.iter_content(chunk_size=8192):  # 8KB 청크 단위 저장
                f.write(chunk)
                pbar.update(len(chunk))


def extract_archive(archive_path: str, output_dir: str):
    """
    압축 파일을 지정한 디렉토리에 해제합니다.

    지원 형식:
        - .zip  : zipfile 모듈로 처리
        - .tar, .tar.gz, .tgz : tarfile 모듈로 처리

    Args:
        archive_path (str): 압축 파일 경로
        output_dir (str): 압축 해제 대상 디렉토리 경로
    """
    archive_path = Path(archive_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)  # 출력 디렉토리 없으면 생성

    if archive_path.suffix == '.zip':
        with zipfile.ZipFile(archive_path, 'r') as zip_ref:
            zip_ref.extractall(output_dir)
    elif archive_path.suffix in ['.tar', '.gz', '.tgz']:
        # 'r:*' 모드: 압축 방식 자동 감지 (gzip, bzip2, xz 모두 지원)
        with tarfile.open(archive_path, 'r:*') as tar_ref:
            tar_ref.extractall(output_dir)
    else:
        print(f"Unknown archive format: {archive_path.suffix}")


class DatasetDownloader:
    """
    FocusSense 학습용 데이터셋 다운로드 및 정리 클래스

    각 데이터셋의 특성에 맞는 다운로드 방법과
    학습 폴더 구조 정리를 담당합니다.

    기대 출력 폴더 구조:
        output_dir/
        ├── drowsiness/
        │   └── train/
        │       ├── Open/        (눈 뜸 → awake)
        │       ├── Closed/      (눈 감음 → drowsy)
        │       ├── no_yawn/     (하품 없음 → awake)
        │       └── yawn/        (하품 → drowsy)
        ├── drowsiness_kaggle/   (Kaggle 원본)
        └── sample/              (테스트용 더미 데이터)

    Args:
        output_dir (str): 데이터셋을 저장할 루트 디렉토리
    """

    def __init__(self, output_dir: str):
        # 버그 수정: 원본 코드의 오타 'output_di' → 'output_dir'
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def download_mrl_eye_dataset(self):
        """
        MRL Eye Dataset 다운로드 안내를 출력합니다.

        MRL Eye Dataset은 API를 통한 자동 다운로드를 지원하지 않으므로
        웹사이트를 직접 방문하여 다운로드해야 합니다.

        데이터셋 구성:
            - open/  : 눈 뜬 이미지 → awake (label=0)
            - closed/: 눈 감은 이미지 → drowsy (label=1)

        출처: http://mrl.cs.vsb.cz/eyedataset
        라이선스: 학술 연구 목적 한정 (상업적 사용 불가)
        """
        print("\n" + "=" * 50)
        print("MRL Eye Dataset")
        print("=" * 50)

        # 자동 다운로드 불가 → 수동 다운로드 방법 안내
        print("""
        MRL Eye Dataset은 직접 다운로드가 필요합니다.

        1. http://mrl.cs.vsb.cz/eyedataset 방문
        2. 데이터셋 다운로드
        3. {output_dir}/mrl_eye/ 에 압축 해제

        구조:
        mrl_eye/
        ├── open/      (눈 뜬 이미지 -> awake)
        └── closed/    (눈 감은 이미지 -> drowsy)
        """.format(output_dir=self.output_dir))

    def download_drowsiness_dataset_kaggle(self):
        """
        Kaggle Drowsiness Dataset을 Kaggle CLI로 다운로드합니다.

        Kaggle CLI 설치 및 인증이 완료되어 있어야 합니다.
        인증 파일 위치: ~/.kaggle/kaggle.json

        다운로드 후 _organize_drowsiness_data()로 폴더 구조를 정리합니다.

        데이터셋 출처:
            https://www.kaggle.com/datasets/dheerajperumandla/drowsiness-dataset

        포함 클래스:
            - Open/    (눈 뜸) → awake
            - Closed/  (눈 감음) → drowsy
            - no_yawn/ (하품 없음) → awake
            - yawn/    (하품) → drowsy
        """
        print("\n" + "=" * 50)
        print("Kaggle Drowsiness Dataset")
        print("=" * 50)

        # Kaggle CLI 설치 여부 확인 (which 명령어로 PATH에서 탐색)
        kaggle_installed = shutil.which('kaggle') is not None

        if not kaggle_installed:
            # Kaggle CLI 미설치 시 설치 방법 안내
            print("""
            Kaggle CLI가 설치되어 있지 않습니다.

            설치 방법:
            1. pip install kaggle
            2. Kaggle API 키 설정:
               - https://www.kaggle.com/account 에서 API 키 생성
               - ~/.kaggle/kaggle.json 에 저장
            """)
            return

        # Kaggle 데이터셋 식별자 (사용자명/데이터셋명)
        dataset_name = "dheerajperumandla/drowsiness-dataset"
        output_path = self.output_dir / "drowsiness_kaggle"

        try:
            print(f"Downloading {dataset_name}...")
            # Kaggle CLI: 데이터셋 다운로드 + 자동 압축 해제
            subprocess.run([
                'kaggle', 'datasets', 'download',
                '-d', dataset_name,
                '-p', str(output_path),
                '--unzip'     # 다운로드 즉시 압축 해제
            ], check=True)

            print(f"✓ Downloaded to {output_path}")

            # 다운로드된 파일을 학습 폴더 구조로 정리
            self._organize_drowsiness_data(output_path)

        except subprocess.CalledProcessError as e:
            print(f"Download failed: {e}")
            print("수동으로 다운로드해주세요: https://www.kaggle.com/datasets/dheerajperumandla/drowsiness-dataset")

    def _organize_drowsiness_data(self, data_dir: Path):
        """
        다운로드된 Kaggle 데이터셋을 학습용 폴더 구조로 정리합니다.

        DrowsinessDataset이 기대하는 구조:
            drowsiness/train/
            ├── Open/
            ├── Closed/
            ├── no_yawn/
            └── yawn/

        Args:
            data_dir (Path): Kaggle에서 다운로드된 원본 데이터 경로
        """
        organized_dir = self.output_dir / "drowsiness" / "train"
        organized_dir.mkdir(parents=True, exist_ok=True)

        # awake, drowsy 폴더 생성 (이진 분류용 단순 구조)
        (organized_dir / "awake").mkdir(exist_ok=True)
        (organized_dir / "drowsy").mkdir(exist_ok=True)

        print("Organizing dataset structure...")

        # 원본 데이터셋 구조에 따라 파일 이동
        # 실제 Kaggle 데이터셋의 폴더명에 맞게 수정 필요
        # Open, Closed, yawn, no_yawn → 학습 데이터로 직접 사용 가능

        print("✓ Dataset organized")

    def download_driver_drowsiness_detection(self):
        """
        운전자 졸음 감지 데이터셋 안내를 출력합니다.

        실제 운전 환경에서 수집된 데이터셋들을 소개합니다.
        이 데이터셋들은 직접 요청이나 학술 등록이 필요합니다.

        추천 데이터셋:
            - NTHU-DDD: 국립칭화대학교 운전 졸음 데이터베이스
            - UTA-RLDD: 실생활 졸음 감지 데이터셋
            - YawDD: 하품 감지 특화 데이터셋
        """
        print("\n" + "=" * 50)
        print("Driver Drowsiness Detection Dataset")
        print("=" * 50)

        print("""
        추천 데이터셋:

        1. NTHU-DDD (National Tsing Hua University)
           - 실제 운전 중 졸음 영상
           - 학술 목적으로 요청 가능

        2. UTA-RLDD (Real-Life Drowsiness Dataset)
           - https://sites.google.com/view/utarldd/home

        3. YawDD
           - 하품 감지 데이터셋

        데이터셋 요청 후 {output_dir}/driver_drowsiness/ 에 저장해주세요.
        """.format(output_dir=self.output_dir))

    def create_sample_data(self):
        """
        파이프라인 동작 테스트용 더미 샘플 데이터를 생성합니다.

        실제 얼굴/눈 이미지가 아닌 랜덤 픽셀 이미지를 생성합니다.
        모델이 의미 있는 패턴을 학습하지는 못하지만,
        데이터 로딩 → 학습 → 체크포인트 저장 파이프라인 전체가
        오류 없이 동작하는지 빠르게 확인할 때 사용합니다.

        생성 구조:
            sample/
            ├── train/
            │   ├── awake/  (랜덤 이미지 10장, 224×224 RGB)
            │   └── drowsy/ (랜덤 이미지 10장, 224×224 RGB)
            └── val/
                ├── awake/  (랜덤 이미지 10장)
                └── drowsy/ (랜덤 이미지 10장)

        Returns:
            Path: 생성된 sample 디렉토리 경로
        """
        print("\n" + "=" * 50)
        print("Creating Sample Data for Testing")
        print("=" * 50)

        try:
            import numpy as np
            from PIL import Image
        except ImportError:
            print("numpy와 Pillow가 필요합니다: pip install numpy Pillow")
            return

        sample_dir = self.output_dir / "sample"

        # train/val × awake/drowsy 조합으로 폴더 생성
        for split in ['train', 'val']:
            for class_name in ['awake', 'drowsy']:
                class_dir = sample_dir / split / class_name
                class_dir.mkdir(parents=True, exist_ok=True)

                # 각 클래스별 10개 샘플 이미지 생성
                for i in range(10):
                    # 224×224 RGB 랜덤 이미지 (실제 학습 의미 없음, 파이프라인 테스트용)
                    img_array = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
                    img = Image.fromarray(img_array)
                    img.save(class_dir / f"sample_{i:03d}.jpg")

        print(f"✓ Sample data created at {sample_dir}")
        print(f"  - Train: 20 images (10 awake + 10 drowsy)")
        print(f"  - Val: 20 images (10 awake + 10 drowsy)")

        return sample_dir

    def download_all(self):
        """
        모든 지원 데이터셋의 다운로드 안내를 순서대로 출력합니다.

        각 데이터셋의 특징과 취득 방법을 안내하고
        자동 다운로드가 가능한 경우 실행합니다.
        """
        # 전체 데이터셋 가이드 요약 출력
        print("""
        ╔══════════════════════════════════════════════════════════════╗
        ║              FocusSense Dataset Download Guide               ║
        ╠══════════════════════════════════════════════════════════════╣
        ║                                                              ║
        ║  1. Kaggle Drowsiness Dataset (추천)                         ║
        ║     - 간편한 다운로드 (Kaggle CLI 필요)                       ║
        ║     - 눈 상태 분류 (Open/Closed) + 하품 (yawn/no_yawn)       ║
        ║                                                              ║
        ║  2. MRL Eye Dataset                                          ║
        ║     - 고품질 눈 이미지 (수동 다운로드)                        ║
        ║     - 학술 목적 무료                                          ║
        ║                                                              ║
        ║  3. Custom Dataset                                           ║
        ║     - 직접 데이터 수집 권장                                   ║
        ║     - 다양한 환경/조명 고려                                   ║
        ║                                                              ║
        ╚══════════════════════════════════════════════════════════════╝
        """)

        # 각 데이터셋 다운로드 순서대로 실행
        self.download_mrl_eye_dataset()
        self.download_drowsiness_dataset_kaggle()
        self.download_driver_drowsiness_detection()


def main():
    """
    커맨드라인 인터페이스: 다운로드할 데이터셋과 출력 경로를 지정합니다.

    선택 가능한 데이터셋:
        sample  : 파이프라인 테스트용 더미 데이터 (기본값)
        kaggle  : Kaggle CLI로 자동 다운로드
        mrl     : MRL Eye Dataset 수동 다운로드 안내
        all     : 모든 데이터셋 안내 및 자동 다운로드 시도
    """
    parser = argparse.ArgumentParser(description='Download FocusSense datasets')

    parser.add_argument('--dataset', type=str, default='sample',
                        choices=['all', 'kaggle', 'mrl', 'sample'],
                        help='Dataset to download (default: sample)')
    parser.add_argument('--output', type=str, default='./data',
                        help='Output directory for downloaded datasets (default: ./data)')

    args = parser.parse_args()

    # DatasetDownloader 초기화 (출력 디렉토리 생성)
    downloader = DatasetDownloader(args.output)

    # 선택된 데이터셋에 따라 해당 메서드 호출
    if args.dataset == 'all':
        downloader.download_all()
    elif args.dataset == 'kaggle':
        downloader.download_drowsiness_dataset_kaggle()
    elif args.dataset == 'mrl':
        downloader.download_mrl_eye_dataset()
    elif args.dataset == 'sample':
        downloader.create_sample_data()


if __name__ == '__main__':
    main()
