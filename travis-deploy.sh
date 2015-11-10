if [ "${TRAVIS_PULL_REQUEST}" = "false" ]
  then

    openssl aes-256-cbc -K $encrypted_513b9a3c0df8_key -iv $encrypted_513b9a3c0df8_iv -in config/deploy_travis_id_rsa.enc -out config/deploy_travis_id_rsa -d
    chmod 600 config/deploy_travis_id_rsa
    eval `ssh-agent -s`
    ssh-add config/deploy_travis_id_rsa

    if [ $TRAVIS_BRANCH = "production" ]
      then
        bundle exec cap production deploy skip_gulp=true;
    elif [ $TRAVIS_BRANCH = "staging" ]
      then
        bundle exec cap staging deploy skip_gulp=true;
    fi
fi
