//
//  CentralViewController.swift
//  Central
//
//  Created by Gregory Williams on 12/24/20.
//

import UIKit

//
//  CentralViewController.swift
//  Central
//
//  Created by Gregory Williams on 12/24/20.
//

import UIKit
import Sodium

var myKey: Box.KeyPair?
var theirPublicKey: Box.PublicKey?

class CentralViewController: UIViewController, BlueToothEvent {

    var central = Central()
    var nonce = ""
    var isLocked = true
    var notifySent = false
    
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var lockBtn: UIButton!
    @IBOutlet weak var statusLog: UITextView!
    
    override func viewDidLoad() {
        central = Central()
        central.delegate = self
        central.RSSIDistance = -50
        statusLbl.text = "Peripheral Is Not Connected"
        lockBtn.isEnabled = false
        setLockBtn()
        super.viewDidLoad()
    }
    
    func Status(text: String) {
        statusLog.text.append("\(text)\n")
    }
    
    func setLockBtn() {
        if isLocked {
            lockBtn.setTitle("Unlock", for: .normal)
        } else {
            lockBtn.setTitle("Lock", for: .normal)
        }
    }
        
    func Notifying() {
        if !notifySent {
            notifySent = true
            
            do{
                let keysAsData = try NSKeyedArchiver.archivedData(withRootObject:  requiringSecureCoding: true)
                UserDefaults.standard.set(colorAsData, forKey: "myColor")
                UserDefaults.standard.synchronize()
            }catch (let error){
                #if DEBUG
                    print("Failed to convert UIColor to Data : \(error.localizedDescription)")
                #endif
            }
            
            myKey = UserDefaults.standard.object(forKey: "MyKey") as? Box.KeyPair
            if myKey == nil {
                myKey = sodium.box.keyPair()
                UserDefaults.standard.set(myKey, forKey: "MyKey")
            }
            central.sendMessage(message: Message.PhoneID(id: (myKey?.publicKey.utf8String)!), encrpytion: .NotEncrypted)
        }
    }
    
    func Event(message: Message) {
        switch message {
        case .SendMyPublicKey(let publicKey):
            central.nonce = ""
            theirPublicKey = publicKey
            statusLbl.text = "Peripheral Is Connected"
            lockBtn.isEnabled = true
            setLockBtn()
        case .LockMessage(let status, let nonce):
            print("Received status of \(status) with nonce: \(nonce)")
            isLocked = status == .Locked
            setLockBtn()
        case .Error(let errorType):
            print("Error = \(errorType.rawValue)")
        default:
            print("Unknown response")
        }
    }
    
    @IBAction func lockButtonTapped(_ sender: Any) {
        if self.isLocked {
            central.sendMessage(message: Message.PhoneMessage(command: .Unlock, nonce: self.nonce), encrpytion: .PublicPrivateKeyNonce)
        } else {
            central.sendMessage(message: Message.PhoneMessage(command: .Lock, nonce: self.nonce), encrpytion: .PublicPrivateKeyNonce)
        }
    }
    
    @IBAction func RegisterBtn(_ sender: Any) {
        myKey = sodium.box.keyPair()
        central.sendMessage(message: Message.SendMyPublicKey(publicKey: myKey!.publicKey), encrpytion: .NotEncrypted)
    }
    
    @IBAction func EncryptDecryptTapped(_ sender: Any) {
/*
        let test = Message.PhoneMessage(command: .Lock, nonce: "")
        let msg = try? PropertyListEncoder().encode(test)
        let test2 = MessageStruct(encryptionType: .PublicPrivateKey, message: test)
        let myKeys2 = sodium.box.keyPair()
        let test3 = encryptMessage(message: test2, publicKey: myKeys2!.publicKey, secretKey: myKey!.secretKey, nonce: "")
        let decrypt = decryptMessage(encryptedMessage: test3!, publicKey: myKey!.publicKey, secretKey: myKeys2!.secretKey, nonce: "")
*/
      }
    
}
