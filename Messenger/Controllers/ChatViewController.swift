//
//  ChatViewController.swift
//  Messenger
//
//  Created by Ahmed on 12/28/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import JGProgressHUD
import FirebaseAuth
import SDWebImage
import CoreLocation

class ChatViewController: MessagesViewController {
    
    private let prgressIndicator = JGProgressHUD(style: .dark)
    
    private let noMessagesLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textAlignment = .center
        label.textColor = .gray
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 19, weight: .medium)
        return label
    }()
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    
    private var messages = [Message]()
    private let otherUser: Reciver
    private let chat: Chat?
    private var senderImageUrl: URL?
    private var otherImageUrl: URL?
    
    
    private var scroll = true
    
    private var sender: Sender? {
        guard  let email = UserDefaults.standard.value(forKey: "email") as? String,
        let currentUser =  Auth.auth().currentUser,
        let userName = currentUser.displayName else {
            print("FAILED TO GET CURRENT USER")
            return nil
        }
        let senderId = DatabaseManager.createDataBaseEmail(with: email)
        return Sender(senderId: senderId, displayName: userName)
    }
    
    init(with reciver: Reciver, in chat: Chat?) {
        self.otherUser = reciver
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        view.addSubview(noMessagesLabel)
        configureAttachments()
        messageInputBar.inputTextView.autocapitalizationType = .none
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        loadChatMessages()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        noMessagesLabel.text = "Start Chating with \(otherUser.displayName)"
        
        noMessagesLabel.frame = CGRect(x: (view.width - 200) / 2,
                                           y: (view.height - 50) / 2,
                                           width: 200,
                                           height: 50)
    }
    
    private func loadChatMessages() {
        DatabaseManager.shared.loadChat(with: self.otherUser, in: self.chat) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    self.messagesCollectionView.isHidden = true
                    self.noMessagesLabel.isHidden = false
                    return
                }
                self.messages = messages
                DispatchQueue.main.async {
                    self.messagesCollectionView.isHidden = false
                    self.noMessagesLabel.isHidden = true
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}


extension ChatViewController : InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let messageId = createMessageId(),
              let currentSender = self.sender else {
            //Invalid Data to be sent
            print("Invalid Data to be sent")
            return
        }
        let date = Date()
        
        /*
         Reciver Data
         */
        
        let reviver = Reciver(
            senderId: self.otherUser.senderId,
            displayName: self.otherUser.displayName
        )
    
        /*
         Sending Message
         */
        
        let message = Message(
            sender: currentSender,
            messageId: messageId,
            sentDate: date,
            kind: .text(text),
            timeStamp: date.timeIntervalSince1970
        )
        
        DatabaseManager.shared.chat(with: reviver, send: message, in: self.chat) { [weak self] success in
            if success {
                print("Message Sent Successfuly")
                self?.messageInputBar.inputTextView.text = ""
            } else {
                print("Message Sending Failed")
            }
        }
    }
    
    private func createMessageId() -> String? {
        // senderEmail, otherUesrEmail, date, randomInt
        guard let emailId = DatabaseManager.getCurrentUserID else {
            print("Created Message ID Failed")
            return nil
        }
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(emailId)@\(self.otherUser.senderId)@\(dateString)"
        return newIdentifier
    }
}

//MARK: - CollectionView Delegates
extension ChatViewController : MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate {
    
    func currentSender() -> SenderType {
        if let sender = self.sender {
            return sender
        }
        fatalError("##Self Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    // MARK: - MessagesDisplayDelegate
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let message = message as! Message
        switch message.kind {
        case .photo(let media):
            if let url = media.url { imageView.sd_setImage(with: url, completed: nil) }
        default:
            break
        }
    }
    
    // MARK: - MessageCellDelegate
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let location):
            let vc = LocationPickerViewController(coordinates: location.location.coordinate)
            vc.title = "Location"
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if message.sender.senderId == currentSender().senderId {
            return .systemBlue
        }
        return .secondarySystemBackground
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        
        print("Current Sender: \(sender.senderId == self.sender?.senderId )", " | " , "Sender id: \(sender.senderId)")
        if sender.senderId == self.sender?.senderId {
            
            if let userUrl = self.senderImageUrl {
                avatarView.sd_setImage(with: userUrl, completed: nil)
            } else {
                guard let currentSender = self.sender else {
                    return
                }
                StorageManager.shared.downloadURL(for: currentSender.imageURL) { [weak self] result in
                    guard let self = self else {return}
                    switch result {
                    case .success(let url):
                        self.senderImageUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("Error: \(error)")
                    }
                }
            }
            
            
        } else {
            
            if let userUrl = self.otherImageUrl {
                avatarView.sd_setImage(with: userUrl, completed: nil)
            } else {
                StorageManager.shared.downloadURL(for: otherUser.imageURL) { [weak self] result in
                    guard let self = self else {return}
                    switch result {
                    case .success(let url):
                        self.senderImageUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("Error: \(error)")
                    }
                }
            }
            
        }
    }
}

