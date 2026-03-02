# ---- Base R image (stable, minimal, well-maintained)
FROM rocker/r-ver:4.4.0

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# ---- Install system dependencies needed by common R packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    gnupg \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libcairo2-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# ---- Install Quarto (pinned version)
ARG QUARTO_VERSION=1.8.27

RUN wget https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb \
    && apt-get update \
    && apt-get install -y ./quarto-${QUARTO_VERSION}-linux-amd64.deb \
    && rm quarto-${QUARTO_VERSION}-linux-amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# ---- Configure CRAN to use Posit Public Package Manager (fast Linux binaries)
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"))' >> /usr/local/lib/R/etc/Rprofile.site

# ---- Install renv
RUN R -e "install.packages('renv')"

# ---- Set working directory
WORKDIR /project

# ---- Copy only renv files first (better Docker layer caching)
COPY renv.lock renv.lock

# ---- Restore packages (this layer will cache unless renv.lock changes)
RUN R -e "renv::restore(confirm = FALSE)"

# ---- Now copy the rest of the project
COPY . .

# ---- Default command (GitHub Actions will override if needed)
CMD ["quarto", "render"]