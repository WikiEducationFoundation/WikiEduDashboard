# Dockerfile
#
# Build and Run:
#   - docker build -t wiki-edu-dashboard .
#   - docker run --net=host -it wiki-edu-dashboard

FROM ruby:2.5

WORKDIR /usr/src/app

# Setup repos
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
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
COPY config/application.example.yml ./config/application.yml
COPY config/database.example.yml ./config/database.yml
COPY entrypoint.sh ./entrypoint.sh
COPY . .
RUN yarn && yarn global add gulp

EXPOSE 3000

# Setup and run
CMD './entrypoint.sh'

