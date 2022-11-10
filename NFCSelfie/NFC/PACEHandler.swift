//
//  PACEHandler.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 24/10/22.
//

import Foundation
import OpenSSL
import CryptoTokenKit

#if !os(macOS)
import CoreNFC
import CryptoKit

@available(iOS 15, *)
private enum PACEHandlerError {
    case DHKeyAgreementError(String)
    case ECDHKeyAgreementError(String)
    
    var value: String {
        switch self {
            case .DHKeyAgreementError(let errMsg): return errMsg
            case .ECDHKeyAgreementError(let errMsg): return errMsg

        }
    }
}

@available(iOS 15, *)
extension PACEHandlerError: LocalizedError {
    public var errorDescription: String? {
        return NSLocalizedString(value, comment: "PACEHandlerError")
    }
}

@available(iOS 15, *)
public class PACEHandler {
    
    
    private static let MRZ_PACE_KEY_REFERENCE : UInt8 = 0x01
    private static let CAN_PACE_KEY_REFERENCE : UInt8 = 0x02 // Not currently supported
    private static let PIN_PACE_KEY_REFERENCE : UInt8 = 0x03 // Not currently supported
    private static let CUK_PACE_KEY_REFERENCE : UInt8 = 0x04 // Not currently supported

    var tagReader : TagReader
    var paceInfo : PACEInfo
    
    var isPACESupported : Bool = false
    var paceError : String = ""
    
    private var paceKey : [UInt8] = []
    private var paceKeyType : UInt8 = 0
    private var paceOID : String = ""
    private var parameterSpec : Int32 = -1
    private var mappingType : PACEMappingType!
    private var agreementAlg : String = ""
    private var cipherAlg : String = ""
    private var digestAlg : String = ""
    private var keyLength : Int = -1
    
    public init(cardAccess : CardAccess, tagReader: TagReader) throws {
        self.tagReader = tagReader
        
        guard let pi = cardAccess.paceInfo else {
            throw NFCPassportReaderError.NotYetSupported( "PACE not supported" )
        }

        self.paceInfo = pi
        isPACESupported = true
    }
    
    public func doPACE( mrzKey : String ) async throws {
        guard isPACESupported else {
            throw NFCPassportReaderError.NotYetSupported( "PACE not supported" )
        }
        
        Log.info( "Performing PACE with \(paceInfo.getProtocolOIDString())" )
        
        paceOID = paceInfo.getObjectIdentifier()
        parameterSpec = try paceInfo.getParameterSpec()
        
        mappingType = try paceInfo.getMappingType()  // Either GM, CAM, or IM.
        agreementAlg = try paceInfo.getKeyAgreementAlgorithm()  // Either DH or ECDH.
        cipherAlg  = try paceInfo.getCipherAlgorithm()  // Either DESede or AES.
        digestAlg = try paceInfo.getDigestAlgorithm()  // Either SHA-1 or SHA-256.
        keyLength = try paceInfo.getKeyLength()  // Get key length  the enc cipher. Either 128, 192, or 256.

        paceKeyType = PACEHandler.MRZ_PACE_KEY_REFERENCE
        paceKey = try createPaceKey( from: mrzKey )
        
        Log.verbose("doPace - inpit parameters" )
        Log.verbose("paceOID - \(paceOID)" )
        Log.verbose("parameterSpec - \(parameterSpec)" )
        Log.verbose("mappingType - \(mappingType!)" )
        Log.verbose("agreementAlg - \(agreementAlg)" )
        Log.verbose("cipherAlg - \(cipherAlg)" )
        Log.verbose("digestAlg - \(digestAlg)" )
        Log.verbose("keyLength - \(keyLength)" )
        Log.verbose("keyLength - \(mrzKey)" )
        Log.verbose("paceKey - \(binToHexRep(paceKey, asArray:true))" )

        _ = try await tagReader.sendMSESetATMutualAuth(oid: paceOID, keyType: paceKeyType)
            
        let decryptedNonce = try await self.doStep1()
        let ephemeralParams = try await self.doStep2(passportNonce: decryptedNonce)
        let (ephemeralKeyPair, passportPublicKey) = try await self.doStep3KeyExchange(ephemeralParams: ephemeralParams)
        let (encKey, macKey) = try await self.doStep4KeyAgreement( pcdKeyPair: ephemeralKeyPair, passportPublicKey: passportPublicKey)
        try self.paceCompleted( ksEnc: encKey, ksMac: macKey )
        Log.debug("PACE SUCCESSFUL" )
    }
    
