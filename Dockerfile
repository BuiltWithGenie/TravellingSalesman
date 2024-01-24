FROM julia:latest
RUN apt-get update && apt-get install -y vim
RUN useradd --create-home --shell /bin/bash genie
RUN mkdir /home/genie/app
COPY Project.toml /home/genie/app/
WORKDIR /home/genie/app
RUN chown -R genie:genie /home/
USER genie
COPY . /home/genie/app
RUN julia -e "using Pkg; Pkg.activate(\".\"); Pkg.instantiate();Pkg.precompile()"
EXPOSE 8000
EXPOSE 80
ENV JULIA_DEPOT_PATH "/home/genie/.julia"
ENV JULIA_REVISE = "off"
ENV GENIE_ENV "prod"
ENV GENIE_HOST "0.0.0.0"
ENV PORT "8000"
ENV WSPORT "8000"
ENV EARLYBIND "true"
ENTRYPOINT ["julia", "--project", "-e", "using GenieFramework; Genie.loadapp(); up(async=false);"]


