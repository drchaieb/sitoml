# Stage 1: Build
FROM ocaml/opam:debian-12-ocaml-5.2 AS build

# Install system dependencies
sudo apt-get update && sudo apt-get install -y libev-dev libgmp-dev libffi-dev pkg-config liblapacke-dev libopenblas-dev

# Set up project
WORKDIR /home/opam/app
COPY . .

# Install OCaml dependencies
RUN opam install . --deps-only -y

# Build project
RUN opam exec -- dune build

# Stage 2: Runtime
FROM debian:12-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y libev4 libgmp10 libffi8 liblapacke libopenblas0 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binaries
COPY --from=build /home/opam/app/_build/default/bin/main.exe ./api
COPY --from=build /home/opam/app/_build/default/bin/worker/main.exe ./worker

# Copy web assets
COPY --from=build /home/opam/app/web ./web
# Ensure the JS is built (it should be part of 'dune build' if linked, 
# otherwise we need to ensure it's there. 
# We'll explicitly copy it if it was built. 
# 'dune build' builds everything reachable. 'web/main.bc.js' is an executable artifact.)
COPY --from=build /home/opam/app/_build/default/web/main.bc.js ./web/

# Create results directory
RUN mkdir -p /data/results

# Entrypoint script
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
