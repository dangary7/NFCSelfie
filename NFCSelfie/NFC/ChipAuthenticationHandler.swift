//
//  ChipAuthenticationHandler.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 24/10/22.
//

import Foundation
import OpenSSL

#if !os(macOS)
import CoreNFC
import CryptoKit

@available(iOS 15, *)
class ChipAuthenticationHandler {
    
    private static let NO_PACE_KEY_REFERENCE : UInt8 = 0x00
    private static let ENC_MODE : UInt8 = 0x1
    private static let MAC_MODE : UInt8 = 0x2
    private static let PACE_MODE : UInt8 = 0x3

    private static let COMMAND_CHAINING_CHUNK_SIZE = 224

    var tagReader : TagReader?
    var gaSegments = [[UInt8]]()
    
    var chipAuthInfos = [Int:ChipAuthenticationInfo]()
    var chipAuthPublicKeyInfos = [ChipAuthenticationPublicKeyInfo]()
    
    var isChipAuthenticationSupported : Bool = false
    
    public init(dg14 : DataGroup14, tagReader: TagReader) {
        self.tagReader = tagReader
        
        for secInfo in dg14.securityInfos {
            if let cai = secInfo as? ChipAuthenticationInfo {
                let keyId = cai.getKeyId()
                chipAuthInfos[keyId] = cai
            } else if let capki = secInfo as? ChipAuthenticationPublicKeyInfo {
                chipAuthPublicKeyInfos.append(capki)
            }
        }
        
        if chipAuthPublicKeyInfos.count > 0 {
            isChipAuthenticationSupported = true
        }
    }

    public func doChipAuthentication() async throws  {
                
        Log.info( "Performing Chip Authentication - number of public keys found - \(chipAuthPublicKeyInfos.count)" )
        guard isChipAuthenticationSupported else {
            throw NFCPassportReaderError.NotYetSupported( "ChipAuthentication not supported" )
        }
        
        var success = false
        for pubKey in chipAuthPublicKeyInfos {
            do {
                success = try await self.doChipAuthentication( with: pubKey)
                if success {
                    break
                }
            } catch {
            }
        }
        
        if !success {
            throw NFCPassportReaderError.ChipAuthenticationFailed
        }
    }
    
    private func doChipAuthentication( with chipAuthPublicKeyInfo : ChipAuthenticationPublicKeyInfo ) async throws -> Bool {
        
        let keyId = chipAuthPublicKeyInfo.keyId
        let chipAuthInfoOID : String
        if let chipAuthInfo = chipAuthInfos[keyId ?? 0] {
            chipAuthInfoOID = chipAuthInfo.oid
        } else {
            if let oid = inferOID( fromPublicKeyOID:chipAuthPublicKeyInfo.oid) {
                chipAuthInfoOID = oid
            } else {
                return false
            }
        }
        
        try await self.doCA( keyId: keyId, encryptionDetailsOID: chipAuthInfoOID, publicKey: chipAuthPublicKeyInfo.pubKey )
        return true
    }
    
    private func inferOID(fromPublicKeyOID: String ) -> String? {
        if fromPublicKeyOID == SecurityInfo.ID_PK_ECDH_OID {
            Log.warning("No ChipAuthenticationInfo - guessing its id-CA-ECDH-3DES-CBC-CBC");
            return SecurityInfo.ID_CA_ECDH_3DES_CBC_CBC_OID
        } else if fromPublicKeyOID == SecurityInfo.ID_PK_DH_OID {
            Log.warning("No ChipAuthenticationInfo - guessing its id-CA-DH-3DES-CBC-CBC");
            return SecurityInfo.ID_CA_DH_3DES_CBC_CBC_OID
        }
        
        Log.warning("No ChipAuthenticationInfo and unsupported ChipAuthenticationPublicKeyInfo public key OID \(fromPublicKeyOID)")
        return nil;
    }
    
    private func doCA( keyId: Int?, encryptionDetailsOID oid: String, publicKey: OpaquePointer) async throws {
        
        var ephemeralKeyPair : OpaquePointer? = nil
        let pctx = EVP_PKEY_CTX_new(publicKey, nil)
        EVP_PKEY_keygen_init(pctx)
        EVP_PKEY_keygen(pctx, &ephemeralKeyPair)
        EVP_PKEY_CTX_free(pctx)
        
        try await sendPublicKey(oid: oid, keyId: keyId, pcdPublicKey: ephemeralKeyPair!)
            
        Log.debug( "Public Key successfully sent to passport!" )
        
        let sharedSecret = OpenSSLUtils.computeSharedSecret(privateKeyPair:ephemeralKeyPair!, publicKey:publicKey)
        
        try restartSecureMessaging( oid : oid, sharedSecret : sharedSecret, maxTranceiveLength : 1, shouldCheckMAC : true)
    }
    
    private func sendPublicKey(oid : String, keyId : Int?, pcdPublicKey : OpaquePointer) async throws {
        let cipherAlg = try ChipAuthenticationInfo.toCipherAlgorithm(oid: oid)
        guard let keyData = OpenSSLUtils.getPublicKeyData(from: pcdPublicKey) else {
            throw NFCPassportReaderError.InvalidDataPassed("Unable to get public key data from public key" )
        }
        
        if cipherAlg.hasPrefix("DESede") {
        
            var idData : [UInt8] = []
            if let keyId = keyId {
                idData = intToBytes( val:keyId, removePadding:true)
                idData = wrapDO( b:0x84, arr:idData)
            }
            let wrappedKeyData = wrapDO( b:0x91, arr:keyData)
            _ = try await self.tagReader?.sendMSEKAT(keyData: Data(wrappedKeyData), idData: Data(idData))
        } else if cipherAlg.hasPrefix("AES") {
            _ = try await self.tagReader?.sendMSESetATIntAuth(oid: oid, keyId: keyId)
            let data = wrapDO(b: 0x80, arr:keyData)
            gaSegments = self.chunk(data: data, segmentSize: ChipAuthenticationHandler.COMMAND_CHAINING_CHUNK_SIZE )
            try await self.handleGeneralAuthentication()
        } else {
            throw NFCPassportReaderError.InvalidDataPassed("Cipher Algorithm \(cipherAlg) not supported")
        }
    }
    
    private func handleGeneralAuthentication() async throws {
        repeat {
            let segment = gaSegments.removeFirst()
            let isLast = gaSegments.isEmpty
        
            _ = try await self.tagReader?.sendGeneralAuthenticate(data: segment, isLast: isLast)
        } while ( !gaSegments.isEmpty )
    }
        
    private func restartSecureMessaging( oid : String, sharedSecret : [UInt8], maxTranceiveLength : Int, shouldCheckMAC : Bool) throws  {
        let cipherAlg = try ChipAuthenticationInfo.toCipherAlgorithm(oid: oid)
        let keyLength = try ChipAuthenticationInfo.toKeyLength(oid: oid)
        
        let smskg = SecureMessagingSessionKeyGenerator()
        let ksEnc = try smskg.deriveKey(keySeed: sharedSecret, cipherAlgName: cipherAlg, keyLength: keyLength, mode: .ENC_MODE)
        let ksMac = try smskg.deriveKey(keySeed: sharedSecret, cipherAlgName: cipherAlg, keyLength: keyLength, mode: .MAC_MODE)
        
        let ssc = withUnsafeBytes(of: 0.bigEndian, Array.init)
        if (cipherAlg.hasPrefix("DESede")) {
            Log.info( "Restarting secure messaging using DESede encryption")
            let sm = SecureMessaging(encryptionAlgorithm: .DES, ksenc: ksEnc, ksmac: ksMac, ssc: ssc)
            tagReader?.secureMessaging = sm
        } else if (cipherAlg.hasPrefix("AES")) {
            Log.info( "Restarting secure messaging using AES encryption")
            let sm = SecureMessaging(encryptionAlgorithm: .AES, ksenc: ksEnc, ksmac: ksMac, ssc: ssc)
            tagReader?.secureMessaging = sm
        } else {
            Log.error( "Not restarting secure messaging as unsupported cipher algorithm requested - \(cipherAlg)")
            throw NFCPassportReaderError.InvalidDataPassed("Unsupported cipher algorithm \(cipherAlg)" )
        }
    }
    
    
    func inferDigestAlgorithmFromCipherAlgorithmForKeyDerivation( cipherAlg : String, keyLength : Int) throws -> String {
        if cipherAlg == "DESede" || cipherAlg == "AES-128" {
            return "SHA1"
        }
        if cipherAlg == "AES" && keyLength == 128 {
            return "SHA1"
        }
        if cipherAlg == "AES-256" || cipherAlg ==  "AES-192" {
            return "SHA256"
        }
        if cipherAlg == "AES" && (keyLength == 192 || keyLength == 256) {
            return "SHA256"
        }
        
        throw NFCPassportReaderError.InvalidDataPassed("Unsupported cipher algorithm or key length")
    }
    
    func chunk( data : [UInt8], segmentSize: Int ) -> [[UInt8]] {
        return stride(from: 0, to: data.count, by: segmentSize).map {
            Array(data[$0 ..< Swift.min($0 + segmentSize, data.count)])
        }
    }
}

#endif
