# Geographic Anomaly Detection

> **Note**: This is a work-in-progress document. When finalized, it should be moved to `smarter-firms-docs/api-gateway/security/geographic-anomaly-detection.md`.

## Overview

The Geographic Anomaly Detection system monitors authentication attempts across the API Gateway to identify potentially suspicious login patterns based on geographic location. This document describes the implementation, configuration, and integration of the geographic anomaly detection system.

## Implementation Architecture

The system consists of several components:

1. **IP Geolocation Service**: Resolves IP addresses to geographic locations
2. **User Location Database**: Tracks known user locations
3. **Anomaly Detection Engine**: Analyzes login patterns for suspicious activity
4. **Alerting System**: Generates alerts for suspicious login attempts
5. **Security Monitoring Integration**: Feeds data to the security monitoring service

![Geographic Anomaly Detection Architecture](https://placeholder-for-geo-anomaly-diagram.png)

## How It Works

### Location Tracking Process

1. When a user successfully authenticates, their IP address is resolved to a geographic location
2. The location is compared with the user's location history in Redis
3. If the location is new, it's added to the user's known locations
4. Subsequent logins are compared against this history to detect anomalies

### Anomaly Detection Logic

The system identifies several types of geographic anomalies:

1. **Impossible Travel**: Login attempts from locations that would be physically impossible to reach given the time between authentication attempts
2. **Unusual Countries**: Login attempts from countries where the user has never logged in before
3. **High-Risk Regions**: Login attempts from locations known for high rates of fraud
4. **Multiple Country Logins**: Rapid sequence of logins from different countries

## Integration with Authentication

The geographic anomaly detection is integrated with the authentication middleware:

```javascript
// Excerpt from the token verification middleware
const verifyToken = async (req, res, next) => {
  // ... existing token verification code ...
  
  // After successful token verification
  if (payload) {
    try {
      // Check for geographic anomalies
      const userId = payload.sub || payload.id;
      const clientIp = req.ip || req.connection.remoteAddress;
      
      // Skip for local/internal IPs
      if (!isInternalIp(clientIp)) {
        const isAnomalous = await geoAnomalyDetection.checkLocation({
          userId,
          clientIp,
          userAgent: req.headers['user-agent'],
          timestamp: Date.now()
        });
        
        if (isAnomalous) {
          // Log the anomaly but don't block the request
          // This can be configured to block in high-security environments
          logger.warn('Geographic anomaly detected', {
            userId,
            clientIp,
            anomalyType: isAnomalous.type,
            risk: isAnomalous.riskScore
          });
          
          // Record security event
          await securityMonitoring.recordSecurityEvent({
            type: 'GEO_ANOMALY',
            userId,
            ip: clientIp,
            userAgent: req.headers['user-agent'],
            details: isAnomalous,
            severity: isAnomalous.riskScore > 80 ? 'high' : 'medium'
          });
          
          // Add anomaly info to request for downstream services
          req.securityContext = req.securityContext || {};
          req.securityContext.geoAnomaly = isAnomalous;
        }
      }
    } catch (error) {
      // Non-blocking error
      logger.error('Error in geographic anomaly detection', {
        error: error.message
      });
    }
  }
  
  // ... continue with request processing ...
};
```

## Geolocation Service

The system supports multiple geolocation service providers:

1. **MaxMind GeoIP2**: Default provider with IP database
2. **IP-API**: Backup real-time API service
3. **ipstack**: Another alternative provider

The implementation includes fallback mechanisms if the primary service fails, ensuring reliable geolocation even during service disruptions.

## Configuration Options

### Main Configuration

Geographic anomaly detection is configured in `src/config/security-monitoring.js`:

```javascript
geoAnomalyDetection: {
  // Enable/disable the feature
  enabled: true,
  
  // Geolocation service configuration
  geoService: {
    provider: 'maxmind', // 'maxmind', 'ipapi', or 'ipstack'
    apiKey: process.env.GEOIP_API_KEY,
    dbPath: './data/GeoLite2-City.mmdb',
    cacheTime: 86400 // 24 hours
  },
  
  // Known location history
  locationHistory: {
    maxLocations: 10, // Maximum number of locations to remember per user
    expirationDays: 90 // Number of days to remember locations
  },
  
  // Anomaly detection settings
  detectionSettings: {
    // Impossible travel detection (speed in km/h)
    impossibleTravelSpeedThreshold: 800,
    
    // High-risk countries (ISO country codes)
    highRiskCountries: ['XX', 'YY', 'ZZ'],
    
    // Alert thresholds
    minRiskScoreForAlert: 60,
    
    // Response actions
    blockHighRiskLogins: false, // Whether to block high-risk logins
    riskScoreForBlocking: 90    // Minimum risk score to block if enabled
  }
}
```

### Environment Variables

Key environment variables that control the system:

| Variable | Description | Default |
|----------|-------------|---------|
| `GEO_ANOMALY_DETECTION_ENABLED` | Enable/disable the entire feature | `true` |
| `GEOIP_PROVIDER` | Geolocation provider to use | `maxmind` |
| `GEOIP_API_KEY` | API key for geolocation service | - |
| `BLOCK_HIGH_RISK_LOGINS` | Whether to block high-risk logins | `false` |

## Risk Scoring System

Each anomaly is assigned a risk score from 0-100 based on several factors:

1. **Distance Factor**: Score increases with geographic distance
2. **Time Factor**: Score increases with impossibly short travel times
3. **Location History**: Score is higher for completely new locations
4. **Country Risk**: Score is higher for known high-risk countries
5. **User Pattern**: Score is lower for users with varied travel patterns

The final risk score determines the action taken:

- **0-59**: Low risk - Monitor only
- **60-89**: Medium risk - Generate alert but allow
- **90-100**: High risk - Generate alert and optionally block

## Response Actions

The system supports several response actions for detected anomalies:

1. **Logging**: All anomalies are logged for analysis
2. **Alerting**: Medium and high-risk anomalies generate alerts
3. **Notify User**: Optional email/SMS to notify user of suspicious login
4. **Require MFA**: Can be configured to trigger additional authentication
5. **Block Access**: Optional blocking of high-risk login attempts

## Admin Dashboard Integration

Security administrators can view geographic anomalies through the admin dashboard:

1. **World Map View**: Visual representation of login locations
2. **User Travel Paths**: Timeline view of user location changes
3. **Anomaly Reports**: Detailed reports of detected anomalies
4. **Risk Configuration**: Interface to adjust risk thresholds

## Performance Considerations

The geographic anomaly detection system is designed for minimal performance impact:

1. **Asynchronous Processing**: Geolocation happens after authentication succeeds
2. **Caching**: IP geolocation results are cached to reduce API calls
3. **Redis Storage**: Fast in-memory storage for location history
4. **Feature Toggle**: Can be disabled in high-load scenarios

## Data Privacy and Compliance

The geographic anomaly detection system adheres to privacy requirements:

1. **Data Minimization**: Only stores location data, not full IP addresses long-term
2. **Purpose Limitation**: Data used only for security purposes
3. **Retention Control**: Configurable retention period for location history
4. **User Transparency**: Login location tracking is documented in privacy policy

## Common Scenarios

### Multiple Office Locations

For users who regularly work from different office locations:

1. All regular office locations are quickly learned by the system
2. Subsequent logins from these locations won't trigger alerts
3. Location history can be pre-configured for known locations

### VPN Usage

For users who frequently use VPNs:

1. The system can be configured to recognize common VPN endpoints
2. Administrators can mark known corporate VPN IP ranges for special handling
3. VPN detection logic reduces false positives for VPN users

## Monitoring and Metrics

The following metrics are available for the geographic anomaly detection system:

1. **Anomaly Count**: Number of anomalies detected by type
2. **False Positive Rate**: Estimated false positive rate based on user feedback
3. **Processing Time**: Time spent on geolocation and analysis
4. **Provider Reliability**: Uptime and response time of geolocation providers

## References

- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [MaxMind GeoIP2 Documentation](https://dev.maxmind.com/geoip/)
- [IP-API Documentation](https://ip-api.com/docs/)
- [Smarter Firms Security Standards](https://github.com/Smarter-Firms/smarter-firms-docs/security/standards.md) 