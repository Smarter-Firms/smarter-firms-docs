# Security Implementation Details

This document outlines the security implementation details for the Smarter Firms authentication system.

## JWT Implementation

### Key Generation and Management

The authentication service uses RSA key pairs for JWT signing:

```javascript
// Key generation example
const { generateKeyPairSync } = require('crypto');
const { writeFileSync } = require('fs');

const { privateKey, publicKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: {
    type: 'spki',
    format: 'pem'
  },
  privateKeyEncoding: {
    type: 'pkcs8',
    format: 'pem'
  }
});

writeFileSync('private.key', privateKey);
writeFileSync('public.key', publicKey);
```

Key management practices:

- RSA key pairs with 2048-bit length
- Key rotation every 30 days
- Version identifier (kid) in JWT header
- Support for multiple active keys during rotation periods
- Keys stored securely in AWS KMS in production

### JWT Claims and Structure

```javascript
// JWT payload structure
const payload = {
  // Registered claims
  iss: 'https://api.smarterfirms.com', // Issuer
  sub: userId,                        // Subject (user ID)
  aud: serviceIdentifiers,            // Audience (array of service IDs)
  exp: Math.floor(Date.now() / 1000) + (60 * 15), // 15 minute expiration
  iat: Math.floor(Date.now() / 1000), // Issued at
  jti: uuidv4(),                      // JWT ID for uniqueness
  
  // Custom claims
  roles: userRoles,                   // User roles array
  type: userType,                     // LAW_FIRM_USER or CONSULTANT
  firm_id: primaryFirmId,             // Primary firm ID for law firm users
  cons_firms: consultantFirmIds,      // Associated firm IDs for consultants
  ver: '1.0'                          // Token version
};

const token = jwt.sign(payload, privateKey, { 
  algorithm: 'RS256',
  header: {
    kid: keyId, // Key ID for identifying the signing key
    typ: 'JWT'
  }
});
```

## PKCE Implementation

PKCE (Proof Key for Code Exchange) implementation for protecting authorization code flow:

```javascript
// Code verifier and challenge generation
const generateCodeVerifier = () => {
  const randomBytes = crypto.randomBytes(32);
  return base64URLEncode(randomBytes);
};

const generateCodeChallenge = (verifier) => {
  const hash = crypto.createHash('sha256').update(verifier).digest();
  return base64URLEncode(hash);
};

// Helper function for base64URL encoding
const base64URLEncode = (buffer) => {
  return buffer.toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
};

// Verifier requirements
const validateVerifier = (verifier) => {
  if (!verifier || verifier.length < 43 || verifier.length > 128) {
    throw new Error('Invalid code verifier length');
  }
  
  // Only accept URL-safe base64 characters
  if (!/^[A-Za-z0-9\-_]+$/.test(verifier)) {
    throw new Error('Invalid code verifier format');
  }
};

// Challenge verification
const verifyCodeChallenge = (storedChallenge, receivedVerifier) => {
  const calculatedChallenge = generateCodeChallenge(receivedVerifier);
  return crypto.timingSafeEqual(
    Buffer.from(calculatedChallenge),
    Buffer.from(storedChallenge)
  );
};
```

Security measures:

- Only S256 method supported (plain method disallowed)
- Code verifier length strictly enforced (43-128 characters)
- Code verifier stored securely and never exposed
- Timing-safe comparison for challenge verification
- State parameter for additional CSRF protection

## Password Hashing with Argon2id

```javascript
// Argon2id configuration
const argon2Options = {
  type: argon2.argon2id,      // Argon2id variant
  memoryCost: 65536,          // 64 MiB
  timeCost: 3,                // 3 iterations
  parallelism: 4,             // 4 parallel threads
  hashLength: 32,             // 32-byte output
  saltLength: 16              // 16-byte salt
};

// Password hashing
const hashPassword = async (password) => {
  return await argon2.hash(password, argon2Options);
};

// Password verification
const verifyPassword = async (hash, password) => {
  return await argon2.verify(hash, password, argon2Options);
};
```

