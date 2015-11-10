if [ "${TRAVIS_PULL_REQUEST}" = "false" ]
  then

    openssl aes-256-cbc -K $encrypted_f7a019a5ba96_key -iv $encrypted_f7a019a5ba96_iv -in config/deploy-keys.tar.enc -out config/deploy-keys.tar -d
    tar xvf config/deploy-keys.tar -C config
    chmod 600 config/github_deploy
    chmod 600 config/travis_deploy
    eval `ssh-agent -s`
    ssh-add config/github_deploy
    ssh-add config/travis_deploy

    if [ $TRAVIS_BRANCH = "production" ]
      then
        bundle exec cap production deploy skip_gulp=true;
    elif [ $TRAVIS_BRANCH = "staging" ]
      then
        bundle exec cap staging deploy skip_gulp=true;
    fi
fi
