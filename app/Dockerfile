# Dockerfile
FROM rocker/shiny:4.2.0 

# install the system requirements
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    git-core \
    curl \
    libssl-dev \
    libcurl4-gnutls-dev \
    libsodium-dev \
    libxml2-dev \
    libicu-dev \
    libpq-dev \
    libcairo2-dev \
    libmariadbd-dev \
    libssh2-1-dev \
    libcurl4-openssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install packages
RUN R -e "install.packages(c('remotes'))"
RUN R -e "require(remotes)"
RUN R -e "remotes::install_version('bigrquery', version = '1.4.1')"
RUN R -e "remotes::install_version('dplyr', version = '1.0.10')"
RUN R -e "remotes::install_version('ggplot2', version = '3.4.0')"
RUN R -e "remotes::install_version('glue', version = '1.6.2')"
RUN R -e "remotes::install_version('gt', version = '0.8.0')"
RUN R -e "remotes::install_version('gtExtras', version = '0.4.5')"
RUN R -e "remotes::install_version('httr', version = '1.4.4')"
RUN R -e "remotes::install_version('IRdisplay', version = '1.1')"
RUN R -e "remotes::install_version('jsonlite', version = '1.8.3')"
RUN R -e "remotes::install_version('paletteer', version = '1.5.0')"
RUN R -e "remotes::install_version('renv', version = '0.16.0')"
RUN R -e "remotes::install_version('shiny', version = '1.7.4')"
RUN R -e "remotes::install_version('shinycssloaders', version = '1.0.0')"
RUN R -e "remotes::install_version('shinyjs', version = '2.1.0')"
RUN R -e "remotes::install_version('shinyWidgets', version = '0.7.6')"
RUN R -e "remotes::install_version('stringr', version = '1.5.0')"
RUN R -e "remotes::install_version('tidyr', version = '1.2.1')"

# copy everything from the current directory into the container 
COPY . ./app

# open port to traffic
EXPOSE 3838

# run app on container start
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]