    func handleError( _ stage: String, _ error: String, needToTerminateGA: Bool = false ) {
        Log.error( "PACEHandler: \(stage) - \(error)" )
        Log.error( "   OpenSSLError: \(OpenSSLUtils.getOpenSSLError())" )
        self.paceError = "\(stage) - \(error)"
    }
    
    func doStep1() async throws -> [UInt8] {
        Log.debug("Doing PACE Step1...")
        let response = try await tagReader.sendGeneralAuthenticate(data: [], isLast: false)
            
        let data = response.data
        let encryptedNonce = try unwrapDO(tag: 0x80, wrappedData: data)
        Log.verbose( "Encrypted nonce - \(binToHexRep(encryptedNonce, asArray:true))" )

        let decryptedNonce: [UInt8]
        if self.cipherAlg == "DESede" {
            let iv = [UInt8](repeating:0, count: 8)
            decryptedNonce = tripleDESDecrypt(key: self.paceKey, message: encryptedNonce, iv: iv)
        } else if self.cipherAlg == "AES" {
            let iv = [UInt8](repeating:0, count: 16)
            decryptedNonce = AESDecrypt(key: self.paceKey, message: encryptedNonce, iv: iv)
        } else {
            throw NFCPassportReaderError.UnsupportedCipherAlgorithm
        }

        Log.verbose( "Decrypted nonce - \(binToHexRep(decryptedNonce, asArray:true) )" )
        return decryptedNonce
    }
    
    func doStep2( passportNonce: [UInt8]) async throws -> OpaquePointer {
        Log.debug( "Doing PACE Step2...")
        switch(mappingType) {
            case .CAM, .GM:
                Log.debug( "   Using General Mapping (GM)...")
                return try await doPACEStep2GM(passportNonce: passportNonce)
            case .IM:
                Log.debug( "   Using Integrated Mapping (IM)...")
                return try await doPACEStep2IM(passportNonce: passportNonce)
            default:
                throw NFCPassportReaderError.PACEError( "Step2GM", "Unsupported Mapping Type" )
        }

    }
    
    func doPACEStep2GM(passportNonce : [UInt8]) async throws -> OpaquePointer {
        
        let mappingKey : OpaquePointer
        mappingKey = try self.paceInfo.createMappingKey( )

        guard let pcdMappingEncodedPublicKey = OpenSSLUtils.getPublicKeyData(from: mappingKey) else {
            throw NFCPassportReaderError.PACEError( "Step2GM", "Unable to get public key from mapping key")
        }
        Log.verbose( "public mapping key - \(binToHexRep(pcdMappingEncodedPublicKey, asArray:true))")

        Log.debug( "Sending public mapping key to passport..")
        let step2Data = wrapDO(b:0x81, arr:pcdMappingEncodedPublicKey)
        let response = try await tagReader.sendGeneralAuthenticate(data:step2Data, isLast:false)

        let piccMappingEncodedPublicKey = try unwrapDO(tag: 0x82, wrappedData: response.data)
            
        Log.debug( "Received passports public mapping key")
        Log.verbose( "   public mapping key - \(binToHexRep(piccMappingEncodedPublicKey, asArray: true))")

        guard let bn_nonce = BN_bin2bn(passportNonce, Int32(passportNonce.count), nil) else {
            throw NFCPassportReaderError.PACEError( "Step2GM", "Unable to convert picc nonce to bignum" )
        }
        defer { BN_free(bn_nonce) }

        let ephemeralParams : OpaquePointer
        if self.agreementAlg == "DH" {
            Log.debug( "Doing DH Mapping agreement")
            ephemeralParams = try self.doDHMappingAgreement(mappingKey: mappingKey, passportPublicKeyData: piccMappingEncodedPublicKey, nonce: bn_nonce )
        } else if self.agreementAlg == "ECDH" {
            Log.debug( "Doing ECDH Mapping agreement")
            ephemeralParams = try self.doECDHMappingAgreement(mappingKey: mappingKey, passportPublicKeyData: piccMappingEncodedPublicKey, nonce: bn_nonce )
        } else {
            throw NFCPassportReaderError.PACEError( "Step2GM", "Unsupported agreement algorithm" )
        }

        EVP_PKEY_free(mappingKey)
        return ephemeralParams
    }
    
