import globals from 'globals';

export default [
  { ignores: ['www/**', 'android/**', 'node_modules/**', 'models-cache/**'] },
  {
    files: ['src/**/*.js'],
    languageOptions: { ecmaVersion: 2024, sourceType: 'module', globals: globals.browser },
    rules: { 'no-unused-vars': 'warn', 'no-undef': 'error' },
  },
  {
    files: ['scripts/**/*.mjs', 'test/**/*.js', 'eslint.config.mjs'],
    languageOptions: { ecmaVersion: 2024, sourceType: 'module', globals: globals.node },
    rules: { 'no-unused-vars': 'warn', 'no-undef': 'error' },
  },
];
