FROM rocker/r-ver:4.5.2

# Install system dependencies
RUN apt-get update && apt-get install -y 
    libcurl4-openssl-dev 
    libssl-dev 
    libxml2-dev

# Install renv
RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"

# Copy lockfile
COPY renv.lock renv.lock

# Restore dependencies
RUN R -e "renv::restore()"

# Copy package source
COPY . /app
WORKDIR /app

# Install SYNTHESIS
RUN R -e "devtools::install('.')"

# Expose API port
EXPOSE 8000

# Run API
CMD ["R", "-e", "pr <- plumber::plumb('R/plumber.R'); pr$run(host='0.0.0.0', port=8000)"]