    func doPACEStep2IM( passportNonce: [UInt8] ) async throws -> OpaquePointer {
        // Not implemented yet
        throw NFCPassportReaderError.PACEError( "Step2IM", "IM not yet implemented" )
    }
    
    func doStep3KeyExchange(ephemeralParams: OpaquePointer) async throws -> (OpaquePointer, OpaquePointer) {
        Log.debug( "Doing PACE Step3 - Key Exchange")

        var ephKeyPair : OpaquePointer? = nil
        let pctx = EVP_PKEY_CTX_new(ephemeralParams, nil)
        EVP_PKEY_keygen_init(pctx)
        EVP_PKEY_keygen(pctx, &ephKeyPair)
        EVP_PKEY_CTX_free(pctx)
                
        guard let ephemeralKeyPair = ephKeyPair else {
            throw NFCPassportReaderError.PACEError( "Step3 KeyEx", "Unable to get create ephermeral key pair" )
        }
        
        Log.debug( "Generated Ephemeral key pair")

        EVP_PKEY_free( ephemeralParams )

        guard let publicKey = OpenSSLUtils.getPublicKeyData( from: ephemeralKeyPair ) else {
            throw NFCPassportReaderError.PACEError( "Step3 KeyEx", "Unable to get public key from ephermeral key pair" )
        }
        Log.verbose( "Ephemeral public key - \(binToHexRep(publicKey, asArray: true))")

        Log.debug( "Sending ephemeral public key to passport")
        let step3Data = wrapDO(b:0x83, arr:publicKey)
        let response = try await tagReader.sendGeneralAuthenticate(data:step3Data, isLast:false)
        let passportEncodedPublicKey = try? unwrapDO(tag: 0x84, wrappedData: response.data)
        guard let passportPublicKey = OpenSSLUtils.decodePublicKeyFromBytes(pubKeyData: passportEncodedPublicKey!, params: ephemeralKeyPair) else {
            throw NFCPassportReaderError.PACEError( "Step3 KeyEx", "Unable to decode passports ephemeral key" )
        }

        Log.verbose( "Received passports ephemeral public key - \(binToHexRep(passportEncodedPublicKey!, asArray: true))" )
        return (ephemeralKeyPair, passportPublicKey)
    }
    
