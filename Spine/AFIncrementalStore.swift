// AFIncrementalStore.m
//
// Copyright (c) 2012 Mattt Thompson (http://mattt.me)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import CoreData

let AFIncrementalStoreUnimplementedMethodException:String! = "com.alamofire.incremental-store.exceptions.unimplemented-method"

let AFIncrementalStoreContextWillFetchRemoteValues:String! = "AFIncrementalStoreContextWillFetchRemoteValues"
let AFIncrementalStoreContextWillSaveRemoteValues:String! = "AFIncrementalStoreContextWillSaveRemoteValues"
let AFIncrementalStoreContextDidFetchRemoteValues:String! = "AFIncrementalStoreContextDidFetchRemoteValues"
let AFIncrementalStoreContextDidSaveRemoteValues:String! = "AFIncrementalStoreContextDidSaveRemoteValues"
let AFIncrementalStoreContextWillFetchNewValuesForObject:String! = "AFIncrementalStoreContextWillFetchNewValuesForObject"
let AFIncrementalStoreContextDidFetchNewValuesForObject:String! = "AFIncrementalStoreContextDidFetchNewValuesForObject"
let AFIncrementalStoreContextWillFetchNewValuesForRelationship:String! = "AFIncrementalStoreContextWillFetchNewValuesForRelationship"
let AFIncrementalStoreContextDidFetchNewValuesForRelationship:String! = "AFIncrementalStoreContextDidFetchNewValuesForRelationship"

let AFIncrementalStoreRequestOperationsKey:String! = "AFIncrementalStoreRequestOperations"
let AFIncrementalStoreFetchedObjectIDsKey:String! = "AFIncrementalStoreFetchedObjectIDs"
let AFIncrementalStoreFaultingObjectIDKey:String! = "AFIncrementalStoreFaultingObjectID"
let AFIncrementalStoreFaultingRelationshipKey:String! = "AFIncrementalStoreFaultingRelationship"
let AFIncrementalStorePersistentStoreRequestKey:String! = "AFIncrementalStorePersistentStoreRequest"

var kAFResourceIdentifierObjectKey:Int8 = Int8()

let kAFIncrementalStoreResourceIdentifierAttributeName:String! = "__af_resourceIdentifier"
let kAFIncrementalStoreLastModifiedAttributeName:String! = "__af_lastModified"

let kAFReferenceObjectPrefix:String! = "__af_"


// MARK: - AFIncrementalStore
class AFIncrementalStore : NSIncrementalStore {     private var _backingObjectIDByObjectID:NSCache<AnyObject, AnyObject>!
    private var _registeredObjectIDsByEntityNameAndNestedResourceIdentifier:NSMutableDictionary!
    private var _backingPersistentStoreCoordinator:NSPersistentStoreCoordinator!
    private var _backingManagedObjectContext:NSManagedObjectContext!
    private var _HTTPClient:Spine!
    
    var spineClient:Spine! {
        get { return Spine(baseURL: URL(string: "https://api.feltapp.com")!) }
    }
    
    private var backingPersistentStoreCoordinator:NSPersistentStoreCoordinator! {
        get { return _backingPersistentStoreCoordinator }
    }
    
    
    class func type() throws -> String! {
        throw NSError.init(domain: "", code: 1, userInfo: nil);
    }
    
    class func model() throws -> NSManagedObjectModel! {
        throw NSError.init(domain: "", code: 2, userInfo: nil);
    }
    
    // MARK: - METHODS FOR NOTIFYING ABOUT CHANGES TO THE OBJECT CONTEXT
    
    //    func notifyManagedObjectContext(context:NSManagedObjectContext!, aboutRequestOperation operation:AFHTTPRequestOperation!, forFetchRequest fetchRequest:NSFetchRequest!, fetchedObjectIDs:[AnyObject]!) {
    //        let notificationName:String! = operation.isFinished() ? AFIncrementalStoreContextDidFetchRemoteValues : AFIncrementalStoreContextWillFetchRemoteValues
    //
    //        let userInfo:NSMutableDictionary! = NSMutableDictionary.dictionary()
    //        userInfo.setObject([AnyObject].arrayWithObject(operation), forKey:AFIncrementalStoreRequestOperationsKey)
    //        userInfo.setObject(fetchRequest, forKey:AFIncrementalStorePersistentStoreRequestKey)
    //        if operation.isFinished() && fetchedObjectIDs {
    //            userInfo.setObject(fetchedObjectIDs, forKey:AFIncrementalStoreFetchedObjectIDsKey as! NSCopying)
    //        }
    //
    //        NotificationCenter.defaultCenter().postNotificationName(notificationName, object:context, userInfo:userInfo)
    //    }
    
    //    func notifyManagedObjectContext(context:NSManagedObjectContext!, aboutRequestOperations operations:[AnyObject]!, forSaveChangesRequest saveChangesRequest:NSSaveChangesRequest!) {
    //        let notificationName:String! = operations.lastObject().isFinished() ? AFIncrementalStoreContextDidSaveRemoteValues : AFIncrementalStoreContextWillSaveRemoteValues
    //
    //        let userInfo:NSMutableDictionary! = NSMutableDictionary.dictionary()
    //        userInfo.setObject(operations, forKey:AFIncrementalStoreRequestOperationsKey as! NSCopying)
    //        userInfo.setObject(saveChangesRequest, forKey:AFIncrementalStorePersistentStoreRequestKey)
    //
    //        NotificationCenter.defaultCenter().postNotificationName(notificationName, object:context, userInfo:userInfo)
    //    }
    //
    //    func notifyManagedObjectContext(context:NSManagedObjectContext!, aboutRequestOperation operation:AFHTTPRequestOperation!, forNewValuesForObjectWithID objectID:NSManagedObjectID!) {
    //        let notificationName:String! = operation.isFinished() ? AFIncrementalStoreContextDidFetchNewValuesForObject :AFIncrementalStoreContextWillFetchNewValuesForObject
    //
    //        let userInfo:MutableDictionary! = MutableDictionary.dictionary()
    //        userInfo.setObject([AnyObject].arrayWithObject(operation), forKey:AFIncrementalStoreRequestOperationsKey)
    //        userInfo.setObject(objectID, forKey:AFIncrementalStoreFaultingObjectIDKey)
    //
    //        NotificationCenter.defaultCenter().postNotificationName(notificationName, object:context, userInfo:userInfo)
    //    }
    //
    //    func notifyManagedObjectContext(context:NSManagedObjectContext!, aboutRequestOperation operation:AFHTTPRequestOperation!, forNewValuesForRelationship relationship:NSRelationshipDescription!, forObjectWithID objectID:NSManagedObjectID!) {
    //        let notificationName:String! = operation.isFinished() ? AFIncrementalStoreContextDidFetchNewValuesForRelationship : AFIncrementalStoreContextWillFetchNewValuesForRelationship
    //
    //        let userInfo:NSMutableDictionary! = NSMutableDictionary.dictionary()
    //        userInfo.setObject([AnyObject].arrayWithObject(operation), forKey:AFIncrementalStoreRequestOperationsKey)
    //        userInfo.setObject(objectID, forKey:AFIncrementalStoreFaultingObjectIDKey)
    //        userInfo.setObject(relationship, forKey:AFIncrementalStoreFaultingRelationshipKey)
    //
    //        NotificationCenter.defaultCenter().postNotificationName(notificationName, object:context, userInfo:userInfo)
    //    }
    
