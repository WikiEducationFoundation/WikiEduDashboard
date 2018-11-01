# Dockerfile
#
# Build and Run:
#   - docker build -t wiki-edu-dashboard .
#   - docker run -p 3000:3000 -it wiki-edu-dashboard

FROM ruby:2.5.0

WORKDIR /usr/src/app

# Setup repos
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Install deps
RUN apt update
RUN apt install -y nodejs r-base gnupg yarn pandoc redis-server mariadb-server libmariadbclient-dev

# Install gems
RUN bundle config --global frozen 1
COPY Gemfile Gemfile.lock ./
RUN bundle install

# App setup and configurations
RUN yarn global add phantomjs-prebuilt
COPY . .
COPY config/application.example.yml ./config/application.yml
COPY config/database.example.yml ./config/database.yml
COPY entrypoint.sh ./entrypoint.sh
COPY db_init.sh ./db_init.sh
RUN yarn && yarn global add gulp

# Setup and initialize DBs
RUN ./db_init.sh

EXPOSE 3000

# Setup and run
CMD './entrypoint.sh'
