FROM node:20

# Set the locale. This affects the encoding of the Postgresql template
# databases.
ENV LANG=C.UTF-8

# Set non-interactive mode for apt-get (avoids timezone prompt)
ENV DEBIAN_FRONTEND=noninteractive

# Style dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    fonts-dejavu-core \
    fonts-hanazono \
    fonts-hanazono ttf-unifont \
    fonts-noto \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-noto-hinted \
    fonts-noto-unhinted \
    gnupg \
    mapnik-utils \
    nodejs \
    npm \
    postgresql-client \
    python \
    ttf-unifont \
    unifont \
    unzip && \
    rm -rf /var/lib/apt/lists/*

# Get Noto Emoji Regular font, despite it being deprecated by Google
RUN wget https://github.com/googlefonts/noto-emoji/blob/9a5261d871451f9b5183c93483cbd68ed916b1e9/fonts/NotoEmoji-Regular.ttf?raw=true --content-disposition -P /usr/share/fonts/

# For some reason this one is missing in the default packages
RUN wget https://github.com/stamen/terrain-classic/blob/master/fonts/unifont-Medium.ttf?raw=true --content-disposition -P /usr/share/fonts/

# Kosmtik with plugins, forcing prefix to /usr because bionic sets
# npm prefix to /usr/local, which breaks the install
RUN npm set prefix /usr && \
    git clone https://github.com/kosmtik/kosmtik.git && \
    cd kosmtik && \
    sed -i 's/"leaflet": *"[^"]*"/"leaflet": "^1.9.4"/' package.json && \
    npm install -g

WORKDIR /usr/lib/node_modules/kosmtik/
RUN kosmtik plugins --install kosmtik-overpass-layer \
                    --install kosmtik-fetch-remote \
                    --install kosmtik-overlay \
                    --install kosmtik-open-in-josm \
                    --install kosmtik-map-compare \
                    --install kosmtik-osm-data-overlay \
                    --install kosmtik-mapnik-reference \
                    --install kosmtik-geojson-overlay \
    && cp /root/.config/kosmtik.yml /tmp/.kosmtik-config.yml

# Closing section
RUN mkdir -p /cyclosm
WORKDIR /cyclosm

# Clean up APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER 1000
COPY scripts/docker-startup.sh /scripts/docker-startup.sh
CMD sh /scripts/docker-startup.sh kosmtik
