//
//  PublicPrivateKeyEncryption.swift
//  Central
//
//  Created by Gregory Williams on 12/23/20.
//

import Foundation
import Sodium

let sodium = Sodium()

func encryptMessage(message: MessageStruct, publicKey: Box.PublicKey, secretKey: Box.SecretKey, nonce: String) -> Data? {
        var internalMsg = Bytes()
        switch message.encryptionType {
        case .NotEncrypted:
            if let msgData = try? JSONEncoder().encode(message) {
                return msgData
            }
        case .PublicPrivateKey, .PublicPrivateKeyNonce:
            let msg = try? PropertyListEncoder().encode(message.messageType)
            internalMsg =
                sodium.box.seal(message: Bytes(msg!),
                                recipientPublicKey: publicKey,
                                senderSecretKey: secretKey)!
        }
        if let msgData = try? PropertyListEncoder().encode(MessageStruct(encryptionType: .PublicPrivateKey, message: internalMsg)) {
            return msgData
        }

    return nil
}

func decryptMessage(encryptedMessage: Data, publicKey: Box.PublicKey, secretKey: Box.SecretKey, nonce: String) -> Message {

    if let msg = try? JSONDecoder().decode(MessageStruct.self, from: encryptedMessage) {
        return (msg.messageType) ?? Message.Error(errorType: .DecodeError)
    } else {
        let msg = try? PropertyListDecoder().decode(MessageStruct.self, from: encryptedMessage)
        switch msg?.encryptionType {
        case .PublicPrivateKey, .PublicPrivateKeyNonce:
            let decryptedMsg = sodium.box.open(nonceAndAuthenticatedCipherText: msg!.messageBytes!,
                                senderPublicKey: publicKey,
                                recipientSecretKey: secretKey)
            if let decryptedMsg = decryptedMsg, let msg = try? PropertyListDecoder().decode(Message.self, from: Data(decryptedMsg)) {
                return msg
            } else {
                return Message.Error(errorType: .Intruder)
            }
        default:
            return Message.Error(errorType: .CantDecrypt)
        }
    }
    return Message.Error(errorType: .DecodeError)
}
