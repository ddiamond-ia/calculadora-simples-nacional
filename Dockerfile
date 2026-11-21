# Calculadora de Tributos - Simples Nacional (Receita Federal) com login
#
# Etapa 1: baixa o código oficial da Receita, gera o banco de dados e compila.
# Etapa 2: imagem final com Java 25 + Caddy (que faz o login e o HTTPS interno).
#
# Para atualizar a versão da calculadora, troque os códigos de commit abaixo
# pelos mais recentes dos repositórios da Receita Federal.
ARG REF_REGIME_REGULAR=f1eebd7ce3157423b1a6aaca7dc1d6c3395452c4
ARG REF_SIMPLES=a926d5a76095ac0295a6612a9a54db7ffead2396

FROM maven:3-eclipse-temurin-25 AS build
ARG REF_REGIME_REGULAR
ARG REF_SIMPLES
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone https://github.com/ReceitaFederal/calculadora-rtc-regime-regular.git regime-regular \
 && git -C regime-regular checkout "$REF_REGIME_REGULAR" \
 && git clone https://github.com/ReceitaFederal/calculadora-rtc-simples-nacional.git simples \
 && git -C simples checkout "$REF_SIMPLES"

# O banco é gerado no projeto do regime regular, que é o que tem o plugin do Flyway configurado.
WORKDIR /build/regime-regular
RUN mkdir -p calculadora/db \
 && mvn -B flyway:migrate -Dflyway.configFiles=./flyway/flyway-pro.conf --errors \
 && test -s calculadora/db/calculadora-pro.db

# Compila a calculadora do Simples Nacional (os testes exigem ambiente próprio e ficam de fora).
WORKDIR /build/simples
RUN mvn -B -DskipTests clean package \
 && test -s target/api-simples-nacional.jar

FROM caddy:2 AS caddy

FROM eclipse-temurin:25-jre
COPY --from=caddy /usr/bin/caddy /usr/bin/caddy

WORKDIR /app
COPY --from=build /build/simples/target/api-simples-nacional.jar ./api-simples-nacional.jar
COPY --from=build /build/regime-regular/calculadora/db/calculadora-pro.db ./calculadora/db/calculadora-pro.db

COPY docker/Caddyfile /etc/caddy/Caddyfile
COPY site/ /srv/site/
COPY docker/iniciar.sh /usr/local/bin/iniciar.sh
RUN chmod +x /usr/local/bin/iniciar.sh

# O Render informa a porta pela variável PORT (padrão 10000).
ENV PORT=10000
EXPOSE 10000
CMD ["/usr/local/bin/iniciar.sh"]
