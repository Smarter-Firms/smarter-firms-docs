# Response Caching Documentation

## Overview

The API Gateway implements a Redis-backed response caching system that stores and serves previously generated responses to improve performance and reduce load on backend services. The caching system is highly configurable with support for:

1. Per-endpoint TTL (Time-To-Live) settings
2. Smart cache key generation based on request parameters
3. Automatic and manual cache invalidation
4. Cache headers for client-side caching
5. Stale-while-revalidate pattern for background refreshing

## How Caching Works

The caching middleware intercepts requests and responses:

1. **On request**: Checks if a cached response exists for the request
   - If found, serves the cached response immediately
   - If not found, passes the request to the next middleware

2. **On response**: Stores successful responses in the cache 
   - Only caches responses with configured status codes (default: 200)
   - Stores response body, status code, and selected headers
   - Sets expiration based on TTL configuration

## Cache Key Generation

Cache keys are generated based on the following components:

- HTTP method (e.g., GET, POST)
- Request URL path
- Query parameters (sorted for consistency)
- User ID (for user-specific responses)
- Request body (for POST/PUT requests, configurable)

This creates unique keys that correctly differentiate between different requests. For example:

```
GET:/api/v1/users/123:user:456:{"include":"profile"}
```

Long keys are automatically hashed using SHA-256 to keep a manageable length.

## Configuration Options

### Global Cache Settings

Configure caching globally in `.env`:

```env
CACHE_ENABLED=true
CACHE_DEFAULT_TTL=60
CACHE_STALE_WHILE_REVALIDATE=5
CACHE_COMPRESSION=false
CACHE_EXCLUDE_PATHS=/api/v1/auth/login,/api/v1/auth/logout
```

### TTL Configuration

Different types of data have different optimal cache durations:

```env
CACHE_TTL_USER=300           # User data: 5 minutes
CACHE_TTL_RESOURCE=600       # Resource data: 10 minutes
CACHE_TTL_STATIC=3600        # Static data: 1 hour
CACHE_TTL_DASHBOARD=60       # Dashboard data: 1 minute  
CACHE_TTL_SEARCH=30          # Search results: 30 seconds
```

### Per-Route Cache Configuration

You can apply specific cache settings to individual routes:

```javascript
// Cache user listing for 5 minutes
app.get('/api/v1/users', cache({ ttl: 300 }), usersController.getAll);

// Don't cache user profile updates
app.put('/api/v1/users/:id', clearCache(), usersController.update);

// Cache with custom key generation
app.get('/api/v1/search', cache({
  ttl: 30,
  keyGenOptions: {
    query: true,   // Include query params
    user: false    // Ignore user ID
  }
}), searchController.search);
```

## Cache Invalidation

### Automatic Invalidation

The `clearCache` middleware automatically invalidates cache entries when data is modified:

```javascript
// Clear cache after updating a user
router.put('/users/:id', 
  clearCache({ 
    patterns: [`users*`, `user:${req.params.id}*`] 
  }),
  usersController.update
);
```

### Manual Invalidation via API

Cache can be manually invalidated through the API:

```
DELETE /api/v1/cache                        # Clear all cache
DELETE /api/v1/cache/pattern/:pattern       # Clear by pattern
DELETE /api/v1/cache/service/:serviceName   # Clear by service
```

These endpoints require administrator privileges.

## Cache Headers

The caching middleware automatically adds cache-related headers to responses:

- `X-Cache: HIT` or `X-Cache: MISS`: Indicates cache hit/miss
- `Cache-Control`: Controls browser caching behavior
- `ETag`: Entity tag for conditional requests

## Stale-While-Revalidate Pattern

The stale-while-revalidate pattern allows serving a stale cached response while asynchronously refreshing the cache in the background:

```javascript
app.get('/api/v1/dashboard', cache({
  ttl: 60,                    // Cache for 60 seconds
  staleWhileRevalidate: 30    // Refresh in background during last 30 seconds
}), dashboardController.get);
```

This provides optimal performance while keeping data relatively fresh.

## Monitoring Cache Performance

The API Gateway provides cache statistics via:

1. **API endpoint**: `GET /api/v1/cache/stats`
2. **Dashboard UI**: Available on the "Cache" tab in the dashboard

Statistics include:
- Total cache entries
- Entries by service
- Entries by endpoint type
- Hit/miss ratios (coming soon)

## Best Practices

1. **Set appropriate TTLs**: 
   - Short-lived for frequently changing data
   - Longer for static or rarely modified data

2. **Use cache invalidation with updates**:
   - Always clear cached data when updating related resources
   - Use pattern-based invalidation to clear related resources

3. **Monitor cache performance**:
   - Watch hit/miss ratios
   - Adjust TTLs based on usage patterns

4. **Exclude sensitive endpoints**:
   - Don't cache authentication endpoints
   - Don't cache user-specific data that requires fresh reads

5. **Consider payload size**:
   - Large responses might benefit from compression
   - Very large responses might be better uncached

## Troubleshooting

### Cache Not Working

1. Verify `CACHE_ENABLED=true` in your env config
2. Check that the endpoint is not in `CACHE_EXCLUDE_PATHS`
3. Ensure the endpoint uses a cacheable HTTP method (GET by default)
4. Check Redis connection is working properly
5. Verify the response status code is in the allowed list (default: 200)

### Cache Not Invalidating

1. Ensure `clearCache` middleware is applied to update routes
2. Check that pattern matching is correct
3. Verify Redis permissions allow DEL operations

### Excessive Memory Usage

1. Reduce TTLs for large responses
2. Enable compression for large payloads
3. Add more granular cache keys to reduce duplication 