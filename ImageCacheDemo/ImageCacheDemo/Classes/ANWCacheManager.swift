//
//  ANWCacheManager.swift
//  Annul Mobile
//
//  Created by Anil ORUC on 14/09/16.
//  Copyright © 2016 Annul Mobile. All rights reserved.
//

import UIKit

class ANWCacheManager: NSObject {

    static let instance = ANWCacheManager()
    
    private static let cacheNamespace: String = "com.annulmobile.allCache"
    
    private static let cachePath: String = "ANWCache"

    private static let kDefaultCacheMaxCacheAge: Double = 60 * 60 * 24 * 7; // 1 week

    private let ioQueue = DispatchQueue(label: ANWCacheManager.cacheNamespace, attributes: [.concurrent])

    private let memCache: NSCache = { () -> NSCache<AnyObject, AnyObject> in 
        let cache = NSCache<AnyObject, AnyObject>()
        cache.name = ANWCacheManager.cacheNamespace
        return cache
    }()

    private let diskCachePath: String = {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                      .userDomainMask,
                                                      true).first!
        let namespace = ANWCacheManager.cacheNamespace
        let pathURL = NSURL(fileURLWithPath: String(path)).appendingPathComponent(namespace, isDirectory: true)
        return pathURL?.path ?? ""
    }()

    private let fileManager: FileManager = {
        let manager = FileManager.default
        let cacheDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!.stringByAppendingPathComponent(path: ANWCacheManager.cachePath)
        if !manager.fileExists(atPath: cacheDirectoryPath) {
            do {
                try manager.createDirectory(atPath: cacheDirectoryPath, withIntermediateDirectories: false, attributes: nil)
            } catch _ {

            }
        }
        return FileManager()
    }()

    private let cacheDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                                 .userDomainMask,
                                                                 true).first!.stringByAppendingPathComponent(path: ANWCacheManager.cachePath)


    private func defaultCachePath(key: String) -> String {
        return cachePath(key: key, inPath: diskCachePath)
    }

    private func cachePath(key: String, inPath: String) -> String {
        let fileName = key.md5
        let pathURL = NSURL(fileURLWithPath: String(inPath)).appendingPathComponent(fileName!, isDirectory: true)
        return pathURL!.path
    }

    override init() {
        super.init()

        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(clearMemory),
                                                         name:NSNotification.Name.UIApplicationDidReceiveMemoryWarning,
                                                         object: nil)
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(cleanDisk),
                                                         name:NSNotification.Name.UIApplicationWillTerminate,
                                                         object: nil)
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(backgroundCleanDisk),
                                                         name:NSNotification.Name.UIApplicationDidEnterBackground,
                                                         object: nil)
    }

    deinit {

        NotificationCenter.default.removeObserver(self,
                                                            name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning,
                                                            object: nil)

        clearMemory()

    }

    @objc private func clearMemory() {

        memCache.removeAllObjects()
    }

    @objc private func cleanDisk() {

        ioQueue.sync {
            let diskCacheURL = NSURL.fileURL(withPath: self.diskCachePath, isDirectory: true)
            let resourceKeys = [URLResourceKey.isDirectoryKey, URLResourceKey.contentModificationDateKey, URLResourceKey.totalFileAllocatedSizeKey]
            let fileEnumerator = FileManager.default.enumerator(at: diskCacheURL,
                                                                                includingPropertiesForKeys: resourceKeys,
                                                                                options: .skipsHiddenFiles,
                                                                                errorHandler: nil)
            
            if let fileEnumerator = fileEnumerator?.allObjects as? [NSURL] {
                let expirationDate = NSDate(timeIntervalSinceNow: -ANWCacheManager.kDefaultCacheMaxCacheAge)
                var cacheFiles: Dictionary<NSURL, Dictionary<URLResourceKey, AnyObject>> = Dictionary()
                var currentCacheSize: UInt = 0
                
                for fileURL: NSURL in fileEnumerator {
                    do {
                        let resourceValues: [URLResourceKey : AnyObject] = try fileURL.resourceValues(forKeys: resourceKeys) as [URLResourceKey : AnyObject]
                        
                        if let value = resourceValues[URLResourceKey.isDirectoryKey] as? NSNumber {
                            if value.boolValue {
                                continue
                            }
                        }
                        
                        if let modificationDate = resourceValues[URLResourceKey.contentModificationDateKey] as? NSDate {
                            if modificationDate.laterDate(expirationDate as Date) == expirationDate as Date {
                                continue
                            }
                        }
                        
                        if let totalAllocatedSize = resourceValues[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber {
                            currentCacheSize += totalAllocatedSize.uintValue
                            
                            cacheFiles[fileURL] = resourceValues
                        }
                    } catch _ {
                        
                    }
                }
            }
        }
    }

    @objc private func backgroundCleanDisk() {

        let application = UIApplication.shared

        var bgTask: UIBackgroundTaskIdentifier

        bgTask = application.beginBackgroundTask {

        }

        DispatchQueue.global().async {
            self.cleanDisk()
            
            application.endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskInvalid
        }
    }

    // MARK: - Set Object & Image Process
    func setImage(image: UIImage?, key: String) {

        guard let image = image else {
            return
        }
        if key.characters.count == 0 {
            return
        }

        memCache.setObject(image, forKey: key as AnyObject)
        let data = UIImagePNGRepresentation(image)

        if let data = data {
            setData(data: data as NSData, key: key)
        }
    }

    func setObject(object: AnyObject?, key: String) {

        guard let object = object else {
            return
        }
        if key.characters.count == 0 {
            return
        }

        memCache.setObject(object, forKey: key as AnyObject)

        let data = NSKeyedArchiver.archivedData(withRootObject: object)

        setData(data: data as NSData, key: key)
    }

    private func setData(data: NSData, key: String) {

        ioQueue.async {
            
            let fileManager = FileManager()
            if !fileManager.fileExists(atPath: self.diskCachePath) {
                do {
                    try fileManager.createDirectory(atPath: self.diskCachePath, withIntermediateDirectories: false, attributes: nil)
                } catch _ {
                    
                }
            }
            fileManager.createFile(atPath: self.defaultCachePath(key: key), contents: data as Data, attributes: nil)
        }
    }

    // MARK: - Get Object & Image Process
    func object(key: String) -> AnyObject? {
        if key.characters.count == 0 {
            return nil
        }

        guard let object = memCache.object(forKey: key as AnyObject) else {
            if let data = diskDataBySearchingAllPaths(key: key) {
                let object = NSKeyedUnarchiver.unarchiveObject(with: data as Data)
                if object != nil {
                    memCache.setObject(object! as AnyObject, forKey: key as AnyObject)
                }
                return object as AnyObject?
            }
            return nil
        }
        return object
    }

    func image(key: String) -> UIImage? {
        if key.characters.count == 0 {
            return nil
        }

        guard let image: UIImage = memCache.object(forKey: key as AnyObject) as? UIImage else {
            if let diskImage = imageFromDisk(key: key) {
                let cost: Int = Int(diskImage.size.height * diskImage.size.width * diskImage.scale)
                memCache.setObject(diskImage, forKey: key as AnyObject, cost: cost)
                return diskImage
            }
            return nil
        }

        return image
    }

    private func imageFromDisk(key: String) -> UIImage? {
        if let data = diskDataBySearchingAllPaths(key: key) {
            let image = UIImage(data: data as Data)
            return image
        }
        return nil
    }

    private func diskDataBySearchingAllPaths(key: String) -> NSData? {
        let defaultPath = defaultCachePath(key: key)
        let data = NSData(contentsOfFile: defaultPath)
        if data == nil {
            return nil
        }
        return data
    }

    // MARK: - Object Control & Object Remove Process
    func isHaveObject(key: String) -> Bool {
        if key.characters.count == 0 {
            return false
        }
        var control: Bool = memCache.object(forKey: key as AnyObject) == nil
        if control {
            ioQueue.sync {
                let fileManager = FileManager()
                control = fileManager.fileExists(atPath: self.defaultCachePath(key: key))
            }
        }
        return control
    }

    func removeObject(key: String?) {
        guard let key = key else {
            return
        }
        if key.characters.count == 0 {
            return
        }

        memCache.removeObject(forKey: key as AnyObject)

        ioQueue.async {
            do {
                try FileManager.default.removeItem(atPath: self.defaultCachePath(key: key))
            } catch(_) {
                
            }
        }
    }

    func clearDisk() {
        ioQueue.sync {
            do {
                try FileManager.default.removeItem(atPath: self.diskCachePath)
                try FileManager.default.createDirectory(atPath: self.diskCachePath,
                                                                         withIntermediateDirectories: false,
                                                                         attributes: nil)
            } catch _ {
                
            }
        }
    }

    // MARK: - UserDefaults Process
    func writeToUserDefaults(object: AnyObject, key: String) -> Bool {
        if key.characters.count == 0 {
            return false
        }
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(object, forKey: key)
        return userDefaults.synchronize()
    }
    
    func removeFromUserDefaults(key: String) -> Bool {
        if key.characters.count == 0 {
            return false
        }

        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: key)
        return userDefaults.synchronize()
    }

    func readFromUserDefaults(key: String) -> AnyObject? {
        if key.characters.count == 0 {
            return nil
        }

        let userDefaults = UserDefaults.standard
        return userDefaults.object(forKey: key) as AnyObject?
    }

    func saveCache(object: AnyObject, key: String) {
        if key.characters.count == 0 {
            return
        }

        memCache.setObject(object, forKey: key as AnyObject)
    }

    func readCacheObject(key: String) -> AnyObject? {

        return memCache.object(forKey: key as AnyObject)
    }
}
