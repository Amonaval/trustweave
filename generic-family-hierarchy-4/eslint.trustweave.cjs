/**
 * TrustWeave independent static-analysis profile.
 *
 * This intentionally does not use `next lint` or the project's historical QA setup.
 * Install the lint runtime once with: npm run lint:trustweave:setup
 * Then run: npm run lint:trustweave
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
    '.next/**',
    'node_modules/**',
    'archive/**',
    'qa/**',
    'scripts/**',
    '*.config.*',
    '16-phase2-representative-capabilities.spec.ts',
  ],
  rules: {
    // High-signal correctness rules: fail fast.
    'no-unreachable': 'error',
    'no-constant-condition': ['error', {checkLoops: false}],
    'no-dupe-keys': 'error',
    'no-import-assign': 'error',
    '@typescript-eslint/await-thenable': 'error',
    '@typescript-eslint/no-misused-promises': ['error', {checksVoidReturn: false}],
    '@typescript-eslint/no-confusing-void-expression': ['error', {ignoreArrowShorthand: true}],
    '@typescript-eslint/no-unnecessary-type-assertion': 'error',

    // Useful debt signals. Report them without making the first adoption unusable.
    '@typescript-eslint/no-unnecessary-condition': 'warn',
    '@typescript-eslint/no-floating-promises': 'warn',
    '@typescript-eslint/require-await': 'warn',
    '@typescript-eslint/no-unused-vars': ['warn', {argsIgnorePattern: '^_', varsIgnorePattern: '^_'}],
    'react-hooks/exhaustive-deps': 'warn',

    // Existing code intentionally uses `any` and non-null assertions in several adapters.
    // Track separately; do not drown the correctness report today.
    '@typescript-eslint/no-explicit-any': 'off',
    '@typescript-eslint/no-non-null-assertion': 'off',
    '@typescript-eslint/no-unsafe-assignment': 'off',
    '@typescript-eslint/no-unsafe-argument': 'off',
    '@typescript-eslint/no-unsafe-member-access': 'off',
    '@typescript-eslint/no-unsafe-call': 'off',
    '@typescript-eslint/no-unsafe-return': 'off',
  },
  overrides: [
    {
      files: ['**/*.tsx'],
      rules: {
        // Async JSX handlers are normal in this codebase.
        '@typescript-eslint/no-misused-promises': ['error', {checksVoidReturn: false}],
      },
    },
  ],
};
