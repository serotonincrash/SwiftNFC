//
//  NFCReader.swift
//  
//
//  Created by 1998code
//

import SwiftUI
import CoreNFC

@available(iOS 13.0, *)
public class NFCReader: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    
    public var startAlert = "Hold your iPhone near the tag."
    public var endAlert = ""
    @Published public var msg = "Scan to read or Edit here to write..."
    @Published public var raw = "Raw Data available after scan."
    public var completionHandler: ((Error?) -> Void)?
    public var session: NFCNDEFReaderSession?
    
    public func read() {
        guard NFCNDEFReaderSession.readingAvailable else {
            let error = NFCIOError(type: .deviceNotSupported, "This device doesn't support NFC!")
            completionHandler?(error)
            return
        }
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = self.startAlert
        session?.begin()
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            self.msg = messages.map {
                $0.records.map {
                    String(decoding: $0.payload, as: UTF8.self)
                }.joined(separator: "\n")
            }.joined(separator: " ")
            
            self.raw = messages.map {
                $0.records.map {
                    "\($0.typeNameFormat) \(String(decoding:$0.type, as: UTF8.self)) \(String(decoding:$0.identifier, as: UTF8.self)) \(String(decoding: $0.payload, as: UTF8.self))"
                }.joined(separator: "\n")
            }.joined(separator: " ")

            session.alertMessage = self.endAlert != "" ? self.endAlert : "Read \(messages.count) NDEF Messages, and \(messages[0].records.count) Records."
            
            self.completionHandler?(nil)
            
        }
    }
    
    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        self.session = nil
        self.completionHandler?(error)
    }
}