    func doStep4KeyAgreement( pcdKeyPair: OpaquePointer, passportPublicKey: OpaquePointer) async throws -> ([UInt8], [UInt8]) {
        Log.debug( "Doing PACE Step4 Key Agreement...")

        Log.debug( "Computing shared secret...")
        let sharedSecret = OpenSSLUtils.computeSharedSecret(privateKeyPair: pcdKeyPair, publicKey: passportPublicKey)
        Log.verbose( "Shared secret - \(binToHexRep(sharedSecret, asArray:true))")

        Log.debug( "Deriving ksEnc and ksMac keys from shared secret")
        let gen = SecureMessagingSessionKeyGenerator()
        let encKey = try! gen.deriveKey(keySeed: sharedSecret, cipherAlgName: cipherAlg, keyLength: keyLength, mode: .ENC_MODE)
        let macKey = try! gen.deriveKey(keySeed: sharedSecret, cipherAlgName: cipherAlg, keyLength: keyLength, mode: .MAC_MODE)
        Log.verbose( "encKey - \(binToHexRep(encKey, asArray:true))")
        Log.verbose( "macKey - \(binToHexRep(macKey, asArray:true))")

        Log.debug( "Generating authentication token")
        guard let pcdAuthToken = try? generateAuthenticationToken( publicKey: passportPublicKey, macKey: macKey) else {
            throw NFCPassportReaderError.PACEError( "Step3 KeyAgreement", "Unable to generate authentication token using passports public key" )
        }
        Log.verbose( "authentication token - \(pcdAuthToken)")

        Log.debug( "Sending auth token to passport")
        let step4Data = wrapDO(b:0x85, arr:pcdAuthToken)
        let response = try await tagReader.sendGeneralAuthenticate(data:step4Data, isLast:true)
            
        let tvlResp = TKBERTLVRecord.sequenceOfRecords(from: Data(response.data))!
        if tvlResp[0].tag != 0x86 {
            Log.warning("Was expecting tag 0x86, found: \(binToHex(UInt8(tvlResp[0].tag)))")
        }
        let expectedPICCToken = try self.generateAuthenticationToken( publicKey: pcdKeyPair, macKey: macKey)
        
        Log.verbose( "Expecting authentication token from passport - \(expectedPICCToken)")

        let piccToken = [UInt8](tvlResp[0].value)
        Log.verbose( "Received authentication token from passport - \(piccToken)")

        guard piccToken == expectedPICCToken else {
            Log.error( "Error PICC Token mismatch!\npicToken - \(piccToken)\nexpectedPICCToken - \(expectedPICCToken)" )
            throw NFCPassportReaderError.PACEError( "Step3 KeyAgreement", "Error PICC Token mismatch!\npicToken - \(piccToken)\nexpectedPICCToken - \(expectedPICCToken)" )
        }
        
        Log.debug( "Auth token from passport matches expected token!" )
        
        return (encKey, macKey)
    }
    
    func paceCompleted( ksEnc: [UInt8], ksMac: [UInt8] ) throws {
        let ssc = withUnsafeBytes(of: 0.bigEndian, Array.init)
        if (cipherAlg.hasPrefix("DESede")) {
            Log.info( "Restarting secure messaging using DESede encryption")
            let sm = SecureMessaging(encryptionAlgorithm: .DES, ksenc: ksEnc, ksmac: ksMac, ssc: ssc)
            tagReader.secureMessaging = sm
        } else if (cipherAlg.hasPrefix("AES")) {
            Log.info( "Restarting secure messaging using AES encryption")
            let sm = SecureMessaging(encryptionAlgorithm: .AES, ksenc: ksEnc, ksmac: ksMac, ssc: ssc)
            tagReader.secureMessaging = sm
        } else {
            throw NFCPassportReaderError.PACEError( "PACECompleted", "Not restarting secure messaging as unsupported cipher algorithm requested - \(cipherAlg)" )
        }
    }
}

@available(iOS 15, *)
extension PACEHandler {
    
