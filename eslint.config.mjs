import js from '@eslint/js';
import reactPlugin from 'eslint-plugin-react';
import jsxA11yPlugin from 'eslint-plugin-jsx-a11y';
import importPlugin from 'eslint-plugin-import';
import i18nextPlugin from 'eslint-plugin-i18next';
import globals from 'globals';

export default [
  {
    ignores: ['public/**', 'coverage/**', 'tmp/**', 'i18n/**'],
  },

  js.configs.recommended,
  reactPlugin.configs.flat.recommended,
  jsxA11yPlugin.flatConfigs.recommended,
  importPlugin.flatConfigs.recommended,
  i18nextPlugin.configs['flat/recommended'],

  {
    files: ['**/*.{js,jsx,mjs,cjs}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      parserOptions: {
        ecmaFeatures: { jsx: true },
      },
      globals: {
        ...globals.browser,
        ...globals.jquery,
        require: 'readonly',
        I18n: 'readonly',
        _: 'readonly',
        Sentry: 'readonly',
        SurveyDetails: 'readonly',
        Features: 'readonly',
        WikiLanguages: 'readonly',
        WikiProjects: 'readonly',
        ProjectNamespaces: 'readonly',
        flatpickr: 'readonly',
        TomSelect: 'readonly',
        locale: 'readonly',
        flatpickrLocales: 'readonly',
      },
    },
    settings: {
      react: { version: 'detect' },
      'import/resolver': {
        alias: {
          map: [
            ['~', '.'],
            ['@components', './app/assets/javascripts/components'],
            ['@constants', './app/assets/javascripts/constants'],
            ['@actions', './app/assets/javascripts/actions'],
          ],
          extensions: ['.js', '.jsx', '.json'],
        },
        node: {
          extensions: ['.js', '.jsx', '.json'],
          moduleDirectory: ['node_modules', 'app/assets/javascripts'],
        },
      },
    },
  },

  {
    files: ['test/**/*.{js,jsx}', '**/*.spec.{js,jsx}'],
    languageOptions: {
      globals: {
        ...globals.jest,
        ...globals.node,
        sinon: 'readonly',
        reduxStore: 'readonly',
      },
    },
  },

  {
    files: ['*.js', '*.cjs'],
    languageOptions: {
      sourceType: 'commonjs',
      globals: { ...globals.node },
    },
  },

  {
    rules: {
      radix: ['error', 'as-needed'],
      'new-cap': ['error', { capIsNew: false }],
      'no-else-return': ['error', { allowElseIf: true }],
      'no-trailing-spaces': 'error',
      'no-unused-vars': ['error', { argsIgnorePattern: '^_', ignoreRestSiblings: true, caughtErrors: 'none' }],
      'react/jsx-equals-spacing': ['error', 'never'],
      'i18next/no-literal-string': ['warn', { message: 'Use I18n over string literals for localization' }],

      'no-empty-pattern': 'off',
      'no-prototype-builtins': 'off',
      'react/display-name': 'off',
      'react/no-string-refs': 'off',
      'react/jsx-no-target-blank': 'off',
      'react/no-find-dom-node': 'off',
      'react/prop-types': 'off',
      'jsx-a11y/no-static-element-interactions': 'off',
      'jsx-a11y/aria-role': 'off',
      'jsx-a11y/anchor-has-content': 'off',
      'jsx-a11y/no-autofocus': 'off',
      'jsx-a11y/anchor-is-valid': 'off',
      'jsx-a11y/click-events-have-key-events': 'off',
      'jsx-a11y/no-noninteractive-element-interactions': 'off',
      'jsx-a11y/label-has-associated-control': 'off',
      'import/no-named-as-default': 'off',
      'import/namespace': 'off',
    },
  },
];
