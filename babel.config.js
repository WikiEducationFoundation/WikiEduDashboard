module.exports = {
  presets: [
    '@babel/preset-react',
    ['@babel/preset-env', {
      modules: false
    }]
  ],
  plugins: [
    '@babel/plugin-proposal-object-rest-spread',
    [
      'babel-plugin-root-import',
      {
        paths: [
          {
            rootPathSuffix: './',
            rootPathPrefix: '~/'
          },
          {
            rootPathSuffix: './app/assets/javascripts/components',
            rootPathPrefix: '@components/'
          },
          {
            rootPathSuffix: './app/assets/javascripts/constants',
            rootPathPrefix: '@constants/'
          }
        ]
      }
    ]
  ],
  env: {
    test: {
      plugins: [
        'istanbul',
        '@babel/plugin-transform-modules-commonjs',
        '@babel/plugin-transform-runtime'
      ],
      ignore: [
        'i18n/*.js'
      ]
    },
    development: {
      plugins: [
        'react-refresh/babel',
      ]
    }
  }
};