    func doDHMappingAgreement( mappingKey : OpaquePointer, passportPublicKeyData: [UInt8], nonce: OpaquePointer ) throws -> OpaquePointer {
        guard let dh_mapping_key = EVP_PKEY_get1_DH(mappingKey) else {
            throw PACEHandlerError.DHKeyAgreementError( "Unable to get DH mapping key" )
        }
        
        let bn = BN_bin2bn(passportPublicKeyData, Int32(passportPublicKeyData.count), nil)
        defer { BN_free( bn ) }
        
        var secret = [UInt8](repeating: 0, count: Int(DH_size(dh_mapping_key)))
        DH_compute_key( &secret, bn, dh_mapping_key)
        
        let bn_h = BN_bin2bn(secret, Int32(secret.count), nil)
        defer { BN_clear_free(bn_h) }
        
        guard let ephemeral_key = DHparams_dup(dh_mapping_key) else {
            throw PACEHandlerError.DHKeyAgreementError("Unable to get initialise ephemeral parameters from DH mapping key")
        }
        defer{ DH_free(ephemeral_key) }
        
        var p : OpaquePointer? = nil
        var q : OpaquePointer? = nil
        var g : OpaquePointer? = nil
        DH_get0_pqg(dh_mapping_key, &p, &q, &g)
        
        guard let bn_g = BN_new() else {
            throw PACEHandlerError.DHKeyAgreementError( "Unable to create bn_g" )
        }
        defer{ BN_free(bn_g) }
        guard let new_g = BN_new() else {
            throw PACEHandlerError.DHKeyAgreementError( "Unable to create new_g" )
        }
        defer{ BN_free(new_g) }
        
        let bn_ctx = BN_CTX_new()
        guard BN_mod_exp(bn_g, g, nonce, p, bn_ctx) == 1,
              BN_mod_mul(new_g, bn_g, bn_h, p, bn_ctx) == 1 else {
            throw PACEHandlerError.DHKeyAgreementError( "Failed to generate new parameters" )
        }
        
        guard DH_set0_pqg(ephemeral_key, BN_dup(p), BN_dup(q), BN_dup(new_g)) == 1 else {
            throw PACEHandlerError.DHKeyAgreementError( "Unable to set DH pqg paramerters" )
        }
        
        guard let ephemeralParams = EVP_PKEY_new() else {
            throw PACEHandlerError.ECDHKeyAgreementError( "Unable to create ephemeral params" )
        }

        guard EVP_PKEY_set1_DH(ephemeralParams, ephemeral_key) == 1 else {
            EVP_PKEY_free( ephemeralParams )
            throw PACEHandlerError.DHKeyAgreementError( "Unable to set ephemeral parameters" )
        }
        return ephemeralParams
    }
    
    func doECDHMappingAgreement( mappingKey : OpaquePointer, passportPublicKeyData: [UInt8], nonce: OpaquePointer ) throws -> OpaquePointer {

        let ec_mapping_key = EVP_PKEY_get1_EC_KEY(mappingKey)
        
        guard let group = EC_GROUP_dup(EC_KEY_get0_group(ec_mapping_key)) else {
            throw PACEHandlerError.ECDHKeyAgreementError( "Unable to get EC group" )
        }
        defer { EC_GROUP_free(group) }
        
        guard let order = BN_new() else {
            throw PACEHandlerError.ECDHKeyAgreementError( "Unable to create order bignum" )
        }
        defer { BN_free( order ) }
        
        guard let cofactor = BN_new() else {
            throw PACEHandlerError.ECDHKeyAgreementError( "Unable to create cofactor bignum" )
        }
        defer { BN_free( cofactor ) }
        
        guard EC_GROUP_get_order(group, order, nil) == 1 ||
                EC_GROUP_get_cofactor(group, cofactor, nil) == 1 else {
            throw PACEHandlerError.ECDHKeyAgreementError( "Unable to get order or cofactor from group" )
        }
        
        guard let sharedSecretMappingPoint = self.computeECDHMappingKeyPoint(privateKey: mappingKey, inputKey: passportPublicKeyData) else {
            throw PACEHandlerError.ECDHKeyAgreementError( "Failed to compute new shared secret mapping point from mapping key and passport public mapping key" )
        }
        defer { EC_POINT_free( sharedSecretMappingPoint ) }

        guard let newGenerater = EC_POINT_new(group) else {
            throw PACEHandlerError.ECDHKeyAgreementError( "Unable to create new mapping generator point" )
        }
        defer{ EC_POINT_free(newGenerater) }
        
        guard EC_POINT_mul(group, newGenerater, nonce, sharedSecretMappingPoint, BN_value_one(), nil) == 1 else {
            throw PACEHandlerError.ECDHKeyAgreementError( "Failed to map nonce to get new generator params" )
        }
        
        guard let ephemeralParams = EVP_PKEY_new() else {
            throw PACEHandlerError.ECDHKeyAgreementError( "Unable to create ephemeral params" )
        }

        let ephemeral_key = EC_KEY_dup(ec_mapping_key)
        defer{ EC_KEY_free(ephemeral_key) }
        
        guard EVP_PKEY_set1_EC_KEY(ephemeralParams, ephemeral_key) == 1,
              EC_GROUP_set_generator(group, newGenerater, order, cofactor) == 1,
              EC_GROUP_check(group, nil) == 1,
              EC_KEY_set_group(ephemeral_key, group) == 1 else {

            EVP_PKEY_free( ephemeralParams )
            throw PACEHandlerError.ECDHKeyAgreementError( "Unable to configure new ephemeral params" )
        }
        return ephemeralParams
    }
    
