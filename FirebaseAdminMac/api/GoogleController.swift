//
//  GoogleController.swift
//  FirebaseAdminMac
//
//  Created by Kumar Shivang on 13/04/20.
//  Copyright © 2020 Kumar Shivang. All rights reserved.
//

import Foundation
import Combine

// Firebase api

func projectsPagePublisher(nextPageToken: String?) -> AnyPublisher<([FirebaseProject], String?), Never> {
    Future<([FirebaseProject], String?), Error> { promise in
        getProjects(token: accessToken, nextPageToken: nextPageToken) { error, projects, token in
            if let projects = projects {
                promise(.success((projects, token)))
            } else if let error  = error {
                promise(.failure(error))
            }
        }
    }.mapError({ (error) -> Error in
        print("error: \(error)")
        return error
    })
//    .retry(Int.max)
    .replaceError(with: ([], nextPageToken))
    .eraseToAnyPublisher()
}

func getProjects(token: String, nextPageToken: String?, _ onResponse: @escaping (_: Error?, _: [FirebaseProject]?, _ nextPageToken: String?) -> Void) {
    var parameter: [String: String]? = nil
    if let nextPageToken = nextPageToken {
        parameter = ["pageToken": nextPageToken]
    }
    getFirebaseRequest(apiSurfix: "projects", token: token, parameter: parameter) { (error, statusCode, jsonResponse) in
        guard let jsonResponse = jsonResponse, error == nil else {
            onResponse(error, nil, nextPageToken)
            return
        }
        guard let json = jsonResponse as? [String: Any] else {
            onResponse(nil, nil, nextPageToken)
            return
        }
        guard let firebaseProjectsDic = json["results"] as? [[String: Any]],
            firebaseProjectsDic.count > 0 else {
                print("Error parsing documents")
                onResponse(nil, nil, nextPageToken)
                return
        }
        var firebaseProjects = [FirebaseProject]()
        for firebaseProjectDic in firebaseProjectsDic {
            firebaseProjects.append(FirebaseProject(firebaseProjectDic))
        }
        if let nextPageToken = json["nextPageToken"] as? String {
            onResponse(nil, firebaseProjects, nextPageToken)
        } else {
            onResponse(nil, firebaseProjects, nil)
        }
    }
}


// Not functioning
func postAddProject(token: String, projectId: String, timeZone: String, regionCode: String, locationId: String, _ onResponse: @escaping (_: Error?, _: Int, _: Any?) -> Void) {
    let bodyParameters = [
        "timeZone": timeZone,
        "regionCode": regionCode,
        "locationId": locationId,
    ]
    postFirebaseRequest(apiSurfix: "projects/\(projectId):addFirebase", token: token, bodyParameters: bodyParameters) { (error, status, jsonResponse) in
        onResponse(error, status, jsonResponse)
    }
}


// Firebase high level api

func getFirebaseRequest(apiSurfix: String, token: String, parameter: [String: String]?, onRequestComplete: @escaping (_: Error?, _: Int, _: Any?) -> Void) {
    getGoogleApiRequest(googleApi: .FIREBASE, apiVersion: .v1_beta1, apiSurfix: apiSurfix, token: token, parameter: parameter, onRequestComplete: onRequestComplete)
}

func postFirebaseRequest(apiSurfix: String, token: String, queryParameters: [String: String]? = nil, bodyParameters: [String: String]? = nil,onRequestComplete: @escaping (_: Error?, _: Int, _: Any?) -> Void) {
    postGoogleApiRequest(googleApi: .FIREBASE, apiVersion: .v1_beta1, apiSurfix: apiSurfix, token: token, queryParameters: queryParameters, bodyParameters: bodyParameters, onRequestComplete: onRequestComplete)
}

// Firestore api

func postCollectionIDs(projectID: String, token: String, documentPath: String, nextPageToken: String?, _ onResponse: @escaping (_: Error?, _: [String]?, _ nextPageToken: String?) -> Void) {
    var parameter: [String: String]? = nil
    if let nextPageToken = nextPageToken {
        parameter = ["pageToken": nextPageToken]
    }
    postFirestoreRequest(projectID: projectID, apiSurfix: "documents/\(documentPath):listCollectionIds", token: token, queryParameters: parameter) { (error, statusCode, jsonResponse) in
        guard let jsonResponse = jsonResponse, error == nil else {
            onResponse(error, nil, nextPageToken)
            return
        }
        guard let json = jsonResponse as? [String: Any] else {
            onResponse(nil, nil, nextPageToken)
            return
        }
        guard let collectionIDs = json["collectionIds"] as? [String],
            collectionIDs.count > 0 else {
                print("Error parsing documents")
                onResponse(nil, nil, nextPageToken)
                return
        }
        if let nextPageToken = json["nextPageToken"] as? String {
            onResponse(nil, collectionIDs, nextPageToken)
        } else {
            onResponse(nil, collectionIDs, nil)
        }
    }
}

func getDocuments(projectID: String, token: String, collectionPath: String, nextPageToken: String?, _ onResponse: @escaping (_: Error?, _: [Document]?, _ nextPageToken: String?) -> Void) {
    var parameter: [String: String]? = nil
    if let nextPageToken = nextPageToken {
        parameter = ["pageToken": nextPageToken]
    }
    getFirestoreRequest(projectID: projectID, apiSurfix: "documents/\(collectionPath)", token: token, parameter: parameter) { (error, statusCode, jsonResponse) in
        guard let jsonResponse = jsonResponse, error == nil else {
            onResponse(error, nil, nextPageToken)
            return
        }
        
        guard let json = jsonResponse as? [String: Any] else {
            onResponse(nil, nil, nextPageToken)
            return
        }
        guard let documentsJson = json["documents"] as? [[String: Any]],
            documentsJson.count > 0 else {
                print("Error parsing documents")
                onResponse(nil, nil, nextPageToken)
                return
        }
        let documents = Document.parseDocuments(documentsJson)
        if let nextPageToken = json["nextPageToken"] as? String {
            onResponse(nil, documents, nextPageToken)
        } else {
            onResponse(nil, documents, nil)
        }
    }
}

