//
//  StorageManager.swift
//  Messenger
//
//  Created by Ahmed on 12/29/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static var shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias PictureProcessCompletion = (Result<String, Error>) -> Void
    
    
    /// Use to upload user profile image to storage and returnes a completion with an error and storage Url
    public func uploadProfilePicture(with data: Data, fileName path: String, complestion: @escaping PictureProcessCompletion) {
        let storageRef = storage.child("images/\(path)")
        storageRef.putData(data, metadata: nil) { (storageMetadata, error) in
            guard error == nil else {
                complestion(.failure(StorageError.failedToUploadImage))
                return
            }
            storageRef.downloadURL { (url, error) in
                guard let downloadURL = url, error == nil else {
                    complestion(.failure(StorageError.failedToDownloadImage))
                    return
                }
                complestion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    public func downloadURL(for path: String, completion: @escaping PictureProcessCompletion) {
        let reference = storage.child(path)
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageError.failedToDownloadImage))
                return
            }
            completion(.success(url.absoluteString))
        })
    }
    
    public enum StorageError: Error {
        case failedToUploadImage
        case failedToDownloadImage
    }
}
