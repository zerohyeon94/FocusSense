"""
FocusSense Dataset Loader

Kaggle Drowsiness Dataset 활용:
- Open / Closed (눈 상태)
- yawn / no_yawn (하품 여부)

이진 분류로 매핑:
- awake: Open + no_yawn  (눈 뜸 또는 하품 안 함 → 깨어있음)
- drowsy: Closed + yawn  (눈 감음 또는 하품 → 졸림)

데이터 흐름:
    원본 폴더(Open/Closed/yawn/no_yawn)
        → DrowsinessDataset (레이블 매핑 + 이미지 경로 수집)
        → random_split (train/val 분리)
        → TransformSubset (각 분할에 맞는 augmentation 적용)
        → DataLoader (배치 단위 공급)
"""

import os
from pathlib import Path
from typing import Tuple, List, Optional, Any

import torch
from torch.utils.data import Dataset, DataLoader, random_split
import numpy as np
import cv2

# Albumentations: 고성능 이미지 증강 라이브러리 (torchvision 대비 빠르고 다양)
try:
    import albumentations as A
    from albumentations.pytorch import ToTensorV2
    HAS_ALBUMENTATIONS = True
except ImportError:
    HAS_ALBUMENTATIONS = False
    print("Warning: albumentations not installed. Using basic transforms.")


# ---------------------------------------------------------------
# 클래스 레이블 매핑
# Kaggle 데이터셋의 폴더명 → 이진 레이블(0: awake, 1: drowsy)
# ---------------------------------------------------------------
KAGGLE_CLASS_MAP = {
    'Open': 0,      # 눈 뜬 상태 → 깨어있음 (awake)
    'Closed': 1,    # 눈 감은 상태 → 졸림 (drowsy)
    'no_yawn': 0,   # 하품 안 함 → 깨어있음 (awake)
    'yawn': 1,      # 하품 함 → 졸림 (drowsy)
}

# 인덱스 → 클래스명 역매핑 (추론 결과 출력 시 사용)
IDX_TO_CLASS = {0: 'awake', 1: 'drowsy'}


class DrowsinessDataset(Dataset):
    """
    졸음 감지 데이터셋

    Kaggle Drowsiness Dataset 폴더 구조를 읽어
    이진 분류(awake/drowsy)를 위한 PyTorch Dataset으로 래핑합니다.

    기대 폴더 구조:
        data/drowsiness_kaggle/train/
        ├── Open/        → awake (label=0)
        ├── Closed/      → drowsy (label=1)
        ├── no_yawn/     → awake (label=0)
        └── yawn/        → drowsy (label=1)

    Args:
        root_dir (str): 데이터셋 루트 디렉토리 경로
        transform: 이미지 변환 파이프라인 (Albumentations 또는 torchvision)
        class_map (dict, optional): 폴더명 → 레이블 매핑.
                                    None이면 KAGGLE_CLASS_MAP 사용
    """

    def __init__(
        self,
        root_dir: str,
        transform: Optional[Any] = None,
        class_map: Optional[dict] = None,
    ):
        self.root_dir = Path(root_dir)
        self.transform = transform
        self.class_map = class_map or KAGGLE_CLASS_MAP
        self.idx_to_class = IDX_TO_CLASS

        # (이미지 경로, 레이블) 쌍의 리스트
        self.samples: List[Tuple[Path, int]] = []
        self._load_samples()

    def _load_samples(self):
        """
        class_map에 정의된 폴더들을 순회하며
        이미지 경로와 레이블을 self.samples에 수집합니다.

        지원 확장자: .jpg, .JPG, .png, .PNG, .jpeg, .JPEG
        존재하지 않는 폴더는 경고 출력 후 건너뜁니다.
        """
        for folder_name, label in self.class_map.items():
            folder_dir = self.root_dir / folder_name
            if not folder_dir.exists():
                print(f"Warning: {folder_dir} not found, skipping")
                continue

            # 대소문자 구분 없이 이미지 확장자 검색
            for ext in ('*.[jJ][pP][gG]', '*.[pP][nN][gG]', '*.[jJ][pP][eE][gG]'):
                for img_path in folder_dir.glob(ext):
                    self.samples.append((img_path, label))

        # 클래스별 샘플 수 출력 (데이터 불균형 확인용)
        counts = {}
        for _, label in self.samples:
            name = self.idx_to_class[label]
            counts[name] = counts.get(name, 0) + 1

        print(f"Loaded {len(self.samples)} samples from {self.root_dir}")
        for name, count in sorted(counts.items()):
            print(f"  - {name}: {count}")

    def __len__(self) -> int:
        """전체 샘플 수 반환"""
        return len(self.samples)

    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, int]:
        """
        인덱스로 이미지와 레이블을 반환합니다.

        이미지는 OpenCV로 BGR로 읽힌 후 RGB로 변환됩니다.
        transform이 있으면 augmentation 후 Tensor로 변환됩니다.

        Args:
            idx (int): 샘플 인덱스

        Returns:
            (image_tensor, label): 변환된 이미지 텐서와 정수 레이블
        """
        img_path, label = self.samples[idx]

        # OpenCV는 BGR로 읽으므로 RGB로 변환 (PyTorch/torchvision 표준)
        image = cv2.imread(str(img_path))
        if image is None:
            raise RuntimeError(f"Failed to load image: {img_path}")
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        # Albumentations는 dict 형태로 반환, torchvision은 직접 반환
        if self.transform:
            if HAS_ALBUMENTATIONS:
                transformed = self.transform(image=image)
                image = transformed['image']
            else:
                image = self.transform(image)

        return image, label


