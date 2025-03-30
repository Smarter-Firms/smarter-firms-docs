# Caching Strategy Documentation

## Overview

The Data Service implements a comprehensive caching strategy to optimize performance, reduce database load, and improve response times for frequently accessed data. This document outlines the caching architecture, implementation details, and best practices for cache management.

## Cache Architecture

### Cache Layers

The caching system operates at multiple layers:

1. **In-Memory Cache**: 
   - First-level cache using Node-Cache for fastest access
   - Stored in the application memory
   - Limited by available memory resources
   
2. **Distributed Cache**: 
   - Second-level cache using Redis
   - Shared across multiple service instances
   - Supports larger cache size and persistence

3. **Application-Level Cache**:
   - Cached results of complex calculations
   - Eliminates redundant processing of the same data
   - Used for analytics and reporting data

### Cache Keys

Cache keys are carefully structured to ensure proper isolation and efficient invalidation:

```
<prefix>:<tenant-id>:<entity-name>:<id>:<version>
```

- **Prefix**: Identifies the cache type (e.g., "repo", "query", "analytics")
- **Tenant ID**: Ensures multi-tenant isolation
- **Entity Name**: Identifies the entity type (e.g., "matter", "client", "timekeeper")
- **ID**: Unique identifier for the specific entity
- **Version**: Optional version identifier for cache invalidation

### Cache Manager

The `CacheManager` class provides a unified interface for cache operations:

- `getOrSet()`: Retrieves a value from cache or executes a function to generate it
- `set()`: Stores a value in the cache with a specified TTL
- `get()`: Retrieves a value from the cache
- `del()`: Removes a value from the cache
- `invalidate()`: Invalidates cache entries based on patterns
- `generateKey()`: Creates standardized cache keys

## Cache Categories and TTLs

Different types of data are cached with appropriate Time-To-Live (TTL) values:

| Category | TTL | Example Data | Rationale |
|----------|-----|--------------|-----------|
| Entity Data | 5 minutes | Single matter, client, or timekeeper | Frequently updated business data |
| Entity Lists | 5 minutes | List of matters or clients | Aggregate data that changes with individual records |
| Reference Data | 30 minutes | Practice areas, matter types | Rarely changed reference data |
| User Data | 15 minutes | User profiles, permissions | Security-related data with moderate update frequency |
| Analytics | 1 hour | Utilization metrics, collection rates | Computationally expensive calculations |
| Reports | 6 hours | Financial reports, performance dashboards | Complex aggregations with daily relevance |
| Historical Data | 24 hours | Year-to-date metrics, historical trends | Historical data that rarely changes |

## Cache Invalidation Strategies

### Time-Based Invalidation

- TTL-based expiration for all cache entries
- Differentiated TTLs based on data type and update frequency
- Allows stale data to be automatically refreshed

### Event-Based Invalidation

- Cache entries invalidated when related data changes
- Triggered by database update events
- Targeted invalidation to minimize cache misses

### Pattern-Based Invalidation

- Invalidation of related cache entries using key patterns
- Example: Updating a matter invalidates associated client caches
- Useful for complex relationships between entities

### Bulk Invalidation

- Selective purging of cache categories
- Used during major data changes or migrations
- Configurable to target specific tenants or data types

## Multi-Tenant Considerations

- Tenant ID included in all cache keys
- Prevents data leakage between tenants
- Enables tenant-specific cache invalidation
- Supports tenant-level cache size controls

## Cache Optimization Techniques

### Partial Caching

- Caching only essential fields rather than entire objects
- Reduces memory usage and improves cache hit ratio
- Implemented for large entities with rarely accessed fields

### Compression

- Compression of large cache values
- Reduces memory footprint of the cache
- Applied selectively based on value size

### Tiered Cache Expiration

- Short TTL for most frequently accessed/updated data
- Longer TTL for relatively stable data
- Very long TTL for historical/archival data

### Cache Warming

- Proactive population of cache for predictable access patterns
- Executed during low-usage periods
- Prevents cache misses during peak usage

## Cache Monitoring and Metrics

The caching system collects and exposes the following metrics:

- **Hit Rate**: Percentage of cache hits vs. misses
- **Memory Usage**: Current memory consumption of the cache
- **Average Response Time**: With and without cache hits
- **Eviction Rate**: Rate of cache entries evicted before expiration
- **Cache Size**: Number of items in cache by category

## Implementation in Repositories

All repositories extend the `BaseRepository` class which integrates with the cache manager:

```typescript
// Example of caching in repository
async findById(id: string): Promise<T | null> {
  const cacheKey = this.cache.generateKey({
    prefix: this.entityName,
    id,
    tenantId: getCurrentTenantId()
  });
  
  return this.cache.getOrSet(
    cacheKey,
    async () => {
      // Database query if cache miss
      return await this.prisma[this.entityName].findUnique({
        where: { id }
      });
    },
    60 * 5 // 5 minute TTL
  );
}
```

## Cache Configuration

The caching behavior is configurable through environment variables:

- `CACHE_ENABLED`: Master switch to enable/disable caching
- `CACHE_TTL_DEFAULT`: Default TTL for cached items
- `CACHE_MAX_SIZE`: Maximum size of the in-memory cache
- `REDIS_CACHE_ENABLED`: Enable/disable Redis as second-level cache
- `CACHE_COMPRESSION_THRESHOLD`: Size threshold for compressing cache values

## Best Practices

1. **Always include tenant ID** in cache keys to maintain multi-tenant isolation
2. **Use appropriate TTLs** based on data update frequency
3. **Add targeted cache invalidation** when updating data
4. **Cache sparingly** for frequently updated data
5. **Monitor cache hit rates** to identify optimization opportunities
6. **Use the CacheManager abstraction** rather than direct cache access
7. **Consider memory implications** when caching large data sets
8. **Include version identifiers** in cache keys for easy invalidation 