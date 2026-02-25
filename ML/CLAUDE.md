# ML/CLAUDE.md

Guidance for working on the FocusSense ML pipeline.
Also read the root `CLAUDE.md` for repository-wide conventions.

## Overview

The ML pipeline trains a drowsiness classifier and exports it as a CoreML model
for use in the iOS app. The backbone is **MobileNetV3** (lightweight, mobile-optimized).

## Environment Setup

```bash
cd ML
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

Verify the environment before training:

```bash
python check_env.py
```

## Training

```bash
python training/train.py \
  --train_dir ./data/drowsiness/train \
  --val_dir   ./data/drowsiness/val \
  --epochs    50
```

Checkpoints are saved to `checkpoints/`. TensorBoard logs go to the default
`runs/` directory — run `tensorboard --logdir runs` to monitor training.

## CoreML Conversion

After training, convert the best checkpoint to CoreML format:

```bash
python conversion/convert_to_coreml.py
```

Output: `output/*.mlpackage` — copy this into `iOS/FocusSense/Resources/`.

## Key Files

| File | Role |
|------|------|
| `models/focus_model.py` | PyTorch model architecture (MobileNetV3 backbone) |
| `training/train.py` | Training loop, metrics, checkpoint saving |
| `training/dataset.py` | Dataset loading and augmentation |
| `conversion/convert_to_coreml.py` | PyTorch → CoreML export |
| `data/download_datasets.py` | Download Kaggle drowsiness dataset |
| `check_env.py` | Validate Python environment |

## Model Design

- **Task**: binary drowsiness classification (alert vs. drowsy)
- **Input**: cropped face image (normalized)
- **Output**: drowsy probability in [0.0, 1.0]
- **Integration**: combined with Vision EAR score (30% CoreML, 70% Vision)

## Data

```
data/
├── drowsiness/
│   ├── train/
│   │   ├── alert/
│   │   └── drowsy/
│   └── val/
│       ├── alert/
│       └── drowsy/
└── sample/       ← small subset for quick smoke tests
```

To download the full Kaggle dataset:

```bash
python data/download_datasets.py
```

Requires Kaggle API credentials configured at `~/.kaggle/kaggle.json`.

## Code Style

- Use Python type hints on all function signatures
- Keep training, data, model, and conversion concerns in separate modules
- Do not hard-code paths — use `argparse` or config files
- `requirements.txt` pins exact versions; do not loosen pins without testing

## Dependency Notes

- `numpy` must stay `< 2.0.0` (CoreML tools compatibility)
- `sympy==1.12` is pinned for PyTorch compatibility
- Do not upgrade `coremltools` without testing the full conversion pipeline