    func generateAuthenticationToken( publicKey: OpaquePointer, macKey: [UInt8] ) throws -> [UInt8] {
        var encodedPublicKeyData = try encodePublicKey(oid:self.paceOID, key:publicKey)
        
        if cipherAlg == "DESede" {
            encodedPublicKeyData = pad(encodedPublicKeyData, blockSize: 8)
        }
        
        Log.verbose( "Generating Authentication Token" )
        Log.verbose( "EncodedPubKey = \(binToHexRep(encodedPublicKeyData, asArray: true))" )
        Log.verbose( "macKey = \(binToHexRep(macKey, asArray: true))" )

        let maccedPublicKeyDataObject = mac(algoName: cipherAlg == "DESede" ? .DES : .AES, key: macKey, msg: encodedPublicKeyData)

        let authToken = [UInt8](maccedPublicKeyDataObject[0..<8])
        Log.verbose( "Generated authToken = \(binToHexRep(authToken, asArray: true))" )
        return authToken
    }
    
    func encodePublicKey( oid : String, key : OpaquePointer ) throws -> [UInt8] {
        let encodedOid = oidToBytes(oid:oid, replaceTag: false)
        guard let pubKeyData = OpenSSLUtils.getPublicKeyData(from: key) else {
            Log.error( "PACEHandler: encodePublicKey() - Unable to get public key data" )
            throw NFCPassportReaderError.InvalidDataPassed("Unable to get public key data")
        }

        let keyType = EVP_PKEY_base_id( key )
        let tag : TKTLVTag
        if keyType == EVP_PKEY_DH || keyType == EVP_PKEY_DHX {
            tag = 0x84
        } else {
            tag = 0x86
        }

        guard let encOid = TKBERTLVRecord(from: Data(encodedOid)) else {
            throw NFCPassportReaderError.InvalidASN1Value
        }
        let encPub = TKBERTLVRecord(tag:tag, value: Data(pubKeyData))
        let record = TKBERTLVRecord(tag: 0x7F49, records:[encOid, encPub])
        let data = record.data

        return [UInt8](data)
    }

    func createPaceKey( from mrzKey: String ) throws -> [UInt8] {
        let buf: [UInt8] = Array(mrzKey.utf8)
        let hash = calcSHA1Hash(buf)
        
        let smskg = SecureMessagingSessionKeyGenerator()
        let key = try smskg.deriveKey(keySeed: hash, cipherAlgName: cipherAlg, keyLength: keyLength, nonce: nil, mode: .PACE_MODE, paceKeyReference: paceKeyType)
        return key
    }
    
    func computeECDHMappingKeyPoint( privateKey : OpaquePointer, inputKey : [UInt8] ) -> OpaquePointer? {
        
        let ecdh = EVP_PKEY_get1_EC_KEY(privateKey)
        defer { EC_KEY_free(ecdh) }

        let privateECKey = EC_KEY_get0_private_key(ecdh)

        guard let group = EC_KEY_get0_group(ecdh) else{ return nil }
        guard let ecp = EC_POINT_new(group) else { return nil }
        defer { EC_POINT_free(ecp) }
        guard EC_POINT_oct2point(group, ecp, inputKey, inputKey.count,nil) != 0 else { return nil }
                
        let output = EC_POINT_new(group)

        EC_POINT_mul(group, output, nil, ecp, privateECKey, nil)
        
        return output
    }
}

#endif
