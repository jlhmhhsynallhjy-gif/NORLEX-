
# Security Checklist - Phase 4 Hardening

## Secrets Scan - Verified

### Scanned Locations
- Flutter source: lib/**/*.dart - NO secrets found (API keys, passwords, tokens)
- Flutter assets: assets/ - NO secrets
- Backend source: src/**/*.py - NO hardcoded secrets, only env var reads via settings
- .env.example - Contains placeholders only, no real keys
- Logs: Structured logs redact api_key, token, authorization, password, secret
- Error messages: NorlexException returns code+message only, no stack traces, no secrets

### Verification Commands (run before commit)
```bash
# Search for potential secrets
grep -r "sk-" lib/ --exclude-dir=.git || echo "No OpenAI keys in Flutter"
grep -r "api_key.*=" lib/ --exclude-dir=.git -i | grep -v "example" || echo "No hardcoded API keys"
grep -r "password.*=" backend/src/ --include="*.py" -i | grep -v "hashed_password" | grep -v "password" | head
grep -r "JWT_SECRET" backend/ --include="*.py" - should only read from settings, not hardcoded
```

### JWT Security Hardening
- Algorithm: HS256 explicitly, not none, validated in decode_token
- Secret: min 32 chars enforced in settings (dev fallback is marked dev-only)
- Access token: 15 min expiry
- Refresh token: 7 days, SHA256 hash stored, rotation, revocation
- No algorithm confusion vulnerability - algorithm fixed in settings.jwt_algorithm

### Password Hashing
- bcrypt via passlib, salt auto-generated, not custom crypto

### CORS
- Origins from env CORS_ORIGINS, strict in prod (not *), credentials True only for allowed origins

### SQL Injection
- SQLAlchemy ORM only, no raw SQL, no string formatting in queries

### Authorization
- get_current_user dependency on all protected routes
- Ownership checks: conversation.user_id == current_user.id enforced at DB query level
- No IDOR via hidden IDs - all checks server-side

### Request Limits
- Max request size: 10MB via settings
- Rate limiting: slowapi 60/min global, 20/min per user chat
- Provider timeout: 60s
- Max tokens per request: 4096

### Error Sanitization
- NorlexException returns {code, message} only
- No stack traces to client
- Logs redact sensitive fields via _sanitize()

## Known Limitations (NOT production-secure yet)
- No HTTPS enforcement in code (relies on reverse proxy)
- No trusted hosts middleware (should add)
- Rate limiting in-memory - needs Redis for multi-instance
- Token counting estimated, not accurate
- No email verification, password reset
- No 2FA
- No audit log persistence (logs to stdout only)
- No intrusion detection
