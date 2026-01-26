"""
FocusSense Model Training Script

Usage:
    python train.py --data_dir ./data --epochs 50 --batch_size 32
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
from training.dataset import create_dataloaders, get_train_transforms, get_val_transforms


class MultiTaskLoss(nn.Module):
    """
    멀티태스크 학습용 손실 함수
    
    각 태스크의 CrossEntropy Loss를 가중 합산
    """
    
    def __init__(
        self,
        drowsiness_weight: float = 1.0,
        gaze_weight: float = 1.0,
        face_weight: float = 0.5,
    ):
        super().__init__()
        self.drowsiness_weight = drowsiness_weight
        self.gaze_weight = gaze_weight
        self.face_weight = face_weight
        
        self.criterion = nn.CrossEntropyLoss()
        
    def forward(
        self,
        outputs: Dict[str, torch.Tensor],
        targets: Dict[str, torch.Tensor],
    ) -> Dict[str, torch.Tensor]:
        """
        Args:
            outputs: Model outputs {'drowsiness': ..., 'gaze': ..., 'face': ...}
            targets: Target labels with same keys
            
        Returns:
            Dictionary with individual losses and total loss
        """
        losses = {}
        
        if 'drowsiness' in targets:
            losses['drowsiness'] = self.criterion(outputs['drowsiness'], targets['drowsiness'])
        
        if 'gaze' in targets:
            losses['gaze'] = self.criterion(outputs['gaze'], targets['gaze'])
            
        if 'face' in targets:
            losses['face'] = self.criterion(outputs['face'], targets['face'])
        
        # Weighted sum
        total_loss = (
            self.drowsiness_weight * losses.get('drowsiness', 0) +
            self.gaze_weight * losses.get('gaze', 0) +
            self.face_weight * losses.get('face', 0)
        )
        
        losses['total'] = total_loss
        
        return losses


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
        task: str = 'drowsiness',  # 'drowsiness', 'gaze', 'multitask'
    ):
        self.model = model
        self.train_loader = train_loader
        self.val_loader = val_loader
        self.optimizer = optimizer
        self.scheduler = scheduler
        self.criterion = criterion
        self.device = device
        self.save_dir = Path(save_dir)
        self.task = task
        
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
            
            # 태스크에 따라 레이블 처리
            if self.task == 'multitask':
                targets = {k: v.to(self.device) for k, v in labels.items()}
            else:
                targets = {self.task: labels.to(self.device)}
            
            # Forward
            self.optimizer.zero_grad()
            outputs = self.model(images)
            
            # Loss 계산
            if isinstance(self.criterion, MultiTaskLoss):
                losses = self.criterion(outputs, targets)
                loss = losses['total']
            else:
                loss = self.criterion(outputs[self.task], targets[self.task])
            
            # Backward
            loss.backward()
            self.optimizer.step()
            
            # Metrics
            total_loss += loss.item()
            
            # Accuracy (main task)
            main_output = outputs[self.task]
            main_target = targets[self.task]
            _, predicted = main_output.max(1)
            total += main_target.size(0)
            correct += predicted.eq(main_target).sum().item()
            
            # Update progress bar
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
            
            if self.task == 'multitask':
                targets = {k: v.to(self.device) for k, v in labels.items()}
            else:
                targets = {self.task: labels.to(self.device)}
            
            outputs = self.model(images)
            
            if isinstance(self.criterion, MultiTaskLoss):
                losses = self.criterion(outputs, targets)
                loss = losses['total']
            else:
                loss = self.criterion(outputs[self.task], targets[self.task])
            
            total_loss += loss.item()
            
            main_output = outputs[self.task]
            main_target = targets[self.task]
            _, predicted = main_output.max(1)
            total += main_target.size(0)
            correct += predicted.eq(main_target).sum().item()
            
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
        print(f"Task: {self.task}")
        print(f"Device: {self.device}")
        print(f"Save dir: {self.save_dir}")
        print(f"{'='*60}\n")
        
        for epoch in range(1, epochs + 1):
            # Train
            train_metrics = self.train_epoch(epoch)
            
            # Validate
            val_metrics = self.validate(epoch)
            
            # Scheduler step
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
            
            # Print summary
            print(f"\nEpoch {epoch}/{epochs}")
            print(f"  Train - Loss: {train_metrics['loss']:.4f}, Acc: {train_metrics['accuracy']:.2f}%")
            print(f"  Val   - Loss: {val_metrics['loss']:.4f}, Acc: {val_metrics['accuracy']:.2f}%")
            
            # Save best model
            if val_metrics['accuracy'] > self.best_val_acc:
                self.best_val_acc = val_metrics['accuracy']
                self.best_epoch = epoch
                self.save_checkpoint(epoch, is_best=True)
                print(f"  ✓ New best model! Acc: {self.best_val_acc:.2f}%")
            
            # Save periodic checkpoint
            if epoch % 10 == 0:
                self.save_checkpoint(epoch)
        
        # Final summary
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
            'task': self.task,
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
    parser.add_argument('--train_dir', type=str, required=True,
                        help='Training data directory')
    parser.add_argument('--val_dir', type=str, required=True,
                        help='Validation data directory')
    parser.add_argument('--task', type=str, default='drowsiness',
                        choices=['drowsiness', 'gaze', 'multitask'],
                        help='Task to train')
    
    # Model
    parser.add_argument('--model', type=str, default='default',
                        choices=['default', 'lite'],
                        help='Model architecture')
    parser.add_argument('--pretrained', action='store_true',
                        help='Use pretrained weights')
    
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
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")
    
    # DataLoaders
    train_loader, val_loader = create_dataloaders(
        train_dir=args.train_dir,
        val_dir=args.val_dir,
        dataset_type=args.task if args.task != 'multitask' else 'drowsiness',
        batch_size=args.batch_size,
        num_workers=args.num_workers,
    )
    
    # Model
    model = create_model(args.model, pretrained=args.pretrained)
    model = model.to(device)
    
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
    if args.task == 'multitask':
        criterion = MultiTaskLoss()
    else:
        criterion = nn.CrossEntropyLoss()
    
    # Save directory with timestamp
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    save_dir = Path(args.save_dir) / f'{args.task}_{args.model}_{timestamp}'
    
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
        task=args.task,
    )
    
    # Train!
    trainer.train(args.epochs)


if __name__ == '__main__':
    main()
