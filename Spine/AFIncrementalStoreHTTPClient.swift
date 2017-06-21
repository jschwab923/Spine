/**
 The `AFIncrementalStoreHTTPClient` protocol defines the methods used by the HTTP client to interract with the associated web services of an `AFIncrementalStore`.
 */

import CoreData

protocol AFIncrementalStoreHTTPClient : NSObject {
    
    ///-----------------------
    /// @name Required Methods
    ///-----------------------
    
    /**
     Returns an `NSDictionary` or an `NSArray` of `NSDictionaries` containing the representations of the resources found in a response object.
     
     @discussion For example, if `GET /users` returned an `NSDictionary` with an array of users keyed on `"users"`, this method would return the keyed array. Conversely, if `GET /users/123` returned a dictionary with all of the atributes of the requested user, this method would simply return that dictionary.
     
     @param entity The entity represented
     @param responseObject The response object returned from the server.
     
     @return An `NSDictionary` with the representation or an `NSArray` of `NSDictionaries` containing the resource representations.
     */
    func representationOrArrayOfRepresentationsOfEntity(entity:NSEntityDescription!, fromResponseObject responseObject:AnyObject!) -> AnyObject!
    
    /**
     Returns an `NSDictionary` containing the representations of associated objects found within the representation of a response object, keyed by their relationship name.
     
     @discussion For example, if `GET /albums/123` returned the representation of an album, including the tracks as sub-entities, keyed under `"tracks"`, this method would return a dictionary with an array of representations for those objects, keyed under the name of the relationship used in the model (which is likely also to be `"tracks"`). Likewise, if an album also contained a representation of its artist, that dictionary would contain a dictionary representation of that artist, keyed under the name of the relationship used in the model (which is likely also to be `"artist"`).
     
     @param representation The resource representation.
     @param entity The entity for the representation.
     @param response The HTTP response for the resource request.
     
     @return An `NSDictionary` containing representations of relationships, keyed by relationship name.
     */
    func representationsForRelationshipsFromRepresentation(representation:NSDictionary!, ofEntity entity:NSEntityDescription!, fromResponse response:HTTPURLResponse!) -> NSDictionary!
    
    /**
     Returns the resource identifier for the resource whose representation of an entity came from the specified HTTP response. A resource identifier is a string that uniquely identifies a particular resource among all resource types. If new attributes come back for an existing resource identifier, the managed object associated with that resource identifier will be updated, rather than a new object being created.
     
     @discussion For example, if `GET /posts` returns a collection of posts, the resource identifier for any particular one might be its URL-safe "slug" or parameter string, or perhaps its numeric id.  For example: `/posts/123` might be a resource identifier for a particular post.
     
     @param representation The resource representation.
     @param entity The entity for the representation.
     @param response The HTTP response for the resource request.
     
     @return An `NSString` resource identifier for the resource.
     */
    func resourceIdentifierForRepresentation(representation:NSDictionary!, ofEntity entity:NSEntityDescription!, fromResponse response:HTTPURLResponse!) -> String!
    
    /**
     Returns the attributes for the managed object corresponding to the representation of an entity from the specified response. This method is used to get the attributes of the managed object from its representation returned in `-representationOrArrayOfRepresentationsFromResponseObject` or `representationsForRelationshipsFromRepresentation:ofEntity:fromResponse:`.
     
     @discussion For example, if the representation returned from `GET /products/123` had a `description` field that corresponded with the `productDescription` attribute in its Core Data model, this method would set the value of the `productDescription` key in the returned dictionary to the value of the `description` field in representation.
     
     @param representation The resource representation.
     @param entity The entity for the representation.
     @param response The HTTP response for the resource request.
     
     @return An `NSDictionary` containing the attributes for a managed object.
     */
    func attributesForRepresentation(representation:NSDictionary!, ofEntity entity:NSEntityDescription!, fromResponse response:HTTPURLResponse!) -> NSDictionary!
    
    /**
     Returns a URL request object for the specified fetch request within a particular managed object context.
     
     @discussion For example, if the fetch request specified the `User` entity, this method might return an `NSURLRequest` with `GET /users` if the web service was RESTful, `POST /endpoint?method=users.getAll` for an RPC-style system, or a request with an XML envelope body for a SOAP webservice.
     
     @param fetchRequest The fetch request to translate into a URL request.
     @param context The managed object context executing the fetch request.
     
     @return An `NSURLRequest` object corresponding to the specified fetch request.
     */
    func requestForFetchRequest(fetchRequest:NSFetchRequest!, withContext context:NSManagedObjectContext!) -> NSMutableURLRequest!
    
