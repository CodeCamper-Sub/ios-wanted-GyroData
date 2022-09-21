//
//  CoreDataManager.swift
//  GyroData
//
//  Created by channy on 2022/09/21.
//

import Foundation
import CoreData

class CoreDataManager {
    
    static var shared: CoreDataManager = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MotionModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unsolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    var context: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }
    
    func fetch<T: NSManagedObject>(request: NSFetchRequest<T>) -> [T] {
        do {
            let fetchResult = try self.context.fetch(request)
            return fetchResult
        } catch {
            // MARK: fetch 실패할 경우 에러 처리
            print(error.localizedDescription)
            return []
        }
    }
    
    @discardableResult
    func insertMotionTask(motion: Motion) -> Bool {
        let entity = NSEntityDescription.entity(forEntityName: "MotionModel", in: self.context)
        
        if let entity = entity {
            let managedObject = NSManagedObject(entity: entity, insertInto: self.context)
            
            managedObject.setValue(motion.type, forKey: "type")
            managedObject.setValue(motion.time, forKey: "time")
            managedObject.setValue(motion.date, forKey: "date")
            managedObject.setValue(motion.path, forKey: "path")
            
            do {
                try self.context.save()
                return true
            } catch {
                // MARK: save 실패할 경우 에러 처리
                print(error.localizedDescription)
                return false
            }
        } else {
            return false
        }
    }
    
    @discardableResult
    func delete(object: NSManagedObject) -> Bool {
        self.context.delete(object)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    func count<T: NSManagedObject>(request: NSFetchRequest<T>) -> Int? {
        do {
            let count = try self.context.count(for: request)
            return count
        } catch {
            return nil
        }
    }
}
