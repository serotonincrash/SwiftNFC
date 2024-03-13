//
//  File.swift
//  
//
//  Created by Sean Wong on 15/11/23.
//

import Foundation

enum NFCErrorType: String {
    case cannotRead
    case cannotConnect
    case readOnly
    case tagUnsupported
    case tagInvalidFormat
    case connectionFailed
    case deviceNotSupported
    case genericError
}

public class NFCIOError: Error, CustomStringConvertible {
    
    public var description: String {
        return "NFC I/O error [\(errorType.rawValue)]: \(message)"
    }
    
    var errorType: NFCErrorType
    var message: String
    init(type: NFCErrorType, _ message: String = "") {
        self.errorType = type
        self.message = message
        
    }
}
