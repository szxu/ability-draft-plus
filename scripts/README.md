# Scripts

Organized utility, build, and development scripts for Ability Draft Plus.

## Directory Structure

```
scripts/
├── build/                    # Build & installation scripts
│   ├── build.sh              # Build distributable packages
│   ├── install.sh            # Install dependencies + native modules
│   ├── clean.sh              # Clean build artifacts
│   ├── prepare-app-config.js # Generate production API config
│   └── fix-tfjs-node-build.js# Fix TensorFlow.js for Electron
├── docker/                   # Docker build environment
│   ├── Dockerfile            # Production build (Linux targets)
│   ├── Dockerfile.dev        # Development environment
│   ├── docker-compose.yml    # Service orchestration
│   └── build-in-docker.sh    # One-command Docker build
├── mapping/                  # Resolution coordinate mapping tools
│   ├── complete_manual_mapper.py  # Interactive coordinate generator
│   ├── mapper_utils.py       # Shared mapping utilities
│   ├── requirements.txt      # Python dependencies
│   ├── setup.bat             # Windows setup helper
│   └── README.md             # Detailed mapping guide
├── test/                     # Testing scripts
│   └── test_ml_recognition.js # ML model accuracy testing
├── generate-mock-data.js     # Generate mock data for testing
└── README.md                 # This file
```

## Quick Reference

### Building

```bash
# Install dependencies
./scripts/build/install.sh

# Build for current platform
./scripts/build/build.sh

# Build for Linux specifically
./scripts/build/build.sh --linux

# Build using Docker (no local deps needed)
./scripts/docker/build-in-docker.sh

# Clean build artifacts
./scripts/build/clean.sh
./scripts/build/clean.sh --all  # Also removes node_modules
```

### Docker

```bash
# Build Linux packages in Docker
docker compose -f scripts/docker/docker-compose.yml run build-linux

# Interactive dev environment
docker compose -f scripts/docker/docker-compose.yml run dev bash
```

### Testing

```bash
# Test ML model with a screenshot
node scripts/test/test_ml_recognition.js screenshot.png coords.json 1920x1080

# Generate mock test data
node scripts/generate-mock-data.js [output-dir]
```

### Mapping New Resolutions

```bash
# Install Python dependencies
pip install -r scripts/mapping/requirements.txt

# Generate coordinates from screenshot
python scripts/mapping/complete_manual_mapper.py --screenshot screenshot.png --output coords.json

# Verify with ML model
node scripts/test/test_ml_recognition.js screenshot.png coords.json 1920x1200
```
