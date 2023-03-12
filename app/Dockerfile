# Dockerfile
FROM rocker/shiny:4.2.0 

# install the system requirements
RUN apt-get update -qq && apt-get install -y \ 
   libssl-dev \ 
   libcurl4-gnutls-dev \
   libsodium-dev \
   libgit2-dev \
   libv8-dev \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

COPY ./renv.lock ./renv.lock

# install packages
RUN R -e "install.packages(c('renv'))"
RUN R -e "renv::restore()"

# copy everything from the current directory into the container 
COPY . ./app

# open port to traffic
EXPOSE 3838

# run app on container start
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]