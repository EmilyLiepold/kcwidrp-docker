# Dockerfile
FROM condaforge/miniforge3:latest

# 1. Automatic Architecture Detection
ARG TARGETARCH

# 2. Install System Dependencies
# Note: Ubuntu 24.04 uses firefox (snap-less via apt), libasound2t64
RUN apt-get update && apt-get install -y \
    build-essential gcc git wget \
    firefox xvfb libasound2t64 socat \
    && rm -rf /var/lib/apt/lists/*

# 3. Install Geckodriver (Dynamic Architecture)
ARG GECKO_VER=v0.34.0
RUN echo "Fetching Geckodriver for: $TARGETARCH" && \
    if [ "$TARGETARCH" = "amd64" ]; then \
        GECKO_ARCH="linux64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        GECKO_ARCH="linux-aarch64"; \
    else \
        echo "Error: Architecture $TARGETARCH not supported" && exit 1; \
    fi && \
    wget -q "https://github.com/mozilla/geckodriver/releases/download/${GECKO_VER}/geckodriver-${GECKO_VER}-${GECKO_ARCH}.tar.gz" \
    && tar -xzf "geckodriver-${GECKO_VER}-${GECKO_ARCH}.tar.gz" \
    && chmod +x geckodriver \
    && mv geckodriver /usr/local/bin/ \
    && rm "geckodriver-${GECKO_VER}-${GECKO_ARCH}.tar.gz"

# 4. Set up Python Environment (official docs recommend Python 3.12)
RUN conda create -n kcwidrp python=3.12 -y

# 5. Install KCWI Pipeline (following official install instructions)
SHELL ["conda", "run", "-n", "kcwidrp", "/bin/bash", "-c"]
RUN pip install kcwidrp

# 6. Runtime Configuration
ENV DISPLAY=:99
WORKDIR /data
COPY run_kcwi.sh /app/run_kcwi.sh
RUN chmod +x /app/run_kcwi.sh

ENTRYPOINT ["/app/run_kcwi.sh"]
CMD ["reduce_kcwi", "--help"]