Security considerations:

- Argon2id chosen for best resistance against both side-channel and GPU attacks
- Parameters calibrated for ~250ms hashing time on server hardware
- Automatic salt generation with high entropy
- Passwords never stored in plaintext at any point

## IP Binding and Subnet Matching

The system implements IP binding for refresh tokens with subnet matching for better user experience:

```javascript
// Storing IP with refresh token
const storeRefreshToken = async (userId, tokenId, ip) => {
  await redis.hset(`refresh:${tokenId}`, {
    userId,
    ip,
    family: uuidv4(),  // Token family ID
    created: Date.now()
  });
  await redis.expire(`refresh:${tokenId}`, REFRESH_TOKEN_TTL);
};

// Subnet matching for IP verification
const isIpInSameSubnet = (originalIp, currentIp) => {
  // For IPv4
  if (originalIp.includes('.') && currentIp.includes('.')) {
    const origParts = originalIp.split('.').map(Number);
    const currParts = currentIp.split('.').map(Number);
    
    // Check if in same /24 subnet
    return origParts[0] === currParts[0] && 
           origParts[1] === currParts[1] && 
           origParts[2] === currParts[2];
  }
  
  // For IPv6 (simplified)
  if (originalIp.includes(':') && currentIp.includes(':')) {
    // Use first 6 groups for /48 subnet match
    const origParts = originalIp.split(':').slice(0, 6).join(':');
    const currParts = currentIp.split(':').slice(0, 6).join(':');
    
    return origParts === currParts;
  }
  
  return false;
};

// IP verification with tiered approach
const verifyIp = async (tokenData, currentIp) => {
  const { ip: originalIp } = tokenData;
  
  // Exact match - proceed normally
  if (originalIp === currentIp) {
    return { valid: true, level: 'exact' };
  }
  
  // Subnet match - proceed with warning
  if (isIpInSameSubnet(originalIp, currentIp)) {
    return { valid: true, level: 'subnet' };
  }
  
  // Different country/region - require full reauthentication
  const origCountry = await getCountryForIp(originalIp);
  const currCountry = await getCountryForIp(currentIp);
  
  if (origCountry !== currCountry) {
    return { valid: false, level: 'country', reason: 'DIFFERENT_COUNTRY' };
  }
  
  // Different network but same country - require additional verification
  return { valid: false, level: 'network', reason: 'DIFFERENT_NETWORK' };
};
```

## Token Family Tracking and Theft Detection

```javascript
// Token family structure
// refresh:{tokenId} -> { userId, ip, family, created, used }
// family:{familyId} -> Set of active token IDs

// Storing a new token in a family
const addTokenToFamily = async (familyId, tokenId) => {
  await redis.sadd(`family:${familyId}`, tokenId);
};

// When refreshing a token
const rotateToken = async (oldTokenId, newTokenId, ip) => {
  const tokenData = await redis.hgetall(`refresh:${oldTokenId}`);
  
  if (!tokenData || !tokenData.family) {
    throw new Error('Invalid token');
  }
  
  // Mark old token as used
  await redis.hset(`refresh:${oldTokenId}`, 'used', Date.now());
  
  // Store new token with same family
  await storeRefreshToken(tokenData.userId, newTokenId, ip, tokenData.family);
  await addTokenToFamily(tokenData.family, newTokenId);
  
  return tokenData.family;
};

// Detecting token reuse (potential theft)
const detectTokenReuse = async (tokenId) => {
  const tokenData = await redis.hgetall(`refresh:${tokenId}`);
  
  if (!tokenData) {
    throw new Error('Invalid token');
  }
  
  // Check if token was previously used
  if (tokenData.used) {
    // Potential token theft detected!
    await invalidateFamily(tokenData.family);
    throw new Error('TOKEN_REUSE_DETECTED');
  }
  
  return tokenData;
};

// Invalidating a compromised token family
const invalidateFamily = async (familyId) => {
  const tokenIds = await redis.smembers(`family:${familyId}`);
  
  // Add family to blacklist
  await redis.sadd('blacklisted_families', familyId);
  
  // Delete all tokens in this family
  for (const tokenId of tokenIds) {
    await redis.del(`refresh:${tokenId}`);
  }
  
  // Delete the family
  await redis.del(`family:${familyId}`);
  
  // Log security event
  await logSecurityEvent({
    type: 'TOKEN_FAMILY_INVALIDATED',
    familyId,
    tokenCount: tokenIds.length,
    timestamp: Date.now()
  });
};
```

## Rate Limiting Implementation

```javascript
// Rate limiting configuration
const rateLimits = {
  login: {
    points: 5,           // 5 attempts
    duration: 300,       // per 5 minutes (300 seconds)
    blockDuration: 900   // block for 15 minutes after exceeding
  },
  registration: {
    points: 3,           // 3 attempts
    duration: 86400,     // per 24 hours
    blockDuration: 86400 // block for 24 hours after exceeding
  },
  passwordReset: {
    points: 3,           // 3 attempts
    duration: 3600,      // per 1 hour
    blockDuration: 7200  // block for 2 hours after exceeding
  },
  // Default limits for authenticated endpoints
  authenticated: {
    points: 100,         // 100 requests
    duration: 60,        // per minute
    blockDuration: 0     // don't block, just delay
  }
};

// Rate limiting implementation using sliding window with Redis
const isRateLimited = async (key, limit) => {
  const now = Date.now();
  const windowStart = now - (limit.duration * 1000);
  
  // Remove old attempts
  await redis.zremrangebyscore(key, 0, windowStart);
  
  // Count recent attempts
  const attemptCount = await redis.zcard(key);
  
  if (attemptCount >= limit.points) {
    // Rate limit exceeded
    const oldestAttempt = await redis.zrange(key, 0, 0, 'WITHSCORES');
    const resetTime = parseInt(oldestAttempt[1]) + (limit.duration * 1000);
    const retryAfter = Math.ceil((resetTime - now) / 1000);
    
    return { limited: true, retryAfter };
  }
  
  // Record this attempt
  await redis.zadd(key, now, uuidv4());
  await redis.expire(key, limit.duration * 2); // Set expiry for housekeeping
  
  return { limited: false };
};

// Example usage for login
const checkLoginRateLimit = async (email, ip) => {
  const emailKey = `ratelimit:login:email:${email}`;
  const ipKey = `ratelimit:login:ip:${ip}`;
  
  // Check both email and IP rate limits
  const emailLimit = await isRateLimited(emailKey, rateLimits.login);
  const ipLimit = await isRateLimited(ipKey, rateLimits.login);
  
  if (emailLimit.limited || ipLimit.limited) {
    // Use the longer retry time
    const retryAfter = Math.max(
      emailLimit.retryAfter || 0,
      ipLimit.retryAfter || 0
    );
    
    return { limited: true, retryAfter };
  }
  
  return { limited: false };
};
```

## Two-Factor Authentication

```javascript
// TOTP setup
const setupTOTP = async (userId) => {
  // Generate secret
  const secret = authenticator.generateSecret();
  
  // Store secret securely
  await storeUserTOTPSecret(userId, secret);
  
  // Generate QR code
  const otpauth = authenticator.keyuri(
    userId,
    'Smarter Firms',
    secret
  );
  
  const qrCode = await QRCode.toDataURL(otpauth);
  
  // Generate backup codes
  const backupCodes = generateBackupCodes();
  await storeBackupCodes(userId, backupCodes);
  
  return {
    secret,
    qrCode,
    backupCodes
  };
};

// TOTP verification
const verifyTOTP = async (userId, token) => {
  // Retrieve user's secret
  const secret = await getUserTOTPSecret(userId);
  
  if (!secret) {
    throw new Error('2FA not set up for this user');
  }
  
  // Check if token is a backup code
  const isBackupCode = await checkAndUseBackupCode(userId, token);
  if (isBackupCode) {
    return true;
  }
  
  // Verify TOTP with some window to account for time skew
  return authenticator.verify({
    token,
    secret,
    window: 1 // Allow 1 period before/after for clock skew
  });
};

// Backup code generation
const generateBackupCodes = () => {
  const codes = [];
  for (let i = 0; i < 10; i++) {
    // Generate 8-character alphanumeric code
    codes.push(crypto.randomBytes(4).toString('hex'));
  }
  return codes;
};

// Store backup codes (hashed)
const storeBackupCodes = async (userId, codes) => {
  const hashedCodes = await Promise.all(
    codes.map(code => argon2.hash(code, argon2Options))
  );
  
  await redis.del(`backupcodes:${userId}`);
  await redis.sadd(`backupcodes:${userId}`, ...hashedCodes);
};

// Verify and use backup code
const checkAndUseBackupCode = async (userId, code) => {
  const hashedCodes = await redis.smembers(`backupcodes:${userId}`);
  
  for (const hashedCode of hashedCodes) {
    try {
      const matches = await argon2.verify(hashedCode, code);
      if (matches) {
        // Remove used backup code
        await redis.srem(`backupcodes:${userId}`, hashedCode);
        return true;
      }
    } catch (err) {
      continue;
    }
  }
  
  return false;
};
```

## Security Auditing and Logging

```javascript
// Security event types
const SECURITY_EVENTS = {
  LOGIN_SUCCESS: 'login_success',
  LOGIN_FAILURE: 'login_failure',
  LOGOUT: 'logout',
  PASSWORD_CHANGE: 'password_change',
  PASSWORD_RESET_REQUEST: 'password_reset_request',
  PASSWORD_RESET_COMPLETE: 'password_reset_complete',
  ACCOUNT_LOCKOUT: 'account_lockout',
  TOKEN_REFRESH: 'token_refresh',
  TOKEN_REUSE_DETECTED: 'token_reuse_detected',
  TOKEN_FAMILY_INVALIDATED: 'token_family_invalidated',
  MFA_SETUP: 'mfa_setup',
  MFA_VERIFICATION_SUCCESS: 'mfa_verification_success',
  MFA_VERIFICATION_FAILURE: 'mfa_verification_failure',
  CONSULTANT_FIRM_ACCESS: 'consultant_firm_access'
};

// Logging security events
const logSecurityEvent = async (event) => {
  const {
    type,
    userId,
    ip,
    userAgent,
    success = true,
    reason = null,
    metadata = {}
  } = event;
  
  const logEntry = {
    type,
    userId: userId || 'anonymous',
    ip: ip || 'unknown',
    userAgent: userAgent || 'unknown',
    timestamp: new Date().toISOString(),
    success,
    reason,
    ...metadata
  };
  
  // Log to database for persistence
  await db.securityLogs.create({ data: logEntry });
  
  // Log to stdout in development
  if (process.env.NODE_ENV !== 'production') {
    console.log(`SECURITY_EVENT: ${JSON.stringify(logEntry)}`);
  }
  
  // For critical events, send to monitoring system
  if (CRITICAL_EVENTS.includes(type) || !success) {
    await notifySecurityMonitoring(logEntry);
  }
};
```

## Consultant-Specific Security Measures

Consultant accounts have enhanced security requirements due to their access to multiple firms' data:

1. **Mandatory 2FA**: Two-factor authentication is required, not optional
2. **Session Timeouts**: Shorter session duration (60 minutes vs 8 hours)
3. **Activity Auditing**: Detailed logs of all data access across firms
4. **Permission Granularity**: Fine-grained access control for different data types
5. **Cross-Firm Isolation**: Strict data boundaries between firms in the same session 