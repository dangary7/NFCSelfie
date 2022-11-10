//
//  AES.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 20/10/22.
//

import Foundation
import CommonCrypto

@available(iOS 13, macOS 10.15, *)
public func AESEncrypt(key:[UInt8], message:[UInt8], iv:[UInt8]) -> [UInt8] {
    
    let dataLength = message.count
    
    let cryptLen = message.count + kCCBlockSizeAES128
    var cryptData = Data(count: cryptLen)

    let keyLength              = size_t(key.count)
    let operation: CCOperation = CCOperation(kCCEncrypt)
    let algorithm:  CCAlgorithm = CCAlgorithm(kCCAlgorithmAES)
    let options:   CCOptions   = CCOptions(0)
    
    var numBytesEncrypted = 0
    
    var cryptStatus: CCCryptorStatus = CCCryptorStatus(kCCSuccess)
    key.withUnsafeBytes {keyBytes in
        message.withUnsafeBytes{ dataBytes in
            iv.withUnsafeBytes{ ivBytes in
                cryptData.withUnsafeMutableBytes{ cryptBytes in

                    cryptStatus = CCCrypt(operation,
                            algorithm,
                            options,
                            keyBytes.baseAddress,
                            keyLength,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress,
                            dataLength,
                            cryptBytes.bindMemory(to: UInt8.self).baseAddress,
                            cryptLen,
                            &numBytesEncrypted)

                }
            }
        }
    }
    
    if cryptStatus == kCCSuccess {
        cryptData.count = Int(numBytesEncrypted)
        
        return [UInt8](cryptData)
    } else {
        Log.error("AES Encrypt Error: \(cryptStatus)")
    }
    return []
}

@available(iOS 13, macOS 10.15, *)
public func AESDecrypt(key:[UInt8], message:[UInt8], iv:[UInt8]) -> [UInt8] {
    var fixedKey = key
    if key.count == 16 {
        fixedKey += key[0..<8]
    }
    
    let data = Data(message)
    let dataLength = message.count
    
    let cryptLen = data.count + kCCBlockSizeAES128
    var cryptData = Data(count: cryptLen)
    
    let keyLength              = size_t(key.count)
    let operation: CCOperation = UInt32(kCCDecrypt)
    let algorithm:  CCAlgorithm = UInt32(kCCAlgorithmAES)
    let options:   CCOptions   = UInt32(0)
    
    var numBytesEncrypted = 0
    
    let cryptStatus = fixedKey.withUnsafeBytes {keyBytes in
        message.withUnsafeBytes{ dataBytes in
            cryptData.withUnsafeMutableBytes{ cryptBytes in
                CCCrypt(operation,
                        algorithm,
                        options,
                        keyBytes.baseAddress,
                        keyLength,
                        iv,
                        dataBytes.baseAddress,
                        dataLength,
                        cryptBytes.bindMemory(to: UInt8.self).baseAddress,
                        cryptLen,
                        &numBytesEncrypted)
                
            }
        }
    }
    
    if cryptStatus == kCCSuccess {
        cryptData.count = Int(numBytesEncrypted)
        
        return [UInt8](cryptData)
    } else {
        Log.error("AES Decrypt Error: \(cryptStatus)")
    }
    return []
}

@available(iOS 13, macOS 10.15, *)
public func AESECBEncrypt(key:[UInt8], message:[UInt8]) -> [UInt8] {

    let dataLength = message.count
    
    let cryptLen = message.count + kCCBlockSizeAES128
    var cryptData = Data(count: cryptLen)
    
    let keyLength              = size_t(key.count)
    let operation: CCOperation = CCOperation(kCCEncrypt)
    let algorithm:  CCAlgorithm = CCAlgorithm(kCCAlgorithmAES)
    let options:   CCOptions   = CCOptions(kCCOptionECBMode)
    
    var numBytesEncrypted = 0
    
    let cryptStatus = key.withUnsafeBytes {keyBytes in
        message.withUnsafeBytes{ dataBytes in
            cryptData.withUnsafeMutableBytes{ cryptBytes in
                
                CCCrypt(operation,
                        algorithm,
                        options,
                        keyBytes.baseAddress,
                        keyLength,
                        nil,
                        dataBytes.baseAddress,
                        dataLength,
                        cryptBytes.bindMemory(to: UInt8.self).baseAddress,
                        cryptLen,
                        &numBytesEncrypted)
                
            }
        }
    }
    
    if cryptStatus == kCCSuccess {
        cryptData.count = Int(numBytesEncrypted)
        
        return [UInt8](cryptData)
    } else {
        Log.error("AESECBEncrypt Error: \(cryptStatus)")
    }
    return []
}