//MARK: - Base Attachment Configs
extension ChatViewController {
    private func configureAttachments() {
        let button = InputBarSendButton()
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.onTouchUpInside { [weak self] _ in
            self?.presentAttachmentActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentAttachmentActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionsheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self]  _ in
            self?.presentVideoInputActionsheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {  _ in

        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: {  [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(actionSheet, animated: true)
    }
}

//MARK: - Attachments Configs
extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //Photo Picking
    private func presentPhotoInputActionsheet() {
        let actionSheet = UIAlertController(
            title: "Attach Photo",
            message: "Where would you like to attach a photo from?",
            preferredStyle: .actionSheet
        )
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            self?.presentImagePicker(with: .camera)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            self?.presentImagePicker(with: .photoLibrary)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentImagePicker(with sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = sourceType
        present(picker, animated: true, completion: nil)
    }
    
    
    //Video Picking
    private func presentVideoInputActionsheet() {
        let actionSheet = UIAlertController(
            title: "Attach Video",
            message: "Where would you like to attach a video from?",
            preferredStyle: .actionSheet
        )
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            self?.presentVideoPicker(with: .camera)
        }))
        actionSheet.addAction(UIAlertAction(title: "Video Library", style: .default, handler: { [weak self] _ in
            self?.presentVideoPicker(with: .photoLibrary)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoPicker(with sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = sourceType
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeMedium
        present(picker, animated: true, completion: nil)
    }
    
    
    //Delegate Functions
    
    private enum messageType {
        case video
        case photo
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let messageId = createMessageId(),
              let currentSender = self.sender else {
            return
        }
        
        if let rawMedia = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
           let imageData = rawMedia.jpeg(.lowest) {
            
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            StorageManager.shared.uploadMessageImage(with: imageData, fileName: fileName) { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let url):
                    print("Downloaded Image: \(url.absoluteString)")
                    self.sendMediaInChat(with: url, messageId: messageId, sender: currentSender)
                case .failure(let error):
                    print("Error while uploading image \(error)")
                }
            }
        } else if let rawMedia = info[.mediaURL] as? URL {
//            print("Vidoe File Size: \(getFileSize(rawMedia.path))")
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            StorageManager.shared.uploadMessageVideo(with: rawMedia, fileName: fileName) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let url):
                    print("Downloaded Video: \(url.absoluteString)")
                    self.sendMediaInChat(with: url, messageId: messageId, sender: currentSender, type: .video)
                case .failure(let error):
                    print("Error while uploading video \(error)")
                }
            }
        } else {
            print("Invalid Picked Media")
        }
    }
    
    private func sendMediaInChat(with url: URL, messageId: String, sender: Sender, type: messageType = .photo) {
        guard let placeholder = UIImage(systemName: "plus") else {
            print("Placeholder image has an Error")
            return
        }
        let date = Date()
        let reviver = Reciver(
            senderId: self.otherUser.senderId,
            displayName: self.otherUser.displayName
        )
        let media = Media(
            url: url,
            image: nil,
            placeholderImage: placeholder,
            size: .zero
        )
        
        var mediaKind: MessageKind?
        
        switch type {
        case .video:
            mediaKind = .video(media)
        case .photo:
            mediaKind = .photo(media)
        }
        
        let message = Message(
            sender: sender,
            messageId: messageId,
            sentDate: date,
            kind: mediaKind!,
            timeStamp: date.timeIntervalSince1970
        )
        
        DatabaseManager.shared.chat(with: reviver, send: message, in: self.chat) { success in
            if success {
                print("Image Message Sent Successfuly")
            } else {
                print("Image Message Sending Failed")
            }
        }
    }
    
    private func getFileSize(_ filePath: String) -> UInt64? {
        var fileSize : UInt64

        do {
            //return [FileAttributeKey : Any]
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            fileSize = attr[FileAttributeKey.size] as! UInt64

            //if you convert to NSDictionary, you can get file size old way as well.
            let dict = attr as NSDictionary
            fileSize = dict.fileSize()
            return fileSize
        } catch {
            print("Error: \(error)")
            return nil
        }
    }
}

//MARK: - Location Picker and Sender

extension ChatViewController {
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.completion = { [weak self] coordinates in
            print("coordinates: \(coordinates)")
            self?.sendLocation(coordinates)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func sendLocation(_ coordinates: CLLocationCoordinate2D) {
        
        guard let messageId = createMessageId(),
              let currentSender = self.sender else {
            return
        }
        
        
        let date = Date()
        
        let reviver = Reciver(
            senderId: self.otherUser.senderId,
            displayName: self.otherUser.displayName
        )
        let location = Location(
            location: CLLocation(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            ),
            size: .zero
        )
        
        let message = Message(
            sender: currentSender,
            messageId: messageId,
            sentDate: date,
            kind: .location(location),
            timeStamp: date.timeIntervalSince1970
        )
        
        DatabaseManager.shared.chat(with: reviver, send: message, in: self.chat) { success in
            if success {
                print("Location Message Sent Successfuly")
            } else {
                print("Location Message Sending Failed")
            }
        }
    }
    
}


//Reduse image size
extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}
