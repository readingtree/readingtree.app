FROM ocaml/opam:debian-12-ocaml-4.14 AS build
RUN sudo apt-get update -y
RUN sudo apt-get install -y libssl-dev libev-dev libgmp-dev pkg-config libffi-dev libc-bin
WORKDIR /readingtree
COPY . .
RUN opam install . --deps-only
RUN eval $(opam env) && dune build

FROM debian:12
RUN apt-get update
RUN apt-get install -y libssl-dev libev-dev libgmp-dev pkg-config libffi-dev libc-bin
COPY --from=build /readingtree/_build/default/bin/application.exe /application.exe
ENTRYPOINT ["/application.exe"]
