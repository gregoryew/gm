//
//  ViewController.swift
//  MailBox
//
//  Created by Gregory Williams on 12/23/20.
//

import UIKit
import CoreBluetooth
import os
import Sodium

struct MailboxService {
    static let serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
    static let characteristicUUID = CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4")
    static let mailboxID = CBUUID(string: "11111111-DB05-467E-8757-72F6FAEB13D4")
}

var myKey: Box.KeyPair?
var theirPublicKey: Box.PublicKey?

class PeripheralViewController: UIViewController, PeripheralBlueToothEvent {

    @IBOutlet weak var textView: UITextView!
    var isLocked = false
    var peripheral = Peripheral()
    var nonce = ""
    var sodium = Sodium()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheral.delegate = self
    }
    
    func addStatus(status: String) {
        textView.text.append("\(status)\n")
    }
    
    func StatusChanged(status: String) {
        addStatus(status: status)
    }
    
    func Event(message: Message) -> MessageStruct {
        var response: MessageStruct
        switch message {
        case .SendMyPublicKey(let publicKey):
            theirPublicKey = publicKey
            myKey = UserDefaults.standard.object(forKey: "MyKey") as? Box.KeyPair
            if myKey == nil {
                myKey = sodium.box.keyPair()
                UserDefaults.standard.set(myKey, forKey: "MyKey")
            }
            response = MessageStruct(encryptionType: .NotEncrypted, message: Message.SendMyPublicKey(publicKey: myKey!.publicKey))

/*
            theirPublicKey = publicKey
            myKey = sodium.box.keyPair()
            addStatus(status: "Registered Public Keys")
            addStatus(status: "   My Public Key: \(String(describing: myKey?.publicKey))")
            addStatus(status: "   Their Public Key: \(theirPublicKey!)")
            response = MessageStruct(encryptionType: .NotEncrypted, message: Message.SendMyPublicKey(publicKey: myKey!.publicKey))
        case .PhoneID(let id):
            addStatus(status: "Phone ID = \(id)")
            nonce = "Nonce"
            response = MessageStruct(encryptionType: .NotEncrypted, message: Message.Nonce(nonce: nonce))
*/
        case .PhoneMessage(let command, let nonce):
            var cmd = ""
            switch command {
            case .Lock:
                cmd = "Lock"
                isLocked = true
                response = MessageStruct(encryptionType: .NotEncrypted, message: Message.LockMessage(status: LockStatus.Locked, nonce: nonce))
            case .Unlock:
                cmd = "Unlock"
                isLocked = false
                response = MessageStruct(encryptionType: .NotEncrypted, message: Message.LockMessage(status: LockStatus.Unlocked, nonce: nonce))
            }
            addStatus(status: "Command = \(cmd) nonce = \(nonce)")
        default:
            addStatus(status: "Unknown Command")
            response = MessageStruct(encryptionType: .NotEncrypted, message: Message.Error(errorType: .UnknownCommand))
        }
        return response
    }
}