    // MARK: -
    
    func backingManagedObjectContext() -> NSManagedObjectContext! {
        if (_backingManagedObjectContext == nil) {
            _backingManagedObjectContext = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
            _backingManagedObjectContext.persistentStoreCoordinator = _backingPersistentStoreCoordinator
            _backingManagedObjectContext.retainsRegisteredObjects = true
        }
        
        return _backingManagedObjectContext
    }
    
    func objectIDForEntity(entity:NSEntityDescription!, withResourceIdentifier resourceIdentifier:String!) -> NSManagedObjectID! {
        if (resourceIdentifier == nil) {
            return nil
        }
        
        var objectID:NSManagedObjectID! = nil
        let objectIDsByResourceIdentifier:NSMutableDictionary! = _registeredObjectIDsByEntityNameAndNestedResourceIdentifier.object(forKey: entity.name!) as! NSMutableDictionary
        if (objectIDsByResourceIdentifier != nil) {
            objectID = objectIDsByResourceIdentifier.object(forKey: resourceIdentifier) as! NSManagedObjectID
        }
        
        if (objectID == nil) {
            objectID = self.newObjectID(for: entity, referenceObject:AFReferenceObjectFromResourceIdentifier(resourceIdentifier: resourceIdentifier))
        }
        
        assert(objectID.entity.name == entity.name)
        
        return objectID
    }
    
    func objectIDForBackingObjectForEntity(entity:NSEntityDescription!, withResourceIdentifier resourceIdentifier:String!) -> NSManagedObjectID! {
        if (resourceIdentifier == nil) {
            return nil
        }
        
        let objectID:NSManagedObjectID! = self.objectIDForEntity(entity: entity, withResourceIdentifier:resourceIdentifier)
        var backingObjectID:NSManagedObjectID! = _backingObjectIDByObjectID.object(forKey: objectID) as! NSManagedObjectID
        if (backingObjectID != nil) {
            return backingObjectID
        }
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity.name!)
        fetchRequest.resultType = .managedObjectIDResultType
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K = %@", argumentArray: [kAFIncrementalStoreResourceIdentifierAttributeName, resourceIdentifier])
        
        let error:NSError! = nil
        let backingContext:NSManagedObjectContext! = self.backingManagedObjectContext()
        backingContext.performAndWait({
            let result = try! backingContext.fetch(fetchRequest).last as! NSManagedObject
            backingObjectID = result.objectID
        })
        
        if (error != nil) {
            NSLog("Error: %@", error)
            return nil
        }
        
        if (backingObjectID != nil) {
            _backingObjectIDByObjectID.setObject(backingObjectID, forKey:objectID)
        }
        