// Firestore high level api

func getFirestoreRequest(projectID: String, apiSurfix: String, token: String, parameter: [String: String]?, onRequestComplete: @escaping (_: Error?, _: Int, _: Any?) -> Void) {
    getGoogleApiRequest(googleApi: .FIRESTORE, apiVersion: .v1, apiSurfix: "projects/\(projectID)/databases/(default)/\(apiSurfix)", token: token, parameter: parameter, onRequestComplete: onRequestComplete)
}

func postFirestoreRequest(projectID: String, apiSurfix: String, token: String, queryParameters: [String: String]? = nil,  bodyParameters: [String: String]? = nil, onRequestComplete: @escaping (_: Error?, _: Int, _: Any?) -> Void) {
    postGoogleApiRequest(googleApi: .FIRESTORE, apiVersion: .v1, apiSurfix: "projects/\(projectID)/databases/(default)/\(apiSurfix)", token: token, queryParameters: queryParameters, bodyParameters: bodyParameters, onRequestComplete: onRequestComplete)
}

// Google high level api

func getGoogleApiRequest(googleApi: GoogleApi, apiVersion: GoogleApiVersion, apiSurfix: String, token: String, parameter: [String: String]?, onRequestComplete: @escaping (_: Error?, _: Int, _: Any?) -> Void) {
    let url = "https://\(googleApi.rawValue).googleapis.com/\(apiVersion.rawValue)/\(apiSurfix)"
    getRequest(on: url, with: parameter, token: token, onRequestComplete)
}

func postGoogleApiRequest(googleApi: GoogleApi, apiVersion: GoogleApiVersion, apiSurfix: String, token: String, queryParameters: [String: String]? = nil, bodyParameters: [String: String]? = nil, onRequestComplete: @escaping (_: Error?, _: Int, _: Any?) -> Void) {
    let url = "https://\(googleApi.rawValue).googleapis.com/\(apiVersion.rawValue)/\(apiSurfix)"
    postRequest(on: url, queryParameters: queryParameters, bodyParameters: bodyParameters, token: token, onRequestComplete)
}

// Request high level api

func getRequest(on url: String, with parameters: [String: String]?, token: String?, _ onRequestComplete: @escaping (_ : Error?, _ : Int, _ : Data?) -> Void) {
    request(type: .GET, on: url, queryParameters: parameters, token: token, onRequestComplete)
}

func postRequest(on url: String, queryParameters: [String: String]? = nil, bodyParameters: [String: String]? = nil, token: String?, _ onRequestComplete: @escaping (_ : Error?, _ : Int, _ : Data?) -> Void) {
    request(type: .POST, on: url, queryParameters: queryParameters, bodyParameters: bodyParameters, token: token, onRequestComplete)
}

func getRequest(on url: String, with parameters: [String: String]?, token: String?, _ onRequestComplete: @escaping (_ : Error?, _ : Int, _ : Any?) -> Void) {
    request(type: .GET, on: url, queryParameters: parameters, token: token) { (error, statusCode, data) in
        if let data = data {
            let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: [])
            onRequestComplete(error, statusCode, jsonResponse)
        } else {
            onRequestComplete(error, statusCode, nil)
        }
    }
}

func postRequest(on url: String, queryParameters: [String: String]? = nil, bodyParameters: [String: String]? = nil, token: String?, _ onRequestComplete: @escaping (_ : Error?, _ : Int, _ : Any?) -> Void) {
    request(type: .POST, on: url, queryParameters: queryParameters, bodyParameters: bodyParameters, token: token) { (error, statusCode, data) in
        if let data = data {
            let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: [])
            onRequestComplete(error, statusCode, jsonResponse)
        } else {
            onRequestComplete(nil, statusCode, nil)
        }
    }
}

func request(type queryType: RequestType, on url: String, queryParameters: [String: String]? = nil, bodyParameters: [String: String]? = nil, token: String?, _ onRequestComplete: @escaping (_ : Error?, _ : Int, _ : Data?) -> Void) {
    var urlComponent = URLComponents(string: url)
    if let parameters = queryParameters {
        urlComponent?.queryItems = parameters.map({ (key, value) in
            URLQueryItem(name: key, value: value)
        })
    }
    var request = URLRequest(url: urlComponent!.url!)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    if let token = token {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    if let bodyParameters = bodyParameters,
        let jsonData = try? JSONSerialization.data(withJSONObject: bodyParameters) {
        request.httpBody = jsonData
    }

    request.httpMethod = queryType.rawValue
    URLSession.shared.dataTask(with: request) { data, response, error in
        var statusCode = 404
        guard let data = data, error == nil else {
            onRequestComplete(error, statusCode, nil)
            return
        }
        if let httpStatus = response as? HTTPURLResponse {
            statusCode = httpStatus.statusCode
        }
        onRequestComplete(nil, statusCode, data)
    }.resume()
}

enum RequestType: String {
    case GET = "GET", POST = "POST"
    static let allValues = [GET, POST]
}

enum GoogleApiVersion: String {
    case v1 = "v1", v1_beta1 = "v1beta1", v1_beta2 = "v1beta2"
    static let allValues = [v1, v1_beta1, v1_beta2]
}

enum GoogleApi: String {
    case FIRESTORE = "firestore", FIREBASE = "firebase"
    static let allValues = [FIRESTORE, FIREBASE]
}
