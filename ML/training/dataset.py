"""
FocusSense Dataset Loader

Kaggle Drowsiness Dataset 활용:
- Open / Closed (눈 상태)
- yawn / no_yawn (하품 여부)

이진 분류로 매핑:
- awake: Open + no_yawn
- drowsy: Closed + yawn
"""

import os
from pathlib import Path
from typing import Tuple, List, Optional, Any

import torch
from torch.utils.data import Dataset, DataLoader, random_split
import numpy as np
import cv2

# Albumentations for augmentation
try:
    import albumentations as A
    from albumentations.pytorch import ToTensorV2
    HAS_ALBUMENTATIONS = True
except ImportError:
    HAS_ALBUMENTATIONS = False
    print("Warning: albumentations not installed. Using basic transforms.")


# Kaggle 데이터셋 폴더 -> 이진 레이블 매핑
KAGGLE_CLASS_MAP = {
    'Open': 0,      # awake
    'Closed': 1,    # drowsy
    'no_yawn': 0,   # awake
    'yawn': 1,      # drowsy
}

IDX_TO_CLASS = {0: 'awake', 1: 'drowsy'}


class DrowsinessDataset(Dataset):
    """
    졸음 감지 데이터셋

    Kaggle Drowsiness Dataset 구조:
    data/drowsiness_kaggle/train/
    ├── Open/        -> awake (0)
    ├── Closed/      -> drowsy (1)
    ├── no_yawn/     -> awake (0)
    └── yawn/        -> drowsy (1)
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

        self.samples: List[Tuple[Path, int]] = []
        self._load_samples()

    def _load_samples(self):
        """샘플 경로 및 레이블 로딩"""
        for folder_name, label in self.class_map.items():
            folder_dir = self.root_dir / folder_name
            if not folder_dir.exists():
                print(f"Warning: {folder_dir} not found, skipping")
                continue

            for ext in ('*.[jJ][pP][gG]', '*.[pP][nN][gG]', '*.[jJ][pP][eE][gG]'):
                for img_path in folder_dir.glob(ext):
                    self.samples.append((img_path, label))

        # 클래스별 개수 출력
        counts = {}
        for _, label in self.samples:
            name = self.idx_to_class[label]
            counts[name] = counts.get(name, 0) + 1

        print(f"Loaded {len(self.samples)} samples from {self.root_dir}")
        for name, count in sorted(counts.items()):
            print(f"  - {name}: {count}")

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, int]:
        img_path, label = self.samples[idx]

        image = cv2.imread(str(img_path))
        if image is None:
            raise RuntimeError(f"Failed to load image: {img_path}")
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        if self.transform:
            if HAS_ALBUMENTATIONS:
                transformed = self.transform(image=image)
                image = transformed['image']
            else:
                image = self.transform(image)

        return image, label


# ============================================================
# Transforms / Augmentations
# ============================================================

def get_train_transforms(image_size: int = 224):
    """학습용 데이터 증강"""
    if HAS_ALBUMENTATIONS:
        return A.Compose([
            A.Resize(image_size, image_size),
            A.HorizontalFlip(p=0.5),
            A.RandomBrightnessContrast(p=0.3),
            A.GaussNoise(p=0.2),
            A.GaussianBlur(blur_limit=3, p=0.1),
            A.Rotate(limit=15, p=0.3),
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
            T.RandomHorizontalFlip(),
            T.ToTensor(),
            T.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225],
            ),
        ])


def get_val_transforms(image_size: int = 224):
    """검증용 Transform (증강 없음)"""
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


# ============================================================
# DataLoader Factory
# ============================================================

def create_dataloaders(
    data_dir: str,
    val_split: float = 0.2,
    batch_size: int = 32,
    num_workers: int = 4,
    image_size: int = 224,
    seed: int = 42,
) -> Tuple[DataLoader, DataLoader]:
    """
    DataLoader 생성 (단일 디렉토리에서 train/val 자동 분할)

    Args:
        data_dir: 데이터 디렉토리 (Open, Closed, yawn, no_yawn 폴더 포함)
        val_split: 검증 데이터 비율
        batch_size: 배치 사이즈
        num_workers: 데이터 로딩 워커 수
        image_size: 이미지 크기
        seed: 랜덤 시드 (재현성)

    Returns:
        (train_loader, val_loader)
    """
    train_transform = get_train_transforms(image_size)
    val_transform = get_val_transforms(image_size)

    # 전체 데이터셋 로드 (transform 없이 - 분할 후 적용)
    full_dataset = DrowsinessDataset(root_dir=data_dir, transform=None)

    # Train/Val 분할
    total = len(full_dataset)
    val_size = int(total * val_split)
    train_size = total - val_size

    generator = torch.Generator().manual_seed(seed)
    train_indices, val_indices = random_split(
        range(total), [train_size, val_size], generator=generator
    )

    # Transform을 적용하는 래퍼 데이터셋
    train_dataset = TransformSubset(full_dataset, train_indices.indices, train_transform)
    val_dataset = TransformSubset(full_dataset, val_indices.indices, val_transform)

    print(f"\nSplit: {train_size} train / {val_size} val")

    pin_memory = torch.cuda.is_available()

    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=pin_memory,
    )

    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=pin_memory,
    )

    return train_loader, val_loader


class TransformSubset(Dataset):
    """Subset에 별도의 transform을 적용하는 래퍼"""

    def __init__(self, dataset: DrowsinessDataset, indices: list, transform):
        self.dataset = dataset
        self.indices = indices
        self.transform = transform

    def __len__(self):
        return len(self.indices)

    def __getitem__(self, idx):
        img_path, label = self.dataset.samples[self.indices[idx]]

        image = cv2.imread(str(img_path))
        if image is None:
            raise RuntimeError(f"Failed to load image: {img_path}")
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        if self.transform:
            if HAS_ALBUMENTATIONS:
                transformed = self.transform(image=image)
                image = transformed['image']
            else:
                image = self.transform(image)

        return image, label


if __name__ == '__main__':
    print("Dataset module loaded successfully!")
    print(f"Albumentations available: {HAS_ALBUMENTATIONS}")
