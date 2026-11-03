"""
FocusSense Model Training Script

졸음 감지 모델(FocusSenseModel / FocusSenseLite)을 학습시키는 메인 스크립트입니다.

학습 파이프라인:
    1. 데이터셋 로드 및 train/val 분할
    2. 모델 생성 (default: MobileNetV3 기반 / lite: 경량 커스텀)
    3. AdamW 옵티마이저 + CosineAnnealing 스케줄러 설정
    4. CrossEntropyLoss로 이진 분류 학습
    5. 에폭마다 TensorBoard 로그 기록
    6. 최고 성능 모델 자동 저장

Usage:
    python training/train.py --data_dir ./data/drowsiness_kaggle/train --epochs 50

TensorBoard 확인:
    tensorboard --logdir ./checkpoints
"""

import os
import sys
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, Any

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torch.utils.tensorboard import SummaryWriter
from tqdm import tqdm  # 진행률 표시 바

# 프로젝트 루트를 sys.path에 추가 (상대 import 허용)
sys.path.append(str(Path(__file__).parent.parent))

from models.focus_model import create_model
from training.dataset import create_dataloaders


class Trainer:
    """
    모델 학습 전체 과정을 관리하는 클래스입니다.

    학습(train) / 검증(validate) 루프, TensorBoard 로깅,
    체크포인트 저장, 최적 모델 추적을 담당합니다.

    Args:
        model (nn.Module): 학습할 PyTorch 모델
        train_loader (DataLoader): 학습 데이터 로더
        val_loader (DataLoader): 검증 데이터 로더
        optimizer (Optimizer): 가중치 업데이트 옵티마이저
        scheduler (_LRScheduler): 학습률 스케줄러
        criterion (nn.Module): 손실 함수
        device (torch.device): 연산 디바이스 (cpu / cuda / mps)
        save_dir (str): 체크포인트 및 TensorBoard 로그 저장 경로
    """

    def __init__(
        self,
        model: nn.Module,
        train_loader: DataLoader,
        val_loader: DataLoader,
        optimizer: optim.Optimizer,
        scheduler: optim.lr_scheduler._LRScheduler,
        criterion: nn.Module,
        device: torch.device,
        save_dir: str,
    ):
        self.model = model
        self.train_loader = train_loader
        self.val_loader = val_loader
        self.optimizer = optimizer
        self.scheduler = scheduler
        self.criterion = criterion
        self.device = device
        self.save_dir = Path(save_dir)

        # 저장 디렉토리 생성 (없으면 자동 생성)
        self.save_dir.mkdir(parents=True, exist_ok=True)

        # TensorBoard 로그 디렉토리 설정
        # → tensorboard --logdir <save_dir>/logs 로 확인
        self.writer = SummaryWriter(log_dir=str(self.save_dir / 'logs'))

        # 최적 모델 추적용 변수
        self.best_val_acc = 0.0   # 지금까지의 최고 검증 정확도
        self.best_epoch = 0        # 최고 정확도 달성 에폭 번호

    def train_epoch(self, epoch: int) -> Dict[str, float]:
        """
        1 에폭(전체 학습 데이터 1회 순회) 학습을 수행합니다.

        Forward → Loss 계산 → Backward → 가중치 업데이트 순으로 진행합니다.
        배치마다 손실과 정확도를 누적하여 에폭 평균을 반환합니다.

        Args:
            epoch (int): 현재 에폭 번호 (1부터 시작)

        Returns:
            dict: {'loss': 평균 손실, 'accuracy': 정확도(%)}
        """
        self.model.train()  # BatchNorm, Dropout 등 학습 모드 활성화

        total_loss = 0.0
        correct = 0
        total = 0

        # tqdm으로 배치별 진행률 표시
        pbar = tqdm(self.train_loader, desc=f'Epoch {epoch} [Train]')

        for batch_idx, (images, labels) in enumerate(pbar):
            # 지정된 디바이스로 데이터 이동 (CPU → GPU/MPS)
            images = images.to(self.device)
            labels = labels.to(self.device)

            # ── Forward Pass ──────────────────────────────────────
            self.optimizer.zero_grad()  # 이전 배치의 gradient 초기화
            outputs = self.model(images)

            # FocusSenseModel/FocusSenseLite은 dict를 반환
            # → drowsiness head의 logits만 사용 (이진 분류)
            if isinstance(outputs, dict):
                outputs = outputs['drowsiness']

            loss = self.criterion(outputs, labels)

            # ── Backward Pass ─────────────────────────────────────
            loss.backward()       # 손실에 대한 각 파라미터의 gradient 계산
            self.optimizer.step() # gradient 방향으로 파라미터 업데이트

            # ── 메트릭 누적 ───────────────────────────────────────
            total_loss += loss.item()
            _, predicted = outputs.max(1)  # 가장 높은 logit의 클래스 선택
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()

            # 진행바에 실시간 손실/정확도 표시
            pbar.set_postfix({
                'loss': f'{loss.item():.4f}',
                'acc': f'{100. * correct / total:.2f}%'
            })

        return {
            'loss': total_loss / len(self.train_loader),  # 배치 수로 나누어 평균
            'accuracy': 100. * correct / total,
        }

    @torch.no_grad()
    def validate(self, epoch: int) -> Dict[str, float]:
        """
        검증 데이터셋으로 모델 성능을 평가합니다.

        @torch.no_grad() 데코레이터로 gradient 계산을 비활성화하여
        메모리 사용량을 줄이고 추론 속도를 높입니다.

        Args:
            epoch (int): 현재 에폭 번호

        Returns:
            dict: {'loss': 평균 손실, 'accuracy': 정확도(%)}
        """
        self.model.eval()  # BatchNorm, Dropout 등 평가 모드 전환

        total_loss = 0.0
        correct = 0
        total = 0

        pbar = tqdm(self.val_loader, desc=f'Epoch {epoch} [Val]')

        for images, labels in pbar:
            images = images.to(self.device)
            labels = labels.to(self.device)

            outputs = self.model(images)

            # dict 출력 처리 (train_epoch과 동일한 방식)
            if isinstance(outputs, dict):
                outputs = outputs['drowsiness']

            loss = self.criterion(outputs, labels)

            total_loss += loss.item()
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()

            pbar.set_postfix({
                'loss': f'{loss.item():.4f}',
                'acc': f'{100. * correct / total:.2f}%'
            })

        return {
            'loss': total_loss / len(self.val_loader),
            'accuracy': 100. * correct / total,
        }

    def train(self, epochs: int):
        """
        지정된 에폭 수만큼 전체 학습 루프를 실행합니다.

        매 에폭마다:
        1. 학습 수행
        2. 검증 수행
        3. 학습률 스케줄러 업데이트
        4. TensorBoard에 Loss/Accuracy 기록
        5. 최고 성능 시 best_model.pth 저장
        6. 10 에폭마다 주기적 체크포인트 저장

        Args:
            epochs (int): 전체 학습 에폭 수
        """
        print(f"\n{'='*60}")
        print(f"Starting training for {epochs} epochs")
        print(f"Device: {self.device}")
        print(f"Save dir: {self.save_dir}")
        print(f"{'='*60}\n")

        for epoch in range(1, epochs + 1):
            # ── 학습 & 검증 ───────────────────────────────────────
            train_metrics = self.train_epoch(epoch)
            val_metrics = self.validate(epoch)

            # ── 학습률 스케줄러 업데이트 ──────────────────────────
            # CosineAnnealingLR: 코사인 함수로 학습률을 점진적으로 감소
            if self.scheduler:
                self.scheduler.step()

            # ── TensorBoard 로깅 ───────────────────────────────────
            # Loss 그래프: train/val 비교로 과적합 여부 판단
            self.writer.add_scalars('Loss', {
                'train': train_metrics['loss'],
                'val': val_metrics['loss'],
            }, epoch)

            # Accuracy 그래프: 모델 성능 추이 확인
            self.writer.add_scalars('Accuracy', {
                'train': train_metrics['accuracy'],
                'val': val_metrics['accuracy'],
            }, epoch)

            # ── 콘솔 출력 ─────────────────────────────────────────
            print(f"\nEpoch {epoch}/{epochs}")
            print(f"  Train - Loss: {train_metrics['loss']:.4f}, Acc: {train_metrics['accuracy']:.2f}%")
            print(f"  Val   - Loss: {val_metrics['loss']:.4f}, Acc: {val_metrics['accuracy']:.2f}%")

            # ── 최고 성능 모델 저장 ───────────────────────────────
            if val_metrics['accuracy'] > self.best_val_acc:
                self.best_val_acc = val_metrics['accuracy']
                self.best_epoch = epoch
                self.save_checkpoint(epoch, is_best=True)
                print(f"  New best model! Acc: {self.best_val_acc:.2f}%")

            # ── 주기적 체크포인트 저장 (10 에폭마다) ─────────────
            # 학습 중 비정상 종료 시 복구용
            if epoch % 10 == 0:
                self.save_checkpoint(epoch)

        print(f"\n{'='*60}")
        print(f"Training complete!")
        print(f"Best validation accuracy: {self.best_val_acc:.2f}% (epoch {self.best_epoch})")
        print(f"{'='*60}\n")

        self.writer.close()

    def save_checkpoint(self, epoch: int, is_best: bool = False):
        """
        현재 모델 상태를 파일로 저장합니다.

        저장 내용:
            - epoch: 현재 에폭 번호
            - model_state_dict: 모델 가중치
            - optimizer_state_dict: 옵티마이저 상태 (재시작 시 필요)
            - best_val_acc: 지금까지의 최고 검증 정확도

        Args:
            epoch (int): 현재 에폭 번호
            is_best (bool): True면 'best_model.pth'로 저장,
                            False면 'checkpoint_epoch_N.pth'로 저장
        """
        checkpoint = {
            'epoch': epoch,
            'model_state_dict': self.model.state_dict(),
            'optimizer_state_dict': self.optimizer.state_dict(),
            'best_val_acc': self.best_val_acc,
        }

        if is_best:
            # CoreML 변환 시 이 파일을 사용: --checkpoint ./checkpoints/.../best_model.pth
            path = self.save_dir / 'best_model.pth'
        else:
            path = self.save_dir / f'checkpoint_epoch_{epoch}.pth'

        torch.save(checkpoint, path)
        print(f"  Checkpoint saved: {path}")


