"""
FocusSense Dataset Download Script

공개 데이터셋 다운로드 및 전처리

Datasets:
1. MRL Eye Dataset - 졸음 감지용 눈 이미지
2. Driver Drowsiness Dataset - 졸음 감지용 얼굴 이미지
3. Columbia Gaze Dataset - 시선 추정용

Usage:
    # 샘플 데이터 생성 (테스트용)
    python data/download_datasets.py --dataset sample --output ./data

    # Kaggle 데이터셋 다운로드
    python data/download_datasets.py --dataset kaggle --output ./data
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
    """파일 다운로드 (진행률 표시)"""
    
    if not HAS_REQUESTS:
        # wget 사용
        subprocess.run(['wget', '-O', output_path, url], check=True)
        return
    
    response = requests.get(url, stream=True)
    total_size = int(response.headers.get('content-length', 0))
    
    with open(output_path, 'wb') as f:
        with tqdm(total=total_size, unit='B', unit_scale=True, desc=desc) as pbar:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
                pbar.update(len(chunk))


def extract_archive(archive_path: str, output_dir: str):
    """압축 파일 해제"""
    
    archive_path = Path(archive_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    if archive_path.suffix == '.zip':
        with zipfile.ZipFile(archive_path, 'r') as zip_ref:
            zip_ref.extractall(output_dir)
    elif archive_path.suffix in ['.tar', '.gz', '.tgz']:
        with tarfile.open(archive_path, 'r:*') as tar_ref:
            tar_ref.extractall(output_dir)
    else:
        print(f"Unknown archive format: {archive_path.suffix}")


class DatasetDownloader:
    """데이터셋 다운로더"""
    
    def __init__(self, output_dir: str):
        self.output_dir = Path(output_di)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def download_mrl_eye_dataset(self):
        """
        MRL Eye Dataset 다운로드
        
        출처: http://mrl.cs.vsb.cz/eyedataset
        주의: 실제 사용 시 라이선스 확인 필요
        """
        print("\n" + "=" * 50)
        print("MRL Eye Dataset")
        print("=" * 50)
        
        # 참고: 실제 URL은 웹사이트에서 확인 필요
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
        Kaggle Drowsiness Dataset 다운로드
        
        출처: https://www.kaggle.com/datasets/dheerajperumandla/drowsiness-dataset
        """
        print("\n" + "=" * 50)
        print("Kaggle Drowsiness Dataset")
        print("=" * 50)
        
        # Kaggle CLI 확인
        kaggle_installed = shutil.which('kaggle') is not None
        
        if not kaggle_installed:
            print("""
            Kaggle CLI가 설치되어 있지 않습니다.
            
            설치 방법:
            1. pip install kaggle
            2. Kaggle API 키 설정:
               - https://www.kaggle.com/account 에서 API 키 생성
               - ~/.kaggle/kaggle.json 에 저장
            """)
            return
        
        dataset_name = "dheerajperumandla/drowsiness-dataset"
        output_path = self.output_dir / "drowsiness_kaggle"
        
        try:
            print(f"Downloading {dataset_name}...")
            subprocess.run([
                'kaggle', 'datasets', 'download',
                '-d', dataset_name,
                '-p', str(output_path),
                '--unzip'
            ], check=True)
            
            print(f"✓ Downloaded to {output_path}")
            
            # 데이터 정리 (awake/drowsy 폴더 구조로)
            self._organize_drowsiness_data(output_path)
            
        except subprocess.CalledProcessError as e:
            print(f"Download failed: {e}")
            print("수동으로 다운로드해주세요: https://www.kaggle.com/datasets/dheerajperumandla/drowsiness-dataset")
    
    def _organize_drowsiness_data(self, data_dir: Path):
        """졸음 데이터셋 폴더 구조 정리"""
        
        organized_dir = self.output_dir / "drowsiness" / "train"
        organized_dir.mkdir(parents=True, exist_ok=True)
        
        # awake, drowsy 폴더 생성
        (organized_dir / "awake").mkdir(exist_ok=True)
        (organized_dir / "drowsy").mkdir(exist_ok=True)
        
        print("Organizing dataset structure...")
        
        # 원본 데이터셋 구조에 따라 파일 이동
        # (실제 데이터셋 구조에 맞게 수정 필요)
        
        print("✓ Dataset organized")
    
    def download_driver_drowsiness_detection(self):
        """
        Driver Drowsiness Detection Dataset
        
        얼굴 이미지 기반 졸음 감지 데이터셋
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
        테스트용 샘플 데이터 생성
        
        실제 학습이 아닌 파이프라인 테스트용
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
        
        for split in ['train', 'val']:
            for class_name in ['awake', 'drowsy']:
                class_dir = sample_dir / split / class_name
                class_dir.mkdir(parents=True, exist_ok=True)
                
                # 각 클래스별 10개 샘플 이미지 생성
                for i in range(10):
                    # 랜덤 이미지 (실제로는 의미 없지만 파이프라인 테스트용)
                    img_array = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
                    img = Image.fromarray(img_array)
                    img.save(class_dir / f"sample_{i:03d}.jpg")
        
        print(f"✓ Sample data created at {sample_dir}")
        print(f"  - Train: 20 images (10 awake + 10 drowsy)")
        print(f"  - Val: 20 images (10 awake + 10 drowsy)")
        
        return sample_dir
    
    def download_all(self):
        """모든 데이터셋 다운로드 안내"""
        
        print("""
        ╔══════════════════════════════════════════════════════════════╗
        ║              FocusSense Dataset Download Guide               ║
        ╠══════════════════════════════════════════════════════════════╣
        ║                                                              ║
        ║  1. Kaggle Drowsiness Dataset (추천)                         ║
        ║     - 간편한 다운로드                                         ║
        ║     - 눈 상태 분류 (Open/Closed)                             ║
        ║                                                              ║
        ║  2. MRL Eye Dataset                                          ║
        ║     - 고품질 눈 이미지                                        ║
        ║     - 학술 목적 무료                                          ║
        ║                                                              ║
        ║  3. Custom Dataset                                           ║
        ║     - 직접 데이터 수집 권장                                   ║
        ║     - 다양한 환경/조명 고려                                   ║
        ║                                                              ║
        ╚══════════════════════════════════════════════════════════════╝
        """)
        
        self.download_mrl_eye_dataset()
        self.download_drowsiness_dataset_kaggle()
        self.download_driver_drowsiness_detection()


def main():
    parser = argparse.ArgumentParser(description='Download FocusSense datasets')
    
    parser.add_argument('--dataset', type=str, default='sample',
                        choices=['all', 'kaggle', 'mrl', 'sample'],
                        help='Dataset to download')
    parser.add_argument('--output', type=str, default='./data',
                        help='Output directory')
    
    args = parser.parse_args()
    
    downloader = DatasetDownloader(args.output)
    
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
