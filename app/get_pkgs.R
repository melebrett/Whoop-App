# install.packages("renv")

directory_depends <- renv::dependencies(dev=T)[2]$Package
packages <- installed.packages()

packages <- packages[which(rownames(installed.packages()) %in% directory_depends),]
packages[,"Version"]

installs <- c()
for(i in 1:length(packages[,"Version"])){
  
  pkg <- names(packages[,"Version"][i])
  version <- packages[,"Version"][[i]]

  cmd <- paste(
    "RUN R -e \"remotes::install_version('",
    pkg,
    "', version = '",
    version,
    "')\"",
    sep = ""
  )
  
  installs <- append(installs,cmd)
  
}

file <- file("install_pkgs.txt")
writeLines(installs,file)
close(file)