        return backingObjectID
    }
    
    func updateBackingObject(backingObject:NSManagedObject!, withAttributeAndRelationshipValuesFromManagedObject managedObject:NSManagedObject!) {
        let mutableRelationshipValues:NSMutableDictionary! = NSMutableDictionary()
        for relationship:NSRelationshipDescription! in managedObject.entity.relationshipsByName.values {
            
            if managedObject.hasFault(forRelationshipNamed: relationship.name) {
                continue
            }
            
            let relationshipValue:AnyObject! = managedObject.value(forKey: relationship.name) as AnyObject
            if (relationshipValue == nil) {
                continue
            }
            
            if relationship.isToMany {
                var mutableBackingRelationshipValue:AnyObject! = nil
                if relationship.isOrdered {
                    mutableBackingRelationshipValue = NSMutableOrderedSet(capacity: relationshipValue.count)
                } else {
                    mutableBackingRelationshipValue = NSMutableSet(capacity: relationshipValue.count)
                }
                
                if let relationshipValueCollection = relationshipValue as? Array<NSManagedObject> {
                    for relationshipManagedObject:NSManagedObject! in relationshipValueCollection {
                        if !relationshipManagedObject.objectID.isTemporaryID {
                            let backingRelationshipObjectID:NSManagedObjectID! = self.objectIDForBackingObjectForEntity(entity: relationship.destinationEntity, withResourceIdentifier:AFResourceIdentifierFromReferenceObject(referenceObject: self.referenceObject(for: relationshipManagedObject.objectID) as AnyObject))
                            if (backingRelationshipObjectID != nil) {
                                let backingRelationshipObject:NSManagedObject! = try! backingObject.managedObjectContext!.existingObject(with: backingRelationshipObjectID)
                                if (backingRelationshipObject != nil) {
                                    mutableBackingRelationshipValue.add(backingRelationshipObject)
                                }
                            }
                        }
                    }
                }
                
                mutableRelationshipValues.setValue(mutableBackingRelationshipValue, forKey:relationship.name)
            } else {
                if !relationshipValue.objectID.isTemporaryID {
                    let backingRelationshipObjectID:NSManagedObjectID! = self.objectIDForBackingObjectForEntity(entity: relationship.destinationEntity, withResourceIdentifier:AFResourceIdentifierFromReferenceObject(referenceObject: self.referenceObject(for: relationshipValue.objectID) as AnyObject))
                    if (backingRelationshipObjectID != nil) {
                        let backingRelationshipObject:NSManagedObject! = try! backingObject.managedObjectContext!.existingObject(with: backingRelationshipObjectID)
                        mutableRelationshipValues.setValue(backingRelationshipObject, forKey:relationship.name)
                    }
                }
            }
        }
        
        backingObject.setValuesForKeys(mutableRelationshipValues as! [String : Any])
        let keys = Array(managedObject.entity.attributesByName.keys)
        backingObject.setValuesForKeys(managedObject.dictionaryWithValues(forKeys:keys))
    }
    
    // MARK: -
    func insertOrUpdateObjectsFromRepresentations(representationOrArrayOfRepresentations:AnyObject!, entity:NSEntityDescription!, response:HTTPURLResponse!, context:NSManagedObjectContext!, error:NSError!, completionBlock:(([AnyObject]?,[AnyObject]?)->Void)? = nil) -> Bool {
        
        if (representationOrArrayOfRepresentations == nil) {
            return false
        }
        
        assert((representationOrArrayOfRepresentations is NSArray) || (representationOrArrayOfRepresentations is NSDictionary))
        
        if representationOrArrayOfRepresentations.count == 0 {
            completionBlock?(Array(), Array())
            return false
        }
        
        let backingContext:NSManagedObjectContext! = self.backingManagedObjectContext()
        let lastModified:String! = response.allHeaderFields["Last-Modified"] as! String
        
        var representations = [Dictionary<String, AnyObject>]()
        if (representationOrArrayOfRepresentations is Array<Dictionary<String, AnyObject>>) {
            representations = representationOrArrayOfRepresentations as! [Dictionary<String, AnyObject>]
        } else if (representationOrArrayOfRepresentations is Dictionary<String, AnyObject>) {
            representations = [representationOrArrayOfRepresentations as! Dictionary<String, AnyObject>]
        }
        
        let numberOfRepresentations:Int = Int(representations.count)
        let mutableManagedObjects:NSMutableArray! = NSMutableArray(capacity: numberOfRepresentations)
        let mutableBackingObjects:NSMutableArray! = NSMutableArray(capacity: numberOfRepresentations)
        
        for var representation:Dictionary<String, AnyObject>! in representations {
            let resourceIdentifier:String! = representation["id"] as! String
            
            representation.removeValue(forKey: "id")
            let attributes:Dictionary! = representation//self.HTTPClient.attributesForRepresentation(representation, ofEntity:entity, fromResponse:response)
            
            var managedObject:NSManagedObject! = nil
            context.performAndWait({
                managedObject = try! context.existingObject(with: self.objectIDForEntity(entity: entity, withResourceIdentifier: resourceIdentifier))
            })
            
            managedObject.setValuesForKeys(attributes)
            
            let backingObjectID:NSManagedObjectID! = self.objectIDForBackingObjectForEntity(entity: entity, withResourceIdentifier:resourceIdentifier)
            var backingObject:NSManagedObject! = nil
            backingContext.performAndWait({
                if (backingObjectID != nil) {
                    backingObject = try! backingContext.existingObject(with: backingObjectID)
                } else {
                    backingObject = NSEntityDescription.insertNewObject(forEntityName: entity.name!, into:backingContext)
                    try! backingObject.managedObjectContext?.obtainPermanentIDs(for: [backingObject])
                }
            })
            backingObject.setValue(resourceIdentifier, forKey:kAFIncrementalStoreResourceIdentifierAttributeName)
            backingObject.setValue(lastModified, forKey:kAFIncrementalStoreLastModifiedAttributeName)
            backingObject.setValuesForKeys(attributes)
            
            if (backingObjectID == nil) {
                context.insert(managedObject)
            }
            
            let relationshipRepresentations:Dictionary<String, AnyObject> = [:]//self.HTTPClient.representationsForRelationshipsFromRepresentation(representation, ofEntity:entity, fromResponse:response)
            for relationshipName:String! in relationshipRepresentations.keys {
                let relationship:NSRelationshipDescription! = entity.relationshipsByName[relationshipName]
                let relationshipRepresentation:AnyObject! = relationshipRepresentations[relationshipName]
                if (relationship == nil) || (relationship.isOptional && ((relationshipRepresentation == nil) || relationshipRepresentation.isEqual(NSNull()))) {
                    continue
                }
                
                if (relationshipRepresentation == nil) || relationshipRepresentation.isEqual(NSNull()) || relationshipRepresentation.count == 0 {
                    managedObject.setValue(nil, forKey:relationshipName)
                    backingObject.setValue(nil, forKey:relationshipName)
                    continue
                }
                
                _ = self.insertOrUpdateObjectsFromRepresentations(representationOrArrayOfRepresentations: relationshipRepresentation, entity:relationship.destinationEntity, response:response, context:context, error:error, completionBlock:{ (managedObjects:[AnyObject]!,backingObjects:[AnyObject]!) in
                    if relationship.isToMany {
                        if relationship.isOrdered {
                            managedObject.setValue(NSOrderedSet(array: managedObjects), forKey:relationship.name)
                            backingObject.setValue(NSOrderedSet(array: backingObjects), forKey:relationship.name)
                        } else {
                            managedObject.setValue(NSSet(array: managedObjects), forKey:relationship.name)
                            backingObject.setValue(NSSet(array: backingObjects), forKey:relationship.name)
                        }
                    } else {
                        managedObject.setValue(managedObjects.last, forKey:relationship.name)
                        backingObject.setValue(backingObjects.last, forKey:relationship.name)
                    }
                })
            }
            
            mutableManagedObjects.add(managedObject)
            mutableBackingObjects.add(backingObject)
        }
        
        
        completionBlock?(mutableManagedObjects as [AnyObject]!, mutableBackingObjects as [AnyObject]!)
        
        return true
    }
    
    func executeFetchRequest(fetchRequest:NSFetchRequest<NSFetchRequestResult>!, withContext context:NSManagedObjectContext!, error:NSError!) -> AnyObject! {
        
        self.spineClient.findAll()
        
//        let request:NSURLRequest! = self.HTTPClient.requestForFetchRequest(fetchRequest, withContext:context)
//        if (request.url != nil) {
//            let operation:AFHTTPRequestOperation! = self.HTTPClient.HTTPRequestOperationWithRequest(request, success:{ (operation:AFHTTPRequestOperation!,responseObject:AnyObject!) in
//                context.performBlockAndWait({
//                    let representationOrArrayOfRepresentations:AnyObject! = self.HTTPClient.representationOrArrayOfRepresentationsOfEntity(fetchRequest.entity, fromResponseObject:responseObject)
//                    
//                    let childContext:NSManagedObjectContext! = NSManagedObjectContext(concurrencyType:NSPrivateQueueConcurrencyType)
//                    childContext.parentContext = context
//                    childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//                    
//                    childContext.performBlockAndWait({
//                        self.insertOrUpdateObjectsFromRepresentations(representationOrArrayOfRepresentations, ofEntity:fetchRequest.entity, fromResponse:operation.response, withContext:childContext, error:nil, completionBlock:{ (managedObjects:[AnyObject]!,backingObjects:[AnyObject]!) in
//                            let childObjects:NSSet! = childContext.registeredObjects()
//                            AFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext)
//                            
//                            let backingContext:NSManagedObjectContext! = self.backingManagedObjectContext()
//                            backingContext.performBlockAndWait({
//                                AFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext)
//                            })
//                            
//                            context.performBlockAndWait({
//                                for childObject:NSManagedObject! in childObjects {
//                                    let parentObject:NSManagedObject! = context.objectWithID(childObject.objectID)
//                                    context.refreshObject(parentObject, mergeChanges:true)
//                                }
//                            })
//                            
//                            self.notifyManagedObjectContext(context, aboutRequestOperation:operation, forFetchRequest:fetchRequest, fetchedObjectIDs:managedObjects.valueForKeyPath("objectID"))
//                        })
//                    })
//                })
//            }, failure:{ (operation:AFHTTPRequestOperation!,error:NSError!) in
//                NSLog("Error: %@", error)
//                self.notifyManagedObjectContext(context, aboutRequestOperation:operation, forFetchRequest:fetchRequest, fetchedObjectIDs:nil)
//            })
//            
//            self.notifyManagedObjectContext(context, aboutRequestOperation:operation, forFetchRequest:fetchRequest, fetchedObjectIDs:nil)
//            self.HTTPClient.enqueueHTTPRequestOperation(operation)
//        }
//        
//        let backingContext:NSManagedObjectContext! = self.backingManagedObjectContext()
//        let backingFetchRequest:NSFetchRequest! = fetchRequest.copy()
//        backingFetchRequest.entity = NSEntityDescription.entityForName(fetchRequest.entityName, inManagedObjectContext:backingContext)
//        
//        switch (fetchRequest.resultType) {
//        case NSManagedObjectResultType:
//            backingFetchRequest.resultType = NSDictionaryResultType
//            backingFetchRequest.propertiesToFetch = [AnyObject].arrayWithObject(kAFIncrementalStoreResourceIdentifierAttributeName)
//            let results:[AnyObject]! = backingContext.executeFetchRequest(backingFetchRequest, error:error)
//            
//            let mutableObjects:NSMutableArray! = NSMutableArray.arrayWithCapacity(results.count())
//            for resourceIdentifier:String! in results.valueForKeyPath(kAFIncrementalStoreResourceIdentifierAttributeName) {
//                let objectID:NSManagedObjectID! = self.objectIDForEntity(fetchRequest.entity, withResourceIdentifier:resourceIdentifier)
//                let object:NSManagedObject! = context.objectWithID(objectID)
//                object.af_resourceIdentifier = resourceIdentifier
//                mutableObjects.addObject(object)
//            }
//            
//            return mutableObjects
//            
//        case NSManagedObjectIDResultType:
//            let backingObjectIDs:[AnyObject]! = backingContext.executeFetchRequest(backingFetchRequest, error:error)
//            let managedObjectIDs:NSMutableArray! = NSMutableArray.arrayWithCapacity(backingObjectIDs.count())
//            
//            for backingObjectID:NSManagedObjectID! in backingObjectIDs {
//                let backingObject:NSManagedObject! = backingContext.objectWithID(backingObjectID)
//                let resourceID:String! = backingObject.valueForKey(kAFIncrementalStoreResourceIdentifierAttributeName)
//                managedObjectIDs.addObject(self.objectIDForEntity(fetchRequest.entity, withResourceIdentifier:resourceID))
//            }
//            
//            return managedObjectIDs
//            
//        case NSDictionaryResultType,
//             NSCountResultType:
//            return backingContext.executeFetchRequest(backingFetchRequest, error:error)
//        default:
//            return nil
//        }
        return nil
    }
}

