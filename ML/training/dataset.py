"""
FocusSense Dataset Loader

공개 데이터셋을 활용한 데이터 로딩
- MRL Eye Dataset (졸음 감지)
- Gaze Estimation Dataset
- Face Detection Dataset
"""

import os
from pathlib import Path
from typing import Tuple, List, Optional, Dict, Any

import torch
from torch.utils.data import Dataset, DataLoader
import numpy as np
import cv2
from PIL import Image
import pandas as pd

# Albumentations for augmentation
try:
    import albumentations as A
    from albumentations.pytorch import ToTensorV2
    HAS_ALBUMENTATIONS = True
except ImportError:
    HAS_ALBUMENTATIONS = False
    print("Warning: albumentations not installed. Using basic transforms.")


class DrowsinessDataset(Dataset):
    """
    졸음 감지 데이터셋
    
    Supports:
    - MRL Eye Dataset
    - Custom labeled data
    
    Directory structure:
    data/
    ├── drowsy/
    │   ├── img001.jpg
    │   └── ...
    └── awake/
        ├── img001.jpg
        └── ...
    """
    
    def __init__(
        self,
        root_dir: str,
        transform: Optional[Any] = None,
        is_training: bool = True,
    ):
        self.root_dir = Path(root_dir)
        self.transform = transform
        self.is_training = is_training
        
        # 이미지 경로 및 레이블 수집
        self.samples: List[Tuple[Path, int]] = []
        
        # Class mapping
        self.class_to_idx = {'awake': 0, 'drowsy': 1}
        self.idx_to_class = {v: k for k, v in self.class_to_idx.items()}
        
        self._load_samples()
        
    def _load_samples(self):
        """샘플 경로 및 레이블 로딩"""
        for class_name, class_idx in self.class_to_idx.items():
            class_dir = self.root_dir / class_name
            if not class_dir.exists():
                print(f"Warning: {class_dir} not found")
                continue
                
            for img_path in class_dir.glob('*.[jJ][pP][gG]'):
                self.samples.append((img_path, class_idx))
            for img_path in class_dir.glob('*.[pP][nN][gG]'):
                self.samples.append((img_path, class_idx))
                
        print(f"Loaded {len(self.samples)} samples from {self.root_dir}")
        
    def __len__(self) -> int:
        return len(self.samples)
    
    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, int]:
        img_path, label = self.samples[idx]
        
        # 이미지 로드
        image = cv2.imread(str(img_path))
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # Transform 적용
        if self.transform:
            if HAS_ALBUMENTATIONS:
                transformed = self.transform(image=image)
                image = transformed['image']
            else:
                image = self.transform(image)
        
        return image, label


class GazeDataset(Dataset):
    """
    시선 방향 데이터셋
    
    Directory structure:
    data/
    ├── looking_at_screen/
    └── looking_away/
    """
    
    def __init__(
        self,
        root_dir: str,
        transform: Optional[Any] = None,
        is_training: bool = True,
    ):
        self.root_dir = Path(root_dir)
        self.transform = transform
        self.is_training = is_training
        
        self.samples: List[Tuple[Path, int]] = []
        self.class_to_idx = {'looking_at_screen': 0, 'looking_away': 1}
        self.idx_to_class = {v: k for k, v in self.class_to_idx.items()}
        
        self._load_samples()
        
    def _load_samples(self):
        for class_name, class_idx in self.class_to_idx.items():
            class_dir = self.root_dir / class_name
            if not class_dir.exists():
                continue
                
            for img_path in class_dir.glob('*.[jJ][pP][gG]'):
                self.samples.append((img_path, class_idx))
            for img_path in class_dir.glob('*.[pP][nN][gG]'):
                self.samples.append((img_path, class_idx))
                
        print(f"Loaded {len(self.samples)} gaze samples from {self.root_dir}")
        
    def __len__(self) -> int:
        return len(self.samples)
    
    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, int]:
        img_path, label = self.samples[idx]
        
        image = cv2.imread(str(img_path))
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        if self.transform:
            if HAS_ALBUMENTATIONS:
                transformed = self.transform(image=image)
                image = transformed['image']
            else:
                image = self.transform(image)
        
        return image, label


class MultiTaskDataset(Dataset):
    """
    멀티태스크 학습용 통합 데이터셋
    
    CSV 파일 기반으로 모든 태스크의 레이블을 로드
    
    CSV format:
    image_path, drowsiness, gaze, face_present
    /path/to/img.jpg, 0, 1, 1
    """
    
    def __init__(
        self,
        csv_path: str,
        root_dir: str,
        transform: Optional[Any] = None,
        is_training: bool = True,
    ):
        self.root_dir = Path(root_dir)
        self.transform = transform
        self.is_training = is_training
        
        # CSV 로드
        self.df = pd.read_csv(csv_path)
        print(f"Loaded {len(self.df)} samples from {csv_path}")
        
    def __len__(self) -> int:
        return len(self.df)
    
    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, Dict[str, int]]:
        row = self.df.iloc[idx]
        
        # 이미지 로드
        img_path = self.root_dir / row['image_path']
        image = cv2.imread(str(img_path))
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # Transform 적용
        if self.transform:
            if HAS_ALBUMENTATIONS:
                transformed = self.transform(image=image)
                image = transformed['image']
            else:
                image = self.transform(image)
        
        # 레이블
        labels = {
            'drowsiness': int(row['drowsiness']),
            'gaze': int(row['gaze']),
            'face': int(row['face_present']),
        }
        
        return image, labels


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
        # Basic transform without albumentations
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
    train_dir: str,
    val_dir: str,
    dataset_type: str = 'drowsiness',
    batch_size: int = 32,
    num_workers: int = 4,
    image_size: int = 224,
) -> Tuple[DataLoader, DataLoader]:
    """
    DataLoader 생성
    
    Args:
        train_dir: 학습 데이터 디렉토리
        val_dir: 검증 데이터 디렉토리
        dataset_type: 'drowsiness', 'gaze', 'multitask'
        batch_size: 배치 사이즈
        num_workers: 데이터 로딩 워커 수
        image_size: 이미지 크기
        
    Returns:
        (train_loader, val_loader)
    """
    train_transform = get_train_transforms(image_size)
    val_transform = get_val_transforms(image_size)
    
    dataset_classes = {
        'drowsiness': DrowsinessDataset,
        'gaze': GazeDataset,
    }
    
    DatasetClass = dataset_classes.get(dataset_type)
    if DatasetClass is None:
        raise ValueError(f"Unknown dataset type: {dataset_type}")
    
    train_dataset = DatasetClass(
        root_dir=train_dir,
        transform=train_transform,
        is_training=True,
    )
    
    val_dataset = DatasetClass(
        root_dir=val_dir,
        transform=val_transform,
        is_training=False,
    )
    
    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=True,
    )
    
    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=True,
    )
    
    return train_loader, val_loader


if __name__ == '__main__':
    # 테스트
    print("Dataset module loaded successfully!")
    print(f"Albumentations available: {HAS_ALBUMENTATIONS}")
