//
//  NFCReader.swift
//
//
//  Created by 1998code
//

import SwiftUI
import CoreNFC

@available(iOS 13.0, *)
public class NFCWriter: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    
    public var startAlert = "Hold your iPhone near the tag."
    public var endAlert = ""
    public var msg = ""
    public var type = "T"
    public var completionHandler: ((Error?) -> Void)?
    
    public var session: NFCNDEFReaderSession?
    
    public func write() {
        guard NFCNDEFReaderSession.readingAvailable else {
            // Throw a proper error here?
            print("Error")
            return
        }
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = self.startAlert
        session?.begin()
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "Detected more than 1 tag. Please try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            if let error = error {
                session.invalidate(errorMessage: "Unable to connect to tag.")
                print(error.localizedDescription)
                return
            }

            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                if let error = error {
                    session.invalidate(errorMessage: "An error occured querying the tag. Please try again.")
                    print("An error occured when querying tag: \(error.localizedDescription)")
                    return
                }
                
                switch ndefStatus {
                case .notSupported:
                    session.invalidate(errorMessage: "Tag is not NDEF compliant.")
                case .readOnly:
                    session.invalidate(errorMessage: "Read only tag detected.")
                case .readWrite:
                    let payload: NFCNDEFPayload?
                    if self.type == "T" {
                        payload = NFCNDEFPayload.init(
                            format: .nfcWellKnown,
                            type: Data("\(self.type)".utf8),
                            identifier: Data(),
                            payload: Data("\(self.msg)".utf8)
                        )
                    } else {
                        payload = NFCNDEFPayload.wellKnownTypeURIPayload(string: "\(self.msg)")
                    }
                    let message = NFCNDEFMessage(records: [payload].compactMap({ $0 }))
                    tag.writeNDEF(message, completionHandler: { (error: Error?) in
                        if nil != error {
                            session.invalidate(errorMessage: "Write to tag fail: \(error!)")
                        } else {
                            session.alertMessage = self.endAlert != "" ? self.endAlert : "Write \(self.msg) to tag successful."
                        }
                        session.invalidate()
                        self.completionHandler?(error)
                    })
                @unknown default:
                    session.alertMessage = "Unknown tag status."
                    session.invalidate()
                }
            })
        })
    }
    
    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // "dismissed by user" is also an error: ignore?
        print("Session did invalidate with error: \(error)")
        self.session = nil
    }
}
