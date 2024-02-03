//
//  File.swift
//  
//
//  Created by Sean Wong on 15/11/23.
//

import Foundation

enum NFCErrorType {
    case cannotRead
    case cannotConnect
    case readOnly
    case tagUnsupported
    case connectionFailed
}

public class NFCError: Error {
    
}
