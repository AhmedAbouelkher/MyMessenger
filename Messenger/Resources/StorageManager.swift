//
//  StorageManager.swift
//  Messenger
//
//  Created by Ahmed on 12/29/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import Foundation
import FirebaseStorage

typealias ProfilePictureProcessCompletion = (Result<String, Error>) -> Void
typealias MediaProcessCompletion = (Result<URL, Error>) -> Void

final class StorageManager {
    static var shared = StorageManager()
    
    private let storage = Storage.storage().reference()
       
    
    /// Use to upload user profile image to storage and returnes a completion with an error and storage Url
    public func uploadProfilePicture(with data: Data, fileName path: String, complestion: @escaping ProfilePictureProcessCompletion) {
        let storageRef = storage.child("images/\(path)")
        storageRef.putData(data, metadata: nil) { _, error in
            guard error == nil else {
                complestion(.failure(StorageError.failedToUploadMedia))
                return
            }
            storageRef.downloadURL { (url, error) in
                guard let downloadURL = url, error == nil else {
                    complestion(.failure(StorageError.failedToDownloadMedia))
                    return
                }
                complestion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    ///Uploads Photo chat message
    public func uploadMessageImage(with data: Data, fileName path: String, completion: @escaping MediaProcessCompletion) {
        let storageRef = storage.child("chat_images/\(path)")
        storageRef.putData(data, metadata: nil) { (storageMetadata, error) in
            guard error == nil else {
                completion(.failure(StorageError.failedToUploadMedia))
                return
            }
            storageRef.downloadURL { (url, error) in
                guard let url = url, error == nil else {
                    completion(.failure(StorageError.failedToDownloadMedia))
                    return
                }
                completion(.success(url))
            }
        }
    }
    
    ///Uploads Video chat message
    public func uploadMessageVideo(with fileUrl: URL, fileName path: String, completion: @escaping MediaProcessCompletion) {
        let storageRef = storage.child("chat_videos/\(path)")
        storageRef.putFile(from: fileUrl, metadata: nil) { _, error in
            guard error == nil else {
                completion(.failure(StorageError.failedToUploadMedia))
                return
            }
            storageRef.downloadURL { (url, error) in
                guard let url = url, error == nil else {
                    completion(.failure(StorageError.failedToDownloadMedia))
                    return
                }
                completion(.success(url))
            }
        }
    }
    
    ///Downloads image at `path`
    public func downloadURL(for path: String, completion: @escaping MediaProcessCompletion) {
        let reference = storage.child(path)
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageError.failedToDownloadMedia))
                return
            }
            completion(.success(url))
        })
    }
    
    public enum StorageError: Error {
        case failedToUploadMedia
        case failedToDownloadMedia
    }
}
