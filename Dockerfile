FROM ruby:3.1.2-slim

WORKDIR /app

# Install tools for development and build dependencies for gems
RUN apt update && \
    apt install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt install -y nodejs git gnupg pandoc dpkg-dev libmysql++-dev && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

# Install gems
COPY . .
RUN bundle config --global frozen 1
RUN bundle install

# Install yarn dependencies
RUN npm install -g yarn
RUN yarn

# Setup configurations
COPY config/application.example.yml ./config/application.yml
COPY config/database.example.yml ./config/database.yml

EXPOSE 3000

ENTRYPOINT ["./docker/entrypoint.sh"]
CMD ["start"]
