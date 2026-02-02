# Dockerfile
FROM condaforge/miniforge3:latest

# 1. Automatic Architecture Detection
ARG TARGETARCH

# 2. Install System Dependencies
# Note: Ubuntu 24.04's firefox package is a snap stub, so we use Mozilla's PPA
RUN apt-get update && apt-get install -y \
    build-essential gcc git wget curl \
    xvfb libasound2t64 socat \
    software-properties-common \
    && add-apt-repository -y ppa:mozillateam/ppa \
    && echo 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001' > /etc/apt/preferences.d/mozilla-firefox \
    && apt-get update && apt-get install -y firefox \
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
# Pin selenium to 4.9.x which still respects PATH for geckodriver
RUN pip install "selenium>=4.9,<4.10"

# Symlink system Firefox and geckodriver into conda env so Bokeh's export_png can find them
RUN ln -sf /usr/bin/firefox /opt/conda/envs/kcwidrp/bin/firefox && \
    ln -sf /usr/local/bin/geckodriver /opt/conda/envs/kcwidrp/bin/geckodriver

# 6. Runtime Configuration
ENV DISPLAY=:99
WORKDIR /data
COPY run_kcwi.sh /app/run_kcwi.sh
COPY patch_bokeh_session.py /app/patch_bokeh_session.py
RUN chmod +x /app/run_kcwi.sh

# Install the Bokeh session patch as a sitecustomize module so it runs on every Python invocation
RUN cp /app/patch_bokeh_session.py /opt/conda/envs/kcwidrp/lib/python3.12/site-packages/sitecustomize.py

ENTRYPOINT ["/app/run_kcwi.sh"]
CMD ["reduce_kcwi", "--help"]