//    func executeSaveChangesRequest(saveChangesRequest:NSSaveChangesRequest!, withContext context:NSManagedObjectContext!, error:NSError!) -> AnyObject! {
//        let mutableOperations:NSMutableArray! = NSMutableArray.array()
//        let backingContext:NSManagedObjectContext! = self.backingManagedObjectContext()
//        
//        if self.HTTPClient.respondsToSelector(Selector("requestForInsertedObject:")) {
//            for insertedObject:NSManagedObject! in saveChangesRequest.insertedObjects() {
//                let request:NSURLRequest! = self.HTTPClient.requestForInsertedObject(insertedObject)
//                if (request == nil) {
//                    backingContext.performBlockAndWait({
//                        let UUID:CFUUIDRef = CFUUIDCreate(nil)
//                        let resourceIdentifier:String! = CFUUIDCreateString(nil, UUID)
//                        CFRelease(UUID)
//                        
//                        let backingObject:NSManagedObject! = NSEntityDescription.insertNewObjectForEntityForName(insertedObject.entity.name, inManagedObjectContext:backingContext)
//                        backingObject.managedObjectContext.obtainPermanentIDsForObjects([AnyObject].arrayWithObject(backingObject), error:nil)
//                        backingObject.setValue(resourceIdentifier, forKey:kAFIncrementalStoreResourceIdentifierAttributeName)
//                        self.updateBackingObject(backingObject, withAttributeAndRelationshipValuesFromManagedObject:insertedObject)
//                        backingContext.save(nil)
//                    })
//                    
//                    insertedObject.willChangeValueForKey("objectID")
//                    context.obtainPermanentIDsForObjects([AnyObject].arrayWithObject(insertedObject), error:nil)
//                    insertedObject.didChangeValueForKey("objectID")
//                    continue
//                }
//                
//                let operation:AFHTTPRequestOperation! = self.HTTPClient.HTTPRequestOperationWithRequest(request, success:{ (operation:AFHTTPRequestOperation!,responseObject:AnyObject!) in
//                    let representationOrArrayOfRepresentations:AnyObject! = self.HTTPClient.representationOrArrayOfRepresentationsOfEntity(insertedObject.entity(),  fromResponseObject:responseObject)
//                    if (representationOrArrayOfRepresentations is NSDictionary) {
//                        let representation:NSDictionary! = representationOrArrayOfRepresentations
//                        
//                        let resourceIdentifier:String! = self.HTTPClient.resourceIdentifierForRepresentation(representation, ofEntity:insertedObject.entity(), fromResponse:operation.response)
//                        let backingObjectID:NSManagedObjectID! = self.objectIDForBackingObjectForEntity(insertedObject.entity(), withResourceIdentifier:resourceIdentifier)
//                        insertedObject.af_resourceIdentifier = resourceIdentifier
//                        insertedObject.valuesForKeysWithDictionary = self.HTTPClient.attributesForRepresentation(representation, ofEntity:insertedObject.entity, fromResponse:operation.response)
//                        
//                        backingContext.performBlockAndWait({
//                            var backingObject:NSManagedObject! = nil
//                            if (backingObjectID != nil) {
//                                backingContext.performBlockAndWait({
//                                    backingObject = backingContext.existingObjectWithID(backingObjectID, error:nil)
//                                })
//                            }
//                            
//                            if (backingObject == nil) {
//                                backingObject = NSEntityDescription.insertNewObjectForEntityForName(insertedObject.entity.name, inManagedObjectContext:backingContext)
//                                backingObject.managedObjectContext.obtainPermanentIDsForObjects([AnyObject].arrayWithObject(backingObject), error:nil)
//                            }
//                            
//                            backingObject.setValue(resourceIdentifier, forKey:kAFIncrementalStoreResourceIdentifierAttributeName)
//                            self.updateBackingObject(backingObject, withAttributeAndRelationshipValuesFromManagedObject:insertedObject)
//                            backingContext.save(nil)
//                        })
//                        
//                        insertedObject.willChangeValueForKey("objectID")
//                        context.obtainPermanentIDsForObjects([AnyObject].arrayWithObject(insertedObject), error:nil)
//                        insertedObject.didChangeValueForKey("objectID")
//                        
//                        context.refreshObject(insertedObject, mergeChanges:false)
//                    }
//                }, failure:{ (operation:AFHTTPRequestOperation!,error:NSError!) in
//                    NSLog("Insert Error: %@", error)
//                    
//                    // Reset destination objects to prevent dangling relationships
//                    for relationship:NSRelationshipDescription! in insertedObject.entity.relationshipsByName.allValues() {
//                        if !relationship.inverseRelationship {
//                            continue
//                        }
//                        
//                        var destinationObjects:NSFastEnumeration! = nil
//                        if relationship.isToMany() {
//                            destinationObjects = insertedObject.valueForKey(relationship.name)
//                        } else {
//                            let destinationObject:NSManagedObject! = insertedObject.valueForKey(relationship.name)
//                            if (destinationObject != nil) {
//                                destinationObjects = [AnyObject].arrayWithObject(destinationObject)
//                            }
//                        }
//                        
//                        for destinationObject:NSManagedObject! in destinationObjects {
//                            context.refreshObject(destinationObject, mergeChanges:false)
//                        }
//                    }
//                })
//                
//                mutableOperations.addObject(operation)
//            }
//        }
//        
//        if self.HTTPClient.respondsToSelector(Selector("requestForUpdatedObject:")) {
//            for updatedObject:NSManagedObject! in saveChangesRequest.updatedObjects() {
//                let backingObjectID:NSManagedObjectID! = self.objectIDForBackingObjectForEntity(updatedObject.entity(), withResourceIdentifier:AFResourceIdentifierFromReferenceObject(self.referenceObjectForObjectID(updatedObject.objectID)))
//                
//                let request:NSURLRequest! = self.HTTPClient.requestForUpdatedObject(updatedObject)
//                if (request == nil) {
//                    backingContext.performBlockAndWait({
//                        let backingObject:NSManagedObject! = backingContext.existingObjectWithID(backingObjectID, error:nil)
//                        self.updateBackingObject(backingObject, withAttributeAndRelationshipValuesFromManagedObject:updatedObject)
//                        backingContext.save(nil)
//                    })
//                    continue
//                }
//                
//                let operation:AFHTTPRequestOperation! = self.HTTPClient.HTTPRequestOperationWithRequest(request, success:{ (operation:AFHTTPRequestOperation!,responseObject:AnyObject!) in
//                    let representationOrArrayOfRepresentations:AnyObject! = self.HTTPClient.representationOrArrayOfRepresentationsOfEntity(updatedObject.entity(),  fromResponseObject:responseObject)
//                    if (representationOrArrayOfRepresentations is NSDictionary) {
//                        let representation:NSDictionary! = representationOrArrayOfRepresentations
//                        updatedObject.valuesForKeysWithDictionary = self.HTTPClient.attributesForRepresentation(representation, ofEntity:updatedObject.entity, fromResponse:operation.response)
//                        
//                        backingContext.performBlockAndWait({
//                            let backingObject:NSManagedObject! = backingContext.existingObjectWithID(backingObjectID, error:nil)
//                            self.updateBackingObject(backingObject, withAttributeAndRelationshipValuesFromManagedObject:updatedObject)
//                            backingContext.save(nil)
//                        })
//                        
//                        context.refreshObject(updatedObject, mergeChanges:true)
//                    }
//                }, failure:{ (operation:AFHTTPRequestOperation!,error:NSError!) in
//                    NSLog("Update Error: %@", error)
//                    context.refreshObject(updatedObject, mergeChanges:false)
//                })
//                
//                mutableOperations.addObject(operation)
//            }
//        }
//        
//        if self.HTTPClient.respondsToSelector(Selector("requestForDeletedObject:")) {
//            for deletedObject:NSManagedObject! in saveChangesRequest.deletedObjects() {
//                let backingObjectID:NSManagedObjectID! = self.objectIDForBackingObjectForEntity(deletedObject.entity(), withResourceIdentifier:AFResourceIdentifierFromReferenceObject(self.referenceObjectForObjectID(deletedObject.objectID)))
//                
//                let request:NSURLRequest! = self.HTTPClient.requestForDeletedObject(deletedObject)
//                if (request == nil) {
//                    backingContext.performBlockAndWait({
//                        let backingObject:NSManagedObject! = backingContext.existingObjectWithID(backingObjectID, error:nil)
//                        backingContext.deleteObject(backingObject)
//                        backingContext.save(nil)
//                    })
//                    continue
//                }
//                
//                let operation:AFHTTPRequestOperation! = self.HTTPClient.HTTPRequestOperationWithRequest(request, success:{ (operation:AFHTTPRequestOperation!,responseObject:AnyObject!) in
//                    backingContext.performBlockAndWait({
//                        let backingObject:NSManagedObject! = backingContext.existingObjectWithID(backingObjectID, error:nil)
//                        backingContext.deleteObject(backingObject)
//                        backingContext.save(nil)
//                    })
//                }, failure:{ (operation:AFHTTPRequestOperation!,error:NSError!) in
//                    NSLog("Delete Error: %@", error)
//                })
//                
//                mutableOperations.addObject(operation)
//            }
//        }
//        
//        // NSManagedObjectContext removes object references from an NSSaveChangesRequest as each object is saved, so create a copy of the original in order to send useful information in AFIncrementalStoreContextDidSaveRemoteValues notification.
//        let saveChangesRequestCopy:NSSaveChangesRequest! = NSSaveChangesRequest(insertedObjects:saveChangesRequest.insertedObjects.copy(), updatedObjects:saveChangesRequest.updatedObjects.copy(), deletedObjects:saveChangesRequest.deletedObjects.copy(), lockedObjects:saveChangesRequest.lockedObjects.copy())
//        
//        self.notifyManagedObjectContext(context, aboutRequestOperations:mutableOperations, forSaveChangesRequest:saveChangesRequestCopy)
//        
//        self.HTTPClient.enqueueBatchOfHTTPRequestOperations(mutableOperations, progressBlock:nil, completionBlock:{ (operations:[AnyObject]!) in
//            self.notifyManagedObjectContext(context, aboutRequestOperations:operations, forSaveChangesRequest:saveChangesRequestCopy)
//        })
//        
//        return [AnyObject].array()
//    }
//    
//    // MARK: - NSIncrementalStore
//    
//    func loadMetadata(error:NSError!) -> Bool {
//        if (_backingObjectIDByObjectID == nil) {
//            let mutableMetadata:NSMutableDictionary! = NSMutableDictionary.dictionary()
//            mutableMetadata.setValue(ProcessInfo.processInfo().globallyUniqueString(), forKey:NSStoreUUIDKey)
//            mutableMetadata.setValue(NSStringFromClass(self.self), forKey:NSStoreTypeKey)
//            self.metadata = mutableMetadata
//            
//            _backingObjectIDByObjectID = NSCache()
//            _registeredObjectIDsByEntityNameAndNestedResourceIdentifier = NSMutableDictionary()
//            
//            let model:NSManagedObjectModel! = self.persistentStoreCoordinator.managedObjectModel.copy()
//            for entity:NSEntityDescription! in model.entities {
//                // Don't add properties for sub-entities, as they already exist in the super-entity
//                if entity.superentity() {
//                    continue
//                }
//                
//                let resourceIdentifierProperty:NSAttributeDescription! = NSAttributeDescription()
//                resourceIdentifierProperty.name = kAFIncrementalStoreResourceIdentifierAttributeName
//                resourceIdentifierProperty.attributeType = NSStringAttributeType
//                resourceIdentifierProperty.indexed = true
//                
//                let lastModifiedProperty:NSAttributeDescription! = NSAttributeDescription()
//                lastModifiedProperty.name = kAFIncrementalStoreLastModifiedAttributeName
//                lastModifiedProperty.attributeType = NSStringAttributeType
//                lastModifiedProperty.indexed = false
//                
//                entity.properties = entity.properties.arrayByAddingObjectsFromArray([AnyObject].arrayWithObjects(resourceIdentifierProperty, lastModifiedProperty, nil))
//            }
//            
//            _backingPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel:model)
//            
//            return true
//        } else {
//            return false
//        }
//    }
//    
//    func obtainPermanentIDsForObjects(array:[AnyObject]!, error:NSError!) -> [AnyObject]! {
//        let mutablePermanentIDs:NSMutableArray! = NSMutableArray.arrayWithCapacity(array.count())
//        for managedObject:NSManagedObject! in array {
//            let managedObjectID:NSManagedObjectID! = managedObject.objectID
//            if managedObjectID.isTemporaryID() && managedObject.af_resourceIdentifier {
//                let objectID:NSManagedObjectID! = self.objectIDForEntity(managedObject.entity, withResourceIdentifier:managedObject.af_resourceIdentifier)
//                mutablePermanentIDs.addObject(objectID)
//            } else {
//                mutablePermanentIDs.addObject(managedObjectID)
//            }
//        }
//        
//        return mutablePermanentIDs as [AnyObject]!
//    }
//    
//    func executeRequest(persistentStoreRequest:NSPersistentStoreRequest!, withContext context:NSManagedObjectContext!, error:NSError!) -> AnyObject! {
//        if persistentStoreRequest.requestType == NSFetchRequestType {
//            return self.executeFetchRequest((persistentStoreRequest as! NSFetchRequest), withContext:context, error:error)
//        } else if persistentStoreRequest.requestType == NSSaveRequestType {
//            return self.executeSaveChangesRequest((persistentStoreRequest as! NSSaveChangesRequest), withContext:context, error:error)
//        } else {
//            let mutableUserInfo:NSMutableDictionary! = NSMutableDictionary.dictionary()
//            mutableUserInfo.setValue(String(format:NSLocalizedString("Unsupported NSFetchRequestResultType, %d", nil), persistentStoreRequest.requestType), forKey:NSLocalizedDescriptionKey)
//            if (error != nil) {
//                *error = NSError(domain:AFNetworkingErrorDomain, code:0, userInfo:mutableUserInfo)
//            }
//            
//            return nil
//        }
//    }
//    
//    func newValuesForObjectWithID(objectID:NSManagedObjectID!, withContext context:NSManagedObjectContext!, error:NSError!) -> NSIncrementalStoreNode! {
//        let fetchRequest:NSFetchRequest! = NSFetchRequest(entityName:objectID.entity().name())
//        fetchRequest.resultType = NSDictionaryResultType
//        fetchRequest.fetchLimit = 1
//        fetchRequest.includesSubentities = false
//        
//        let attributes:[AnyObject]! = NSEntityDescription.entityForName(fetchRequest.entityName, inManagedObjectContext:context).attributesByName().allValues()
//        let intransientAttributes:[AnyObject]! = attributes.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("isTransient == NO"))
//        fetchRequest.propertiesToFetch = intransientAttributes.valueForKeyPath("name").arrayByAddingObject(kAFIncrementalStoreLastModifiedAttributeName)
//        
//        fetchRequest.predicate = NSPredicate.predicateWithFormat("%K = %@", kAFIncrementalStoreResourceIdentifierAttributeName, AFResourceIdentifierFromReferenceObject(self.referenceObjectForObjectID(objectID)))
//        
//        var results:[AnyObject]!
//        let backingContext:NSManagedObjectContext! = self.backingManagedObjectContext()
//        backingContext.performBlockAndWait({
//            results = backingContext.executeFetchRequest(fetchRequest, error:error)
//        })
//        
//        let attributeValues:NSDictionary! = results.lastObject() ?results.lastObject(): NSDictionary.dictionary()
//        let node:NSIncrementalStoreNode! = NSIncrementalStoreNode(objectID:objectID, withValues:attributeValues, version:1)
//        
//        if self.HTTPClient.respondsToSelector(Selector("shouldFetchRemoteAttributeValuesForObjectWithID:inManagedObjectContext:")) && self.HTTPClient.shouldFetchRemoteAttributeValuesForObjectWithID(objectID, inManagedObjectContext:context) {
//            if (attributeValues != nil) {
//                let childContext:NSManagedObjectContext! = NSManagedObjectContext(concurrencyType:NSPrivateQueueConcurrencyType)
//                childContext.parentContext = context
//                childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//                
//                let request:NSMutableURLRequest! = self.HTTPClient.requestWithMethod("GET", pathForObjectWithID:objectID, withContext:context)
//                let lastModified:String! = attributeValues.object(forKey: kAFIncrementalStoreLastModifiedAttributeName) as! String
//                if (lastModified != nil) {
//                    request.setValue(lastModified, forHTTPHeaderField:"Last-Modified")
//                }
//                
//                if (request.url != nil) {
//                    if (attributeValues.value(forKey: kAFIncrementalStoreLastModifiedAttributeName) != nil) {
//                        request.setValue(attributeValues.valueForKey(kAFIncrementalStoreLastModifiedAttributeName).description(), forHTTPHeaderField:"If-Modified-Since")
//                    }
//                    
//                    let operation:AFHTTPRequestOperation! = self.HTTPClient.HTTPRequestOperationWithRequest(request, success:{ (operation:AFHTTPRequestOperation!,representation:NSDictionary!) in
//                        childContext.performBlock({
//                            let managedObject:NSManagedObject! = childContext.existingObjectWithID(objectID, error:nil)
//                            
//                            let mutableAttributeValues:NSMutableDictionary! = attributeValues.mutableCopy()
//                            mutableAttributeValues.addEntriesFromDictionary(self.HTTPClient.attributesForRepresentation(representation, ofEntity:managedObject.entity, fromResponse:operation.response))
//                            mutableAttributeValues.removeObjectForKey(kAFIncrementalStoreLastModifiedAttributeName)
//                            managedObject.valuesForKeysWithDictionary = mutableAttributeValues
//                            
//                            let backingObjectID:NSManagedObjectID! = self.objectIDForBackingObjectForEntity(objectID.entity(), withResourceIdentifier:AFResourceIdentifierFromReferenceObject(self.referenceObjectForObjectID(objectID)))
//                            let backingObject:NSManagedObject! = self.backingManagedObjectContext().existingObjectWithID(backingObjectID, error:nil)
//                            backingObject.valuesForKeysWithDictionary = mutableAttributeValues
//                            
//                            let lastModified:String! = operation.response.allHeaderFields().valueForKey("Last-Modified")
//                            if (lastModified != nil) {
//                                backingObject.setValue(lastModified, forKey:kAFIncrementalStoreLastModifiedAttributeName)
//                            }
//                            
//                            childContext.performBlockAndWait({
//                                AFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext)
//                                
//                                let backingContext:NSManagedObjectContext! = self.backingManagedObjectContext()
//                                backingContext.performBlockAndWait({
//                                    AFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext)
//                                })
//                            })
//                            
//                            self.notifyManagedObjectContext(context, aboutRequestOperation:operation, forNewValuesForObjectWithID:objectID)
//                        })
//                        
//                    }, failure:{ (operation:AFHTTPRequestOperation!,error:NSError!) in
//                        NSLog("Error: %@, %@", operation, error)
//                        self.notifyManagedObjectContext(context, aboutRequestOperation:operation, forNewValuesForObjectWithID:objectID)
//                    })
//                    
//                    self.notifyManagedObjectContext(context, aboutRequestOperation:operation, forNewValuesForObjectWithID:objectID)
//                    self.HTTPClient.enqueueHTTPRequestOperation(operation)
//                }
//            }
//        }
//        
//        return node
//    }
//    
//    func newValueForRelationship(relationship:NSRelationshipDescription!, forObjectWithID objectID:NSManagedObjectID!, withContext context:NSManagedObjectContext!, error:NSError!) -> AnyObject! {
//        if self.HTTPClient.respondsToSelector(Selector("shouldFetchRemoteValuesForRelationship:forObjectWithID:inManagedObjectContext:")) && self.HTTPClient.shouldFetchRemoteValuesForRelationship(relationship, forObjectWithID:objectID, inManagedObjectContext:context) {
//            let request:NSURLRequest! = self.HTTPClient.requestWithMethod("GET", pathForRelationship:relationship, forObjectWithID:objectID, withContext:context)
//            
//            if request.URL() && !context.existingObjectWithID(objectID, error:nil).hasChanges() {
//                let childContext:NSManagedObjectContext! = NSManagedObjectContext(concurrencyType:NSPrivateQueueConcurrencyType)
//                childContext.parentContext = context
//                childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//                
//                let operation:AFHTTPRequestOperation! = self.HTTPClient.HTTPRequestOperationWithRequest(request, success:{ (operation:AFHTTPRequestOperation!,responseObject:AnyObject!) in
//                    childContext.performBlock({
//                        let representationOrArrayOfRepresentations:AnyObject! = self.HTTPClient.representationOrArrayOfRepresentationsOfEntity(relationship.destinationEntity, fromResponseObject:responseObject)
//                        
//                        self.insertOrUpdateObjectsFromRepresentations(representationOrArrayOfRepresentations, ofEntity:relationship.destinationEntity, fromResponse:operation.response, withContext:childContext, error:nil, completionBlock:{ (managedObjects:[AnyObject]!,backingObjects:[AnyObject]!) in
//                            let managedObject:NSManagedObject! = childContext.objectWithID(objectID)
//                            
//                            let backingObjectID:NSManagedObjectID! = self.objectIDForBackingObjectForEntity(objectID.entity(), withResourceIdentifier:AFResourceIdentifierFromReferenceObject(self.referenceObjectForObjectID(objectID)))
//                            let backingObject:NSManagedObject! = (backingObjectID == nil) ? nil : self.backingManagedObjectContext().existingObjectWithID(backingObjectID, error:nil)
//                            
//                            if relationship.isToMany() {
//                                if relationship.isOrdered() {
//                                    managedObject.setValue(NSOrderedSet.orderedSetWithArray(managedObjects), forKey:relationship.name)
//                                    backingObject.setValue(NSOrderedSet.orderedSetWithArray(backingObjects), forKey:relationship.name)
//                                } else {
//                                    managedObject.setValue(NSSet.withArray = managedObjects, forKey:relationship.name)
//                                    backingObject.setValue(NSSet.withArray = backingObjects, forKey:relationship.name)
//                                }
//                            } else {
//                                managedObject.setValue(managedObjects.lastObject(), forKey:relationship.name)
//                                backingObject.setValue(backingObjects.lastObject(), forKey:relationship.name)
//                            }
//                            
//                            childContext.performBlockAndWait({
//                                AFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext)
//                                
//                                let backingContext:NSManagedObjectContext! = self.backingManagedObjectContext()
//                                backingContext.performBlockAndWait({
//                                    AFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext)
//                                })
//                            })
//                            
//                            self.notifyManagedObjectContext(context, aboutRequestOperation:operation, forNewValuesForRelationship:relationship, forObjectWithID:objectID)
//                        })
//                    })
//                }, failure:{ (operation:AFHTTPRequestOperation!,error:NSError!) in
//                    NSLog("Error: %@, %@", operation, error)
//                    self.notifyManagedObjectContext(context, aboutRequestOperation:operation, forNewValuesForRelationship:relationship, forObjectWithID:objectID)
//                })
//                
//                self.notifyManagedObjectContext(context, aboutRequestOperation:operation, forNewValuesForRelationship:relationship, forObjectWithID:objectID)
//                self.HTTPClient.enqueueHTTPRequestOperation(operation)
//            }
//        }
//        
//        let backingObjectID:NSManagedObjectID! = self.objectIDForBackingObjectForEntity(objectID.entity(), withResourceIdentifier:AFResourceIdentifierFromReferenceObject(self.referenceObjectForObjectID(objectID)))
//        let backingObject:NSManagedObject! = (backingObjectID == nil) ? nil : self.backingManagedObjectContext().existingObjectWithID(backingObjectID, error:nil)
//        
//        if (backingObject != nil) {
//            let backingRelationshipObject:AnyObject! = backingObject.valueForKeyPath(relationship.name)
//            if relationship.isToMany() {
//                let mutableObjects:NSMutableArray! = NSMutableArray.arrayWithCapacity(backingRelationshipObject.count())
//                for resourceIdentifier:String! in backingRelationshipObject.valueForKeyPath(kAFIncrementalStoreResourceIdentifierAttributeName) {
//                    let objectID:NSManagedObjectID! = self.objectIDForEntity(relationship.destinationEntity, withResourceIdentifier:resourceIdentifier)
//                    mutableObjects.addObject(objectID)
//                }
//                
//                return mutableObjects            
//            } else {
//                let resourceIdentifier:String! = backingRelationshipObject.valueForKeyPath(kAFIncrementalStoreResourceIdentifierAttributeName)
//                let objectID:NSManagedObjectID! = self.objectIDForEntity(relationship.destinationEntity, withResourceIdentifier:resourceIdentifier)
//                
//                return objectID ?objectID: NSNull.null()
//            }
//        } else {
//            if relationship.isToMany() {
//                return [AnyObject].array()
//            } else {
//                return NSNull.null()
//            }
//        }
//    }
//    
//    func managedObjectContextDidRegisterObjectsWithIDs(objectIDs:[AnyObject]!) {
//        super.managedObjectContextDidRegisterObjectsWithIDs(objectIDs)
//        
//        for objectID:NSManagedObjectID! in objectIDs {  
//            let referenceObject:AnyObject! = self.referenceObjectForObjectID(objectID)
//            if (referenceObject == nil) {
//                continue
//            }
//            
//            let objectIDsByResourceIdentifier:NSMutableDictionary! = _registeredObjectIDsByEntityNameAndNestedResourceIdentifier.objectForKey(objectID.entity.name) ?_registeredObjectIDsByEntityNameAndNestedResourceIdentifier.objectForKey(objectID.entity.name): NSMutableDictionary.dictionary()
//            objectIDsByResourceIdentifier.setObject(objectID, forKey:AFResourceIdentifierFromReferenceObject(referenceObject))
//            
//            _registeredObjectIDsByEntityNameAndNestedResourceIdentifier.setObject(objectIDsByResourceIdentifier, forKey:objectID.entity.name)
//        }
//    }
//    
//    func managedObjectContextDidUnregisterObjectsWithIDs(objectIDs:[AnyObject]!) {
//        super.managedObjectContextDidUnregisterObjectsWithIDs(objectIDs)
//        
//        for objectID:NSManagedObjectID! in objectIDs {  
//            _registeredObjectIDsByEntityNameAndNestedResourceIdentifier.objectForKey(objectID.entity.name).removeObjectForKey(AFResourceIdentifierFromReferenceObject(self.referenceObjectForObjectID(objectID)))
//        }
//    }
//}
func AFReferenceObjectFromResourceIdentifier(resourceIdentifier:String!) -> String! {
    if (resourceIdentifier == nil) {
        return nil
    }
    
    return kAFReferenceObjectPrefix.appending(resourceIdentifier)
}