@available(iOS 13, macOS 10.15, *)
public func tripleDESEncrypt(key:[UInt8], message:[UInt8], iv:[UInt8]) -> [UInt8] {
    var fixedKey = key
    if key.count == 16 {
        fixedKey += key[0..<8]
    }
    
    let dataLength = message.count
    
    let cryptLen = message.count + kCCBlockSize3DES
    var cryptData = Data(count: cryptLen)
    
    let keyLength              = size_t(kCCKeySize3DES)
    let operation: CCOperation = UInt32(kCCEncrypt)
    let algorithm:  CCAlgorithm = UInt32(kCCAlgorithm3DES)
    let options:   CCOptions   = UInt32(0)
    
    var numBytesEncrypted = 0
    
    let cryptStatus = fixedKey.withUnsafeBytes {keyBytes in
        message.withUnsafeBytes{ dataBytes in
            iv.withUnsafeBytes{ ivBytes in
                cryptData.withUnsafeMutableBytes{ cryptBytes in
                    CCCrypt(operation,
                            algorithm,
                            options,
                            keyBytes.baseAddress,
                            keyLength,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress,
                            dataLength,
                            cryptBytes.bindMemory(to: UInt8.self).baseAddress,
                            cryptLen,
                            &numBytesEncrypted)
                    
                }
            }
        }
    }

    if cryptStatus == kCCSuccess {
        cryptData.count = Int(numBytesEncrypted)
        
        return [UInt8](cryptData)
    } else {
        Log.error("Error: \(cryptStatus)")
    }
    return []
}

@available(iOS 13, macOS 10.15, *)
public func tripleDESDecrypt(key:[UInt8], message:[UInt8], iv:[UInt8]) -> [UInt8] {
    var fixedKey = key
    if key.count == 16 {
        fixedKey += key[0..<8]
    }

    let data = Data(message)
    let dataLength = message.count
    
    let cryptLen = data.count + kCCBlockSize3DES
    var cryptData = Data(count: cryptLen)
    
    let keyLength              = size_t(kCCKeySize3DES)
    let operation: CCOperation = UInt32(kCCDecrypt)
    let algorithm:  CCAlgorithm = UInt32(kCCAlgorithm3DES)
    let options:   CCOptions   = UInt32(0)
    
    var numBytesEncrypted = 0
    
    let cryptStatus = fixedKey.withUnsafeBytes {keyBytes in
        message.withUnsafeBytes{ dataBytes in
            cryptData.withUnsafeMutableBytes{ cryptBytes in
                CCCrypt(operation,
                        algorithm,
                        options,
                        keyBytes.baseAddress,
                        keyLength,
                        iv,
                        dataBytes.baseAddress,
                        dataLength,
                        cryptBytes.bindMemory(to: UInt8.self).baseAddress,
                        cryptLen,
                        &numBytesEncrypted)

            }
        }
    }
    
    if cryptStatus == kCCSuccess {
        cryptData.count = Int(numBytesEncrypted)
        
        return [UInt8](cryptData)
    } else {
        Log.error("Error: \(cryptStatus)")
    }
    return []
}

@available(iOS 13, macOS 10.15, *)
public func DESEncrypt(key:[UInt8], message:[UInt8], iv:[UInt8], options:UInt32 = 0) -> [UInt8] {
    
    let dataLength = message.count
    
    let cryptLen = message.count + kCCBlockSizeDES
    var cryptData = Data(count: cryptLen)
    
    let keyLength              = size_t(kCCKeySizeDES)
    let operation: CCOperation = UInt32(kCCEncrypt)
    let algorithm:  CCAlgorithm = UInt32(kCCAlgorithmDES)
    let options:   CCOptions   = options
    
    var numBytesEncrypted = 0
    
    let cryptStatus = key.withUnsafeBytes {keyBytes in
        message.withUnsafeBytes{ dataBytes in
            iv.withUnsafeBytes{ ivBytes in
                cryptData.withUnsafeMutableBytes{ cryptBytes in
                    CCCrypt(operation,
                            algorithm,
                            options,
                            keyBytes.baseAddress,
                            keyLength,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress,
                            dataLength,
                            cryptBytes.bindMemory(to: UInt8.self).baseAddress,
                            cryptLen,
                            &numBytesEncrypted)
                    
                }
            }
        }
    }
    
    if cryptStatus == kCCSuccess {
        cryptData.count = Int(numBytesEncrypted)
        
        return [UInt8](cryptData)
    } else {
        Log.error("Error: \(cryptStatus)")
    }
    return []
}

@available(iOS 13, macOS 10.15, *)
public func DESDecrypt(key:[UInt8], message:[UInt8], iv:[UInt8], options:UInt32 = 0) -> [UInt8] {
    
    let dataLength = message.count
    
    let cryptLen = message.count + kCCBlockSizeDES
    var cryptData = Data(count: cryptLen)
    
    let keyLength              = size_t(kCCKeySizeDES)
    let operation: CCOperation = UInt32(kCCDecrypt)
    let algorithm:  CCAlgorithm = UInt32(kCCAlgorithmDES)
    let options:   CCOptions   = options
    
    var numBytesEncrypted = 0
    
    let cryptStatus = key.withUnsafeBytes {keyBytes in
        message.withUnsafeBytes{ dataBytes in
            iv.withUnsafeBytes{ ivBytes in
                cryptData.withUnsafeMutableBytes{ cryptBytes in
                    CCCrypt(operation,
                            algorithm,
                            options,
                            keyBytes.baseAddress,
                            keyLength,
                            nil,
                            dataBytes.baseAddress,
                            dataLength,
                            cryptBytes.bindMemory(to: UInt8.self).baseAddress,
                            cryptLen,
                            &numBytesEncrypted)
                    
                }
            }
        }
    }
    
    if cryptStatus == kCCSuccess {
        cryptData.count = Int(numBytesEncrypted)
        
        return [UInt8](cryptData)
    } else {
        Log.error("Error: \(cryptStatus)")
    }
    return []
}