# ================================================================
# Transforms / Augmentations
# ================================================================

def get_train_transforms(image_size: int = 224):
    """
    학습용 데이터 증강 파이프라인을 반환합니다.

    Albumentations 설치 시 더 다양한 증강 사용,
    미설치 시 torchvision의 기본 변환으로 대체합니다.

    적용 증강 목록 (Albumentations):
        - Resize: 224×224로 크기 조정
        - HorizontalFlip: 좌우 반전 (p=0.5)
        - RandomBrightnessContrast: 밝기/대비 랜덤 조정 (p=0.3)
        - GaussNoise: 가우시안 노이즈 추가 (p=0.2)
        - GaussianBlur: 블러 처리 (p=0.1)
        - Rotate: ±15도 회전 (p=0.3)
        - Normalize: ImageNet 통계로 정규화 (mean/std)
        - ToTensorV2: numpy → torch.Tensor 변환

    Args:
        image_size (int): 출력 이미지 크기 (기본값: 224)

    Returns:
        transform: 증강 파이프라인 객체
    """
    if HAS_ALBUMENTATIONS:
        return A.Compose([
            A.Resize(image_size, image_size),
            A.HorizontalFlip(p=0.5),                          # 좌우 반전으로 데이터 다양성 증가
            A.RandomBrightnessContrast(p=0.3),                 # 다양한 조명 환경 시뮬레이션
            A.GaussNoise(p=0.2),                               # 카메라 노이즈 시뮬레이션
            A.GaussianBlur(blur_limit=3, p=0.1),               # 초점 흔들림 시뮬레이션
            A.Rotate(limit=15, p=0.3),                         # 고개 기울임 시뮬레이션
            A.Normalize(
                mean=[0.485, 0.456, 0.406],                    # ImageNet RGB 평균값
                std=[0.229, 0.224, 0.225],                     # ImageNet RGB 표준편차
            ),
            ToTensorV2(),                                       # HWC numpy → CHW tensor
        ])
    else:
        # Albumentations 없을 때 torchvision 기본 변환 사용
        import torchvision.transforms as T
        return T.Compose([
            T.ToPILImage(),
            T.Resize((image_size, image_size)),
            T.RandomHorizontalFlip(),
            T.ToTensor(),
            T.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225],
            ),
        ])


def get_val_transforms(image_size: int = 224):
    """
    검증/테스트용 Transform 파이프라인을 반환합니다.

    검증 시에는 랜덤 증강을 적용하지 않고
    크기 조정과 정규화만 수행합니다.
    (증강 적용 시 재현성 없는 결과 발생)

    Args:
        image_size (int): 출력 이미지 크기 (기본값: 224)

    Returns:
        transform: 검증용 변환 파이프라인 객체
    """
    if HAS_ALBUMENTATIONS:
        return A.Compose([
            A.Resize(image_size, image_size),
            A.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225],
            ),
            ToTensorV2(),
        ])
    else:
        import torchvision.transforms as T
        return T.Compose([
            T.ToPILImage(),
            T.Resize((image_size, image_size)),
            T.ToTensor(),
            T.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225],
            ),
        ])


