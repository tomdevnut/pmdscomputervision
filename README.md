# Computer Vision Project

## Project Structure

```
pmdscomputervision/
├── data/               # Data storage
│   ├── raw/           # Original data
│   └── processed/     # Processed data
├── notebooks/         # Jupyter notebooks for analysis
├── src/              # Source code
│   ├── data/         # Data processing scripts
│   ├── models/       # Computer vision model implementations
│   └── utils/        # Utility functions
└── tests/            # Test files
```

## Setup

1. Create and activate virtual environment:
```bash
python -m venv venv
# On Windows
venv\Scripts\activate
# On Unix/MacOS
source venv/bin/activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

## Project Dependencies

- numpy: Numerical computing
- pandas: Data manipulation and analysis
- jupyter: Notebook interface
- opencv-python: Computer vision library
- Pillow: Image processing
- matplotlib: Data visualization
- scikit-learn: Machine learning utilities
