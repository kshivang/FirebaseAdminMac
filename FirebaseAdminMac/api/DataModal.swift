//
//  DataModal.swift
//  FirestoreAdmin
//
//  Created by Kumar Shivang on 01/02/19.
//  Copyright © 2019 Kumar Shivang. All rights reserved.
//

import Foundation

struct DefaultResources {
    var hostingSite: String?
    var realtimeDatabaseInstance: String?
    var storageBucket: String?
    var locationId: String?
    
    var dictionary: [String: String?] {
        return [
            "hostingSite": hostingSite,
            "realtimeDatabaseInstance": realtimeDatabaseInstance,
            "storageBucket": storageBucket,
            "locationId": locationId,
        ]
    }
}

extension DefaultResources {
    init(_ dictionary: [String: Any]) {
        hostingSite = dictionary["hostingSite"] as? String
        realtimeDatabaseInstance = dictionary["realtimeDatabaseInstance"] as? String
        storageBucket = dictionary["storageBucket"] as? String
        locationId = dictionary["locationId"] as? String
    }
}

struct FirebaseProject: Hashable {
    static func == (lhs: FirebaseProject, rhs: FirebaseProject) -> Bool {
        lhs.projectId == rhs.projectId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(projectId)
    }
    
    var name: String
    var projectId: String
    var projectNumber: String
    var displayName: String
    var resources: DefaultResources
    
    var dictionary: [String: Any] {
        return [
            "name": name,
            "projectId": projectId,
            "projectNumber": projectNumber,
            "displayName": displayName,
            "resources": resources.dictionary,
        ]
    }
}

extension FirebaseProject {
    init(_ dictionary: [
        String: Any]) {
        name = dictionary["name"] as! String
        projectId = dictionary["projectId"] as! String
        projectNumber = dictionary["projectNumber"] as! String
        displayName = dictionary["displayName"] as! String
        resources = DefaultResources(dictionary["resources"] as! [String: Any])
    }
}


struct DataField {
    var key: String = ""
    var type: String = ""
    var value: String = ""
    var rawValue: Any? = nil
    
    var dictionary: [String: Any] {
        return [ key: [ type: rawValue ] ]
    }
    
    var childs: [DataField] {
        if type == "mapValue" {
            if let dictionary = rawValue as? [String: Any?],
                let dataFields = dictionary["fields"] as? [String: Any?] {
                return DataField.parseDataField(dataFields)
            }
        } else if type == "arrayValue" {
            if let dictionary = rawValue as? [String: Any?],
                let dataFields = dictionary["values"] as? [[String: Any?]] {
                var array = [DataField]()
                var key = 0
                for datafield in dataFields {
                    array.append(DataField("\(key)", datafield))
                    key = key + 1
                }
                return array
            }
        }
        return [DataField]()
    }
}

extension DataField {
    init(_ key: String, _ field: [String: Any?]) {
        self.key = key
        for (fieldType, fieldValue) in field {
            type  = fieldType
            rawValue = fieldValue
            switch fieldType {
            case "nullValue":
                value = "null"
                break
            case "booleanValue",
                 "integerValue",
                 "doubleValue",
                 "timestampValue",
                 "stringValue",
                 "bytesValue",
                 "referenceValue",
                 "geoPointValue":
                value = "\(fieldValue!)"
                break
            case "arrayValue":
                value = "Array"
                break
            case "mapValue":
                value = "Map"
                break
            default:
                break
            }
        }
    }
    
    static func parseDataField(_ fields: [String: Any?]) -> [DataField] {
        var dataFields = [DataField]()
        for (key, value) in fields {
            if let value = value as? [String: Any] {
                dataFields.append(DataField(key, value))
            }
        }
        return dataFields
    }
    
    static func dataFieldsDictionary(fields: [DataField]) -> [String: Any] {
        var dictionary = [String: Any]()
        for field in fields {
            dictionary += field.dictionary
        }
        return dictionary
    }
}

func += <K, V> (left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left[k] = v
    }
}

struct Document {
    var name: String
    var fields = [DataField]()
    var createdTime: String = ""
    var updatedTime: String = ""
    
    var dictionary: [String: Any] {
        return [
            "name": name,
            "fields": DataField.dataFieldsDictionary(fields: fields),
        ]
    }
    
    var id: String {
        let split = name.split(separator: "/")
        return String(split.last!)
    }
    
    var path: String {
        if name.isEmpty {
            return ""
        }
        var split = name.split(separator: "/")
        split.removeFirst(5)
        return split.joined(separator: "/")
    }
}

extension Document {
    init(_ dictionary: [String: Any]) {
        name = dictionary["name"] as! String
        createdTime = (dictionary["createdTime"] as? String) ?? ""
        updatedTime = (dictionary["updatedTime"] as? String) ?? ""
        if let dataFields = dictionary["fields"] as? [String: Any] {
            fields = DataField.parseDataField(dataFields)
        }
    }
    
    static func parseDocuments(_ documentsJson: [[String: Any]]) -> [Document] {
        var documents = [Document]()
        for documentJson in documentsJson {
            documents.append(Document(documentJson))
        }
        return documents
    }
}

