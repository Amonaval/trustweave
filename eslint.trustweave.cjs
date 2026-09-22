/**
 * TrustWeave independent static-analysis profile.
 *
 * The profile has two purposes:
 * 1) correctness failures that should block a patch/build;
 * 2) legacy/type-design debt that should remain visible without blocking day-to-day stabilization.
 *
 * Install once: npm run lint:trustweave:setup
 * Run:          npm run lint:trustweave
 */
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: './tsconfig.static.json',
    tsconfigRootDir: __dirname,
    sourceType: 'module',
    ecmaVersion: 2022,
    ecmaFeatures: { jsx: true },
  },
  plugins: ['@typescript-eslint', 'react-hooks', '@next/next'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended-type-checked',
    'plugin:react-hooks/recommended',
    'plugin:@next/next/recommended',
  ],
  env: { browser: true, node: true, es2022: true },
  ignorePatterns: [
    '.next/**','node_modules/**','archive/**','qa/**','scripts/**','*.config.*',
    '16-phase2-representative-capabilities.spec.ts',
  ],
  rules: {
    // Build/runtime correctness: these remain blocking errors.
    'no-unreachable': 'error',
    'no-constant-condition': ['error', {checkLoops: false}],
    'no-dupe-keys': 'error',
    'no-import-assign': 'error',
    '@typescript-eslint/await-thenable': 'error',
    '@typescript-eslint/no-misused-promises': ['error', {checksVoidReturn: false}],
    '@typescript-eslint/no-unused-expressions': 'error',

    // Existing-code debt discovered by the first full scan. Keep it visible, but
    // do not treat it as a release blocker while stabilization is in progress.
    '@typescript-eslint/no-confusing-void-expression': ['warn', {ignoreArrowShorthand: true}],
    '@typescript-eslint/no-unnecessary-type-assertion': 'warn',
    '@typescript-eslint/no-base-to-string': 'warn',
    '@typescript-eslint/no-redundant-type-constituents': 'warn',
    '@typescript-eslint/no-unnecessary-condition': 'warn',
    '@typescript-eslint/no-floating-promises': 'warn',
    '@typescript-eslint/require-await': 'warn',
    '@typescript-eslint/no-unused-vars': ['warn', {argsIgnorePattern: '^_', varsIgnorePattern: '^_'}],
    'react-hooks/exhaustive-deps': 'warn',
    'prefer-const': 'warn',
    'no-empty': ['warn', {allowEmptyCatch: true}],
    'no-useless-escape': 'warn',
    'no-extra-semi': 'warn',

    // Existing adapters intentionally use these patterns today.
    '@typescript-eslint/no-explicit-any': 'off',
    '@typescript-eslint/no-non-null-assertion': 'off',
    '@typescript-eslint/no-unsafe-assignment': 'off',
    '@typescript-eslint/no-unsafe-argument': 'off',
    '@typescript-eslint/no-unsafe-member-access': 'off',
    '@typescript-eslint/no-unsafe-call': 'off',
    '@typescript-eslint/no-unsafe-return': 'off',
  },
  overrides: [{
      files: ['**/*.tsx'],
    rules: {'@typescript-eslint/no-misused-promises': ['error', {checksVoidReturn: false}]},
  }],
};