    /**
     Returns a URL request object with a given HTTP method for a particular managed object. This method is used in `AFIncrementalStore -newValuesForObjectWithID:withContext:error`.
     
     @discussion For example, if a `User` managed object were to be refreshed, this method might return a `GET /users/123` request.
     
     @param method The HTTP method of the request.
     @param objectID The object ID for the specified managed object.
     @param context The managed object context for the managed object.
     
     @return An `NSURLRequest` object with the provided HTTP method for the resource corresponding to the managed object.
     */
    func requestWithMethod(method:String!, pathForObjectWithID objectID:NSManagedObjectID!, withContext context:NSManagedObjectContext!) -> NSMutableURLRequest!
    
    /**
     Returns a URL request object with a given HTTP method for a particular relationship of a given managed object. This method is used in `AFIncrementalStore -newValueForRelationship:forObjectWithID:withContext:error:`.
     
     @discussion For example, if a `Department` managed object was attempting to fulfill a fault on the `employees` relationship, this method might return `GET /departments/sales/employees`.
     
     @param method The HTTP method of the request.
     @param relationship The relationship of the specifified managed object
     @param objectID The object ID for the specified managed object.
     @param context The managed object context for the managed object.
     
     @return An `NSURLRequest` object with the provided HTTP method for the resource or resoures corresponding to the relationship of the managed object.
     
     */
    func requestWithMethod(method:String!, pathForRelationship relationship:NSRelationshipDescription!, forObjectWithID objectID:NSManagedObjectID!, withContext context:NSManagedObjectContext!) -> NSMutableURLRequest!
    
    
    ///-----------------------
    /// @name Optional Methods
    ///-----------------------
    
    /**
     Returns the attributes representation of an entity from the specified managed object. This method is used to get the attributes of the representation from its managed object.
     
     @discussion For example, if the representation sent to `POST /products` or `PUT /products/123` had a `description` field that corresponded with the `productDescription` attribute in its Core Data model, this method would set the value of the `productDescription` field to the value of the `description` key in representation/dictionary.
     
     @param attributes The resource representation.
     @param managedObject The `NSManagedObject` for the representation.
     
     @return An `NSDictionary` containing the attributes for a representation, based on the given managed object.
     */
    optional func representationOfAttributes(attributes:NSDictionary!, ofManagedObject managedObject:NSManagedObject!) -> NSDictionary!
    
    /**
     
     */
    optional func requestForInsertedObject(insertedObject:NSManagedObject!) -> NSMutableURLRequest!
    
    /**
     
     */
    optional func requestForUpdatedObject(updatedObject:NSManagedObject!) -> NSMutableURLRequest!
    
    /**
     
     */
    optional func requestForDeletedObject(deletedObject:NSManagedObject!) -> NSMutableURLRequest!
    
    /**
     Returns whether the client should fetch remote attribute values for a particular managed object. This method is consulted when a managed object faults on an attribute, and will call `-requestWithMethod:pathForObjectWithID:withContext:` if `YES`.
     
     @param objectID The object ID for the specified managed object.
     @param context The managed object context for the managed object.
     
     @return `YES` if an HTTP request should be made, otherwise `NO.
     */
    optional func shouldFetchRemoteAttributeValuesForObjectWithID(objectID:NSManagedObjectID!, inManagedObjectContext context:NSManagedObjectContext!) -> Bool
    
    /**
     Returns whether the client should fetch remote relationship values for a particular managed object. This method is consulted when a managed object faults on a particular relationship, and will call `-requestWithMethod:pathForRelationship:forObjectWithID:withContext:` if `YES`.
     
     @param relationship The relationship of the specifified managed object
     @param objectID The object ID for the specified managed object.
     @param context The managed object context for the managed object.
     
     @return `YES` if an HTTP request should be made, otherwise `NO.
     */
    optional func shouldFetchRemoteValuesForRelationship(relationship:NSRelationshipDescription!, forObjectWithID objectID:NSManagedObjectID!, inManagedObjectContext context:NSManagedObjectContext!) -> Bool
    
}
