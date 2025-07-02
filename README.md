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

## How to create an SSL certificate for only testing purpouse (not production)
```bash
openssl req -x509 -newkey rsa:4096 -nodes -out ./certificate/cert.pem -keyout ./certificate/key.pem -days 365
````
