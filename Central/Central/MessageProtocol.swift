//
//  MessageProtocol.swift
//  MailBox
//
//  Created by Gregory Williams on 12/23/20.
//

import Foundation
import Sodium

enum EncryptionType: UInt8, Codable {
    typealias RawValue = UInt8
    case NotEncrypted
    case PublicPrivateKey
    case PublicPrivateKeyNonce
}

enum Command: UInt8, Codable {
    typealias RawValue = UInt8
    case Lock
    case Unlock
}

enum LockStatus: UInt8, Codable {
    typealias RawValue = UInt8
    case Locking
    case Locked
    case Unlocking
    case Unlocked
    case Error
}

enum ErrorType: UInt8, Codable {
    typealias RawValue = UInt8
    case DecodeError
    case UnknownCommand
    case CantDecrypt
}

struct MessageStruct: Codable {
    let encryptionType: EncryptionType
    var messageType: Message?
    var messageBytes: Bytes?
    
    init (encryptionType: EncryptionType, message: Message) {
        self.encryptionType = encryptionType
        self.messageType = message
        self.messageBytes = nil
    }

    init (encryptionType: EncryptionType, message: Bytes) {
        self.encryptionType = encryptionType
        self.messageBytes = message
        self.messageType = nil
    }
}

enum Message: Encodable {
    
    case SendMyPublicKey(publicKey: Box.PublicKey)
    case PhoneID(id: String)
    case Nonce(nonce: String)
    case PhoneMessage(command: Command, nonce: String)
    case LockMessage(status: LockStatus, nonce: String)
    case Error(errorType: ErrorType)
    
    enum CodingKeys: CodingKey {
      case id, command, status, key, nonce, errorType, publicKey
    }

    func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CodingKeys.self)
       
       switch self {
       case .SendMyPublicKey(let publicKey):
          try container.encode(publicKey, forKey: .publicKey)
       case .PhoneID(let id):
          try container.encode(id, forKey: .id)
       case .Nonce(let nonce):
          try container.encode(nonce, forKey: .nonce)
       case .PhoneMessage(let command, let nonce):
          try container.encode(command, forKey: .command)
          try container.encode(nonce, forKey: .nonce)
       case .LockMessage(let status, let nonce):
          try container.encode(status, forKey: .status)
          try container.encode(nonce, forKey: .nonce)
       case .Error(let errorType):
          try container.encode(errorType, forKey: .errorType)
       }
    }
}

extension Message: Decodable {
   init(from decoder: Decoder) throws {
     let container = try decoder.container(keyedBy: CodingKeys.self)
     let containerKeys = Set(container.allKeys)
     let MyPublicKeys = Set<CodingKeys>([.publicKey])
     let PhoneIDKeys = Set<CodingKeys>([.id])
     let NonceKeys = Set<CodingKeys>([.nonce])
     let PhoneMessageKeys = Set<CodingKeys>([.command, .nonce])
     let LockMessageKeys = Set<CodingKeys>([.status, .nonce])
     let ErrorKeys = Set<CodingKeys>([.errorType])
    
     switch containerKeys {
     case MyPublicKeys:
        let phoneKey = try container.decode(Box.PublicKey.self, forKey: .publicKey)
        self = .SendMyPublicKey(publicKey: phoneKey)
     case PhoneIDKeys:
        let id = try container.decode(String.self, forKey: .id)
        self = .PhoneID(id: id)
     case NonceKeys:
        let nonce = try container.decode(String.self, forKey: .nonce)
        self = .Nonce(nonce: nonce)
     case PhoneMessageKeys:
        let command = try container.decode(Command.self, forKey: .command)
        let nonce = try container.decode(String.self, forKey: .nonce)
        self = .PhoneMessage(command: command, nonce: nonce)
     case LockMessageKeys:
        let status = try container.decode(LockStatus.self, forKey: .status)
        let nonce = try container.decode(String.self, forKey: .nonce)
        self = .LockMessage(status: status, nonce: nonce)
     case ErrorKeys:
        let errorType = try container.decode(ErrorType.self, forKey: .errorType)
        self = .Error(errorType: errorType)
     default:
        fatalError("Unknown message type")
     }
   }
}

