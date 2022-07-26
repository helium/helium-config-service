FROM elixir:1.13.4
ENV DEBIAN_FRONTEND noninteractive

RUN apt update
RUN apt-get install -y -q \
        build-essential \
        bison \
        flex \
        git \
        gzip \
        autotools-dev \
        automake \
        libtool \
        pkg-config \
        cmake \
        libsodium-dev \
        iproute2 \
	protobuf-compiler \
	postgresql-client

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup update

WORKDIR /opt/helium_config_service

ADD lib lib
ADD config config
ADD priv priv
ADD test test
ADD mix.exs mix.exs
ADD mix.lock mix.lock
ADD scripts/start.sh start.sh

RUN mix local.hex --force
RUN mix local.rebar --force

RUN mix escript.install --force hex protobuf
ENV PATH "${PATH}:/root/.mix/escripts"

RUN mix deps.get
RUN mix deps.compile

ENV MIX_ENV=prod
RUN mix release

CMD ["/opt/helium_config_service/start.sh"]