def main():
    """
    커맨드라인 인자를 파싱하고 학습 파이프라인을 실행합니다.

    디바이스 자동 선택 우선순위:
        1. Apple MPS (M1/M2/M3 Mac GPU) → 가장 빠름
        2. NVIDIA CUDA GPU
        3. CPU (느림, 소규모 실험용)
    """
    parser = argparse.ArgumentParser(description='FocusSense Model Training')

    # ── 데이터 관련 인자 ─────────────────────────────────────────
    parser.add_argument('--data_dir', type=str, required=True,
                        help='Data directory (with Open/Closed/yawn/no_yawn folders)')
    parser.add_argument('--val_split', type=float, default=0.2,
                        help='Validation split ratio (default: 0.2)')

    # ── 모델 관련 인자 ───────────────────────────────────────────
    parser.add_argument('--model', type=str, default='default',
                        choices=['default', 'lite'],
                        help='Model architecture: default(MobileNetV3) or lite(custom lightweight)')
    parser.add_argument('--pretrained', action='store_true', default=True,
                        help='Use ImageNet pretrained weights (default: True)')

    # ── 학습 하이퍼파라미터 ──────────────────────────────────────
    parser.add_argument('--epochs', type=int, default=50,
                        help='Total training epochs (default: 50)')
    parser.add_argument('--batch_size', type=int, default=32,
                        help='Mini-batch size (default: 32)')
    parser.add_argument('--lr', type=float, default=1e-4,
                        help='Initial learning rate for AdamW (default: 1e-4)')
    parser.add_argument('--weight_decay', type=float, default=1e-5,
                        help='L2 regularization strength (default: 1e-5)')
    parser.add_argument('--num_workers', type=int, default=4,
                        help='DataLoader worker processes (default: 4)')

    # ── 출력 관련 인자 ───────────────────────────────────────────
    parser.add_argument('--save_dir', type=str, default='./checkpoints',
                        help='Root directory for saving checkpoints (default: ./checkpoints)')

    args = parser.parse_args()

    # ── 디바이스 자동 선택 ───────────────────────────────────────
    if torch.backends.mps.is_available():
        # Apple Silicon (M1/M2/M3) GPU 사용
        device = torch.device('mps')
    elif torch.cuda.is_available():
        # NVIDIA CUDA GPU 사용
        device = torch.device('cuda')
    else:
        # CPU 폴백 (학습 속도 매우 느림)
        device = torch.device('cpu')
    print(f"Using device: {device}")

    # ── DataLoader 생성 ──────────────────────────────────────────
    train_loader, val_loader = create_dataloaders(
        data_dir=args.data_dir,
        val_split=args.val_split,
        batch_size=args.batch_size,
        num_workers=args.num_workers,
    )

    # ── 모델 생성 및 디바이스 배치 ───────────────────────────────
    model = create_model(args.model, pretrained=args.pretrained)
    model = model.to(device)

    total_params = sum(p.numel() for p in model.parameters())
    print(f"Model: {args.model} ({total_params:,} parameters)")

    # ── 옵티마이저: AdamW ─────────────────────────────────────────
    # AdamW = Adam + 분리된 가중치 감소(Weight Decay)
    # → 일반 Adam보다 정규화 효과가 좋아 과적합 방지에 유리
    optimizer = optim.AdamW(
        model.parameters(),
        lr=args.lr,
        weight_decay=args.weight_decay,
    )

    # ── 학습률 스케줄러: CosineAnnealingLR ───────────────────────
    # 코사인 함수를 따라 학습률을 lr → eta_min으로 점진적 감소
    # 학습 후반에 세밀한 수렴을 유도하여 최종 성능 향상
    scheduler = optim.lr_scheduler.CosineAnnealingLR(
        optimizer,
        T_max=args.epochs,   # 코사인 주기 = 전체 에폭 수
        eta_min=1e-6,         # 최소 학습률 하한값
    )

    # ── 손실 함수: CrossEntropyLoss ───────────────────────────────
    # 이진 분류(awake/drowsy)에 사용
    # 내부적으로 Softmax + NLLLoss를 결합
    criterion = nn.CrossEntropyLoss()

    # ── 저장 경로: 타임스탬프로 실험 구분 ────────────────────────
    # 예: ./checkpoints/drowsiness_default_20260204_163610/
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    save_dir = Path(args.save_dir) / f'drowsiness_{args.model}_{timestamp}'

    # ── Trainer 생성 및 학습 시작 ────────────────────────────────
    trainer = Trainer(
        model=model,
        train_loader=train_loader,
        val_loader=val_loader,
        optimizer=optimizer,
        scheduler=scheduler,
        criterion=criterion,
        device=device,
        save_dir=str(save_dir),
    )

    trainer.train(args.epochs)


if __name__ == '__main__':
    main()