# ================================================================
# DataLoader Factory
# ================================================================

def create_dataloaders(
    data_dir: str,
    val_split: float = 0.2,
    batch_size: int = 32,
    num_workers: int = 4,
    image_size: int = 224,
    seed: int = 42,
) -> Tuple[DataLoader, DataLoader]:
    """
    단일 데이터 디렉토리에서 학습/검증 DataLoader를 생성합니다.

    전체 데이터셋을 val_split 비율로 자동 분할하며,
    각 분할에 적합한 transform을 적용합니다.

    Args:
        data_dir (str): Open, Closed, yawn, no_yawn 폴더가 있는 루트 경로
        val_split (float): 검증 데이터 비율 (기본값: 0.2 = 20%)
        batch_size (int): 미니배치 크기 (기본값: 32)
        num_workers (int): 데이터 로딩 병렬 워커 수 (기본값: 4)
        image_size (int): 입력 이미지 크기 (기본값: 224)
        seed (int): 분할 재현성을 위한 랜덤 시드 (기본값: 42)

    Returns:
        tuple: (train_loader, val_loader) DataLoader 쌍
    """
    train_transform = get_train_transforms(image_size)
    val_transform = get_val_transforms(image_size)

    # transform 없이 전체 데이터셋 로드 → 분할 후 각각 transform 적용
    full_dataset = DrowsinessDataset(root_dir=data_dir, transform=None)

    # ── Train / Val 분할 ──────────────────────────────────────────
    total = len(full_dataset)
    val_size = int(total * val_split)
    train_size = total - val_size

    # 시드 고정으로 실험 재현성 보장
    generator = torch.Generator().manual_seed(seed)
    train_indices, val_indices = random_split(
        range(total), [train_size, val_size], generator=generator
    )

    # TransformSubset으로 각 분할에 맞는 transform 적용
    train_dataset = TransformSubset(full_dataset, train_indices.indices, train_transform)
    val_dataset = TransformSubset(full_dataset, val_indices.indices, val_transform)

    print(f"\nSplit: {train_size} train / {val_size} val")

    # CUDA 사용 가능 시 pin_memory로 GPU 전송 속도 향상
    pin_memory = torch.cuda.is_available()

    # 학습용: shuffle=True로 배치마다 다른 샘플 순서
    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,       # 매 에폭마다 셔플 → 과적합 방지
        num_workers=num_workers,
        pin_memory=pin_memory,
    )

    # 검증용: shuffle=False로 결과 재현성 보장
    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,      # 검증은 순서 유지
        num_workers=num_workers,
        pin_memory=pin_memory,
    )

    return train_loader, val_loader


class TransformSubset(Dataset):
    """
    데이터셋의 부분 집합(Subset)에 별도의 transform을 적용하는 래퍼입니다.

    PyTorch의 random_split은 transform을 포함한 Dataset을 분할하므로
    train/val에 서로 다른 transform을 적용하려면 이 래퍼가 필요합니다.

    Args:
        dataset (DrowsinessDataset): 원본 전체 데이터셋
        indices (list): 이 subset에 포함될 샘플 인덱스 목록
        transform: 이 subset에만 적용할 transform 파이프라인
    """

    def __init__(self, dataset: DrowsinessDataset, indices: list, transform):
        self.dataset = dataset
        self.indices = indices
        self.transform = transform

    def __len__(self):
        return len(self.indices)

    def __getitem__(self, idx):
        """
        idx → self.indices[idx] → 원본 dataset의 실제 인덱스로 매핑하여
        이미지를 읽고 transform을 적용합니다.
        """
        img_path, label = self.dataset.samples[self.indices[idx]]

        # OpenCV BGR → RGB 변환
        image = cv2.imread(str(img_path))
        if image is None:
            raise RuntimeError(f"Failed to load image: {img_path}")
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        # 이 subset에 지정된 transform 적용
        if self.transform:
            if HAS_ALBUMENTATIONS:
                transformed = self.transform(image=image)
                image = transformed['image']
            else:
                image = self.transform(image)

        return image, label


if __name__ == '__main__':
    # 모듈 로드 확인 및 환경 정보 출력
    print("Dataset module loaded successfully!")
    print(f"Albumentations available: {HAS_ALBUMENTATIONS}")
