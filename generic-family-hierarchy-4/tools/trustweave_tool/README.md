# TrustWeave adapter

Everything in this folder is TrustWeave-specific. The reusable engine lives in `tools/react-runtime-toolkit`.

The adapter only does three things:

1. maps `?twdebug=1` / `?twdebug=0` to session enablement;
2. injects the generic React preload only when the TrustWeave debug session is enabled;
3. registers optional Supabase decoding and TrustWeave-specific finding rules.

No TrustWeave knowledge is allowed inside `react-runtime-toolkit`.
