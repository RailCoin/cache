import Foundation

class MemoryStorage2<T>: StorageAware2 {
  fileprivate let cache = NSCache<NSString, MemoryCapsule>()
  // Memory cache keys
  fileprivate var keys = Set<String>()
  /// Configuration
  fileprivate let config: MemoryConfig

  init(config: MemoryConfig) {
    self.config = config
    self.cache.countLimit = Int(config.countLimit)
  }

  func setObject(_ object: T, forKey key: String, expiry: Expiry? = nil) {
    let capsule = MemoryCapsule(value: object, expiry: .date(expiry?.date ?? config.expiry.date))
    cache.setObject(capsule, forKey: NSString(string: key))
    keys.insert(key)
  }

  func removeAll() {
    cache.removeAllObjects()
    keys.removeAll()
  }

  func removeExpiredObjects() {
    let allKeys = keys
    for key in allKeys {
      removeObjectIfExpired(forKey: key)
    }
  }

  func removeObjectIfExpired(forKey key: String) {
    if let capsule = cache.object(forKey: NSString(string: key)), capsule.expiry.isExpired {
      removeObject(forKey: key)
    }
  }

  func removeObject(forKey key: String) {
    cache.removeObject(forKey: NSString(string: key))
    keys.remove(key)
  }

  func entry(forKey key: String) throws -> Entry2<T> {
    guard let capsule = cache.object(forKey: NSString(string: key)) else {
      throw StorageError.notFound
    }

    guard let object = capsule.object as? T else {
      throw StorageError.typeNotMatch
    }

    return Entry2(object: object, expiry: capsule.expiry)
  }
}

extension MemoryStorage2 {
  func support<U>() -> MemoryStorage2<U> {
    let storage = MemoryStorage2<U>(config: config)
    return storage
  }
}
