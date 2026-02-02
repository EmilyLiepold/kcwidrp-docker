# Dockerized KCWI Data Reduction Pipeline

A cross-platform Docker container for the [Keck Cosmic Web Imager Data Reduction Pipeline (KCWI DRP)](https://kcwi-drp.readthedocs.io/). Run the pipeline on macOS (Apple Silicon) or Linux without managing local dependencies.

## Quick Start

### Pull the image

```bash
docker pull ghcr.io/emilyliepold/dockerized_kcwi-drp:main
```

### Run a reduction

```bash
docker run --rm -it -p 5006:5006 \
  -v /path/to/your/data:/data \
  ghcr.io/emilyliepold/dockerized_kcwi-drp:main \
  reduce_kcwi -c kcwi.cfg -b -f kb*.fits -g
```

### View live plots

Open **http://localhost:5006/?bokeh-session-id=kcwi** in your browser to see interactive Bokeh plots during reduction.

## Usage Examples

### Interactive shell

```bash
docker run --rm -it -p 5006:5006 \
  -v /path/to/your/data:/data \
  ghcr.io/emilyliepold/dockerized_kcwi-drp:main \
  /bin/bash
```

### Run with custom config

```bash
docker run --rm -it -p 5006:5006 \
  -v /path/to/your/data:/data \
  ghcr.io/emilyliepold/dockerized_kcwi-drp:main \
  reduce_kcwi -c kcwi.cfg -b -f kb*.fits -g
```

### Persist calibration data

Mount `~/.kcwidrp` to cache calibration files between runs:

```bash
docker run --rm -it -p 5006:5006 \
  -v /path/to/your/data:/data \
  -v ~/.kcwidrp:/root/.kcwidrp \
  ghcr.io/emilyliepold/dockerized_kcwi-drp:main \
  reduce_kcwi -b -f kb*.fits -g
```

## Shell Alias (Recommended)

Add this to your `~/.zshrc` or `~/.bashrc`:

```bash
alias kcwi='docker run --rm -it -p 5006:5006 -v "$(pwd)":/data ghcr.io/emilyliepold/dockerized_kcwi-drp:main'
```

Then simply run:

```bash
cd /path/to/your/data
kcwi reduce_kcwi -c kcwi.cfg -b -f kb*.fits -g
```

## Building Locally

```bash
git clone https://github.com/EmilyLiepold/dockerized_KCWI-DRP.git
cd dockerized_KCWI-DRP/kcwi-docker
docker build -t kcwi-drp .
```

For multi-architecture builds (ARM64 + AMD64):

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t kcwi-drp .
```

## Features

- **Cross-platform**: Supports both Apple Silicon (ARM64) and Intel/AMD (AMD64)
- **Live plotting**: View Bokeh plots in your browser at `localhost:5006`
- **Headless operation**: Xvfb provides a virtual display for Firefox/Selenium
- **Transparent wrapper**: Pass any command directly to the container

## Technical Details

- **Base image**: `condaforge/miniforge3:latest`
- **Python**: 3.12 (as recommended by KCWI DRP docs)
- **Browser**: Firefox (from Mozilla PPA) + geckodriver
- **Display**: Xvfb virtual framebuffer on `:99`

## Troubleshooting

### Plots not visible in browser

Make sure you're visiting `http://localhost:5006/?bokeh-session-id=kcwi` (note the session ID parameter).

### Port 5006 already in use

Either stop the other service using port 5006, or map to a different port:

```bash
docker run --rm -it -p 5007:5006 -v "$(pwd)":/data kcwi-drp ...
# Then visit http://localhost:5007/?bokeh-session-id=kcwi
```

### Token expired error on browser reload

This shouldn't happen with the current configuration (24-hour token expiration), but if it does, simply restart the container.

## License

This Docker configuration is provided as-is. The KCWI DRP itself is developed by the KCWI Team at Keck Observatory.

## Links

- [KCWI DRP Documentation](https://kcwi-drp.readthedocs.io/)
- [KCWI DRP GitHub](https://github.com/Keck-DataReductionPipelines/KCWI_DRP)