func AFResourceIdentifierFromReferenceObject(referenceObject:AnyObject!) -> String! {
    if (referenceObject == nil) {
        return nil
    }
    
    let index = kAFReferenceObjectPrefix.index(kAFReferenceObjectPrefix.startIndex, offsetBy: kAFReferenceObjectPrefix.characters.count)
    
    let objectString:String! = referenceObject.description
    return objectString.hasPrefix(kAFReferenceObjectPrefix) ?
        objectString.substring(from: index) : objectString
}

func AFSaveManagedObjectContextOrThrowInternalConsistencyException(managedObjectContext:NSManagedObjectContext!) throws {
    do {
        try managedObjectContext.save()
    } catch {
        let nserror = error as NSError
        throw NSException(name: .internalInconsistencyException, reason: nserror.localizedFailureReason, userInfo: [NSUnderlyingErrorKey:nserror]) as! Error
    }
}


extension NSManagedObject {
    
    func af_resourceIdentifier() -> String! {
        let identifier:String! = objc_getAssociatedObject(self, &kAFResourceIdentifierObjectKey) as! String
        
        if (identifier == nil) {
            if (self.objectID.persistentStore is AFIncrementalStore) {
                let referenceObject:AnyObject! = (self.objectID.persistentStore as! AFIncrementalStore).referenceObject(for: self.objectID) as AnyObject
                if (referenceObject is NSString) {
                    return AFResourceIdentifierFromReferenceObject(referenceObject: referenceObject)
                }
            }
        }
        
        return identifier
    }
    
    func af_setResourceIdentifier(resourceIdentifier:String!) {
        objc_setAssociatedObject(self, &kAFResourceIdentifierObjectKey, resourceIdentifier,
                                 .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
}
