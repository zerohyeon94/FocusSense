"""
FocusSense Model Training Script

Usage:
    python training/train.py --data_dir ./data/drowsiness_kaggle/train --epochs 50
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
from tqdm import tqdm

# Add project root to path
sys.path.append(str(Path(__file__).parent.parent))

from models.focus_model import create_model
from training.dataset import create_dataloaders


class Trainer:
    """모델 학습 관리 클래스"""

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

        self.save_dir.mkdir(parents=True, exist_ok=True)

        # TensorBoard
        self.writer = SummaryWriter(log_dir=str(self.save_dir / 'logs'))

        # Best model tracking
        self.best_val_acc = 0.0
        self.best_epoch = 0

    def train_epoch(self, epoch: int) -> Dict[str, float]:
        """1 에폭 학습"""
        self.model.train()

        total_loss = 0.0
        correct = 0
        total = 0

        pbar = tqdm(self.train_loader, desc=f'Epoch {epoch} [Train]')

        for batch_idx, (images, labels) in enumerate(pbar):
            images = images.to(self.device)
            labels = labels.to(self.device)

            # Forward
            self.optimizer.zero_grad()
            outputs = self.model(images)

            # 모델이 dict를 반환하면 drowsiness head 사용
            if isinstance(outputs, dict):
                outputs = outputs['drowsiness']

            loss = self.criterion(outputs, labels)

            # Backward
            loss.backward()
            self.optimizer.step()

            # Metrics
            total_loss += loss.item()
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()

            pbar.set_postfix({
                'loss': f'{loss.item():.4f}',
                'acc': f'{100. * correct / total:.2f}%'
            })

        return {
            'loss': total_loss / len(self.train_loader),
            'accuracy': 100. * correct / total,
        }

    @torch.no_grad()
    def validate(self, epoch: int) -> Dict[str, float]:
        """검증"""
        self.model.eval()

        total_loss = 0.0
        correct = 0
        total = 0

        pbar = tqdm(self.val_loader, desc=f'Epoch {epoch} [Val]')

        for images, labels in pbar:
            images = images.to(self.device)
            labels = labels.to(self.device)

            outputs = self.model(images)

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
        """전체 학습 루프"""
        print(f"\n{'='*60}")
        print(f"Starting training for {epochs} epochs")
        print(f"Device: {self.device}")
        print(f"Save dir: {self.save_dir}")
        print(f"{'='*60}\n")

        for epoch in range(1, epochs + 1):
            train_metrics = self.train_epoch(epoch)
            val_metrics = self.validate(epoch)

            if self.scheduler:
                self.scheduler.step()

            # Logging
            self.writer.add_scalars('Loss', {
                'train': train_metrics['loss'],
                'val': val_metrics['loss'],
            }, epoch)

            self.writer.add_scalars('Accuracy', {
                'train': train_metrics['accuracy'],
                'val': val_metrics['accuracy'],
            }, epoch)

            print(f"\nEpoch {epoch}/{epochs}")
            print(f"  Train - Loss: {train_metrics['loss']:.4f}, Acc: {train_metrics['accuracy']:.2f}%")
            print(f"  Val   - Loss: {val_metrics['loss']:.4f}, Acc: {val_metrics['accuracy']:.2f}%")

            # Save best model
            if val_metrics['accuracy'] > self.best_val_acc:
                self.best_val_acc = val_metrics['accuracy']
                self.best_epoch = epoch
                self.save_checkpoint(epoch, is_best=True)
                print(f"  New best model! Acc: {self.best_val_acc:.2f}%")

            # Save periodic checkpoint
            if epoch % 10 == 0:
                self.save_checkpoint(epoch)

        print(f"\n{'='*60}")
        print(f"Training complete!")
        print(f"Best validation accuracy: {self.best_val_acc:.2f}% (epoch {self.best_epoch})")
        print(f"{'='*60}\n")

        self.writer.close()

    def save_checkpoint(self, epoch: int, is_best: bool = False):
        """체크포인트 저장"""
        checkpoint = {
            'epoch': epoch,
            'model_state_dict': self.model.state_dict(),
            'optimizer_state_dict': self.optimizer.state_dict(),
            'best_val_acc': self.best_val_acc,
        }

        if is_best:
            path = self.save_dir / 'best_model.pth'
        else:
            path = self.save_dir / f'checkpoint_epoch_{epoch}.pth'

        torch.save(checkpoint, path)
        print(f"  Checkpoint saved: {path}")


def main():
    parser = argparse.ArgumentParser(description='FocusSense Model Training')

    # Data
    parser.add_argument('--data_dir', type=str, required=True,
                        help='Data directory (with Open/Closed/yawn/no_yawn folders)')
    parser.add_argument('--val_split', type=float, default=0.2,
                        help='Validation split ratio (default: 0.2)')

    # Model
    parser.add_argument('--model', type=str, default='default',
                        choices=['default', 'lite'],
                        help='Model architecture')
    parser.add_argument('--pretrained', action='store_true', default=True,
                        help='Use pretrained weights (default: True)')

    # Training
    parser.add_argument('--epochs', type=int, default=50)
    parser.add_argument('--batch_size', type=int, default=32)
    parser.add_argument('--lr', type=float, default=1e-4)
    parser.add_argument('--weight_decay', type=float, default=1e-5)
    parser.add_argument('--num_workers', type=int, default=4)

    # Output
    parser.add_argument('--save_dir', type=str, default='./checkpoints')

    args = parser.parse_args()

    # Device
    if torch.backends.mps.is_available():
        device = torch.device('mps')
    elif torch.cuda.is_available():
        device = torch.device('cuda')
    else:
        device = torch.device('cpu')
    print(f"Using device: {device}")

    # DataLoaders
    train_loader, val_loader = create_dataloaders(
        data_dir=args.data_dir,
        val_split=args.val_split,
        batch_size=args.batch_size,
        num_workers=args.num_workers,
    )

    # Model
    model = create_model(args.model, pretrained=args.pretrained)
    model = model.to(device)

    total_params = sum(p.numel() for p in model.parameters())
    print(f"Model: {args.model} ({total_params:,} parameters)")

    # Optimizer
    optimizer = optim.AdamW(
        model.parameters(),
        lr=args.lr,
        weight_decay=args.weight_decay,
    )

    # Scheduler
    scheduler = optim.lr_scheduler.CosineAnnealingLR(
        optimizer,
        T_max=args.epochs,
        eta_min=1e-6,
    )

    # Loss
    criterion = nn.CrossEntropyLoss()

    # Save directory with timestamp
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    save_dir = Path(args.save_dir) / f'drowsiness_{args.model}_{timestamp}'

    # Trainer
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
