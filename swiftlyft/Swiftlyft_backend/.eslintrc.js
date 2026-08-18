module.exports = {
  env: {
    node: true,
    es2021: true,
    jest: true,
  },
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 2021,
    sourceType: 'module',
  },
  rules: {
    'no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
    'no-console': ['warn', { allow: ['warn', 'error'] }],
    'no-trailing-spaces': 'warn',
    'eol-last': 'warn',
    'semi': ['error', 'always'],
    'quotes': ['error', 'single', { avoidEscape: true }],
    'comma-dangle': ['warn', 'always-multiline'],
  },
};

