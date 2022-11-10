//
//  BACHandler.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 24/10/22.
//

import Foundation

#if !os(macOS)
import CoreNFC

@available(iOS 15, *)
public class BACHandler {
    let KENC : [UInt8] = [0,0,0,1]
    let KMAC : [UInt8] = [0,0,0,2]
    
    public var ksenc : [UInt8] = []
    public var ksmac : [UInt8] = []

    var rnd_icc : [UInt8] = []
    var rnd_ifd : [UInt8] = []
    public var kifd : [UInt8] = []
    
    var tagReader : TagReader?
    
    public init() {
    }
    
    public init(tagReader: TagReader) {
        self.tagReader = tagReader
    }

    public func performBACAndGetSessionKeys( mrzKey : String ) async throws {
        guard let tagReader = self.tagReader else {
            throw NFCPassportReaderError.NoConnectedTag
        }
        
        Log.debug( "BACHandler - deriving Document Basic Access Keys" )
        _ = try self.deriveDocumentBasicAccessKeys(mrz: mrzKey)
        
        tagReader.secureMessaging = nil
        
        Log.debug( "BACHandler - Getting initial challenge" )
        let response = try await tagReader.getChallenge()
    
        Log.verbose( "DATA - \(response.data)" )
        
        Log.debug( "BACHandler - Doing mutual authentication" )
        let cmd_data = self.authentication(rnd_icc: [UInt8](response.data))
        let maResponse = try await tagReader.doMutualAuthentication(cmdData: Data(cmd_data))
        Log.debug( "DATA - \(maResponse.data)" )
        guard maResponse.data.count > 0 else {
            throw NFCPassportReaderError.InvalidMRZKey
        }
        
        let (KSenc, KSmac, ssc) = try self.sessionKeys(data: [UInt8](maResponse.data))
        tagReader.secureMessaging = SecureMessaging(ksenc: KSenc, ksmac: KSmac, ssc: ssc)
        Log.debug( "BACHandler - complete" )
    }


    func deriveDocumentBasicAccessKeys(mrz: String) throws -> ([UInt8], [UInt8]) {
        let kseed = generateInitialKseed(kmrz:mrz)
    
        Log.verbose("Calculate the Basic Access Keys (Kenc and Kmac) using TR-SAC 1.01, 4.2")
        let smskg = SecureMessagingSessionKeyGenerator()
        self.ksenc = try smskg.deriveKey(keySeed: kseed, mode: .ENC_MODE)
        self.ksmac = try smskg.deriveKey(keySeed: kseed, mode: .MAC_MODE)
                
        return (ksenc, ksmac)
    }
    
    func generateInitialKseed(kmrz : String ) -> [UInt8] {
        
        Log.verbose("Calculate the SHA-1 hash of MRZ_information")
        Log.verbose("\tMRZ KEY - \(kmrz)")
        let hash = calcSHA1Hash( [UInt8](kmrz.data(using:.utf8)!) )
        
        Log.verbose("\tsha1(MRZ_information): \(binToHexRep(hash))")
        
        let subHash = Array(hash[0..<16])
        Log.verbose("Take the most significant 16 bytes to form the Kseed")
        Log.verbose("\tKseed: \(binToHexRep(subHash))" )
        
        return Array(subHash)
    }
    
    func authentication( rnd_icc : [UInt8]) -> [UInt8] {
        self.rnd_icc = rnd_icc
        
        Log.verbose("Request an 8 byte random number from the MRTD's chip")
        Log.verbose("\tRND.ICC: " + binToHexRep(self.rnd_icc))
        
        self.rnd_icc = rnd_icc

        let rnd_ifd = generateRandomUInt8Array(8)
        let kifd = generateRandomUInt8Array(16)
        
        Log.verbose("Generate an 8 byte random and a 16 byte random")
        Log.verbose("\tRND.IFD: \(binToHexRep(rnd_ifd))" )
        Log.verbose("\tRND.Kifd: \(binToHexRep(kifd))")
        
        let s = rnd_ifd + rnd_icc + kifd
        
        Log.verbose("Concatenate RND.IFD, RND.ICC and Kifd")
        Log.verbose("\tS: \(binToHexRep(s))")
        
        let iv : [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        let eifd = tripleDESEncrypt(key: ksenc,message: s, iv: iv)
        
        Log.verbose("Encrypt S with TDES key Kenc as calculated in Appendix 5.2")
        Log.verbose("\tEifd: \(binToHexRep(eifd))")
        
        let mifd = mac(algoName: .DES, key: ksmac, msg: pad(eifd, blockSize:8))

        Log.verbose("Compute MAC over eifd with TDES key Kmac as calculated in-Appendix 5.2")
        Log.verbose("\tMifd: \(binToHexRep(mifd))")
        
        let cmd_data = eifd + mifd
        Log.verbose("Construct command data for MUTUAL AUTHENTICATE")
        Log.verbose("\tcmd_data: \(binToHexRep(cmd_data))")
        
        self.rnd_ifd = rnd_ifd
        self.kifd = kifd

        return cmd_data
    }
    
    public func sessionKeys(data : [UInt8] ) throws -> ([UInt8], [UInt8], [UInt8]) {
        Log.verbose("Decrypt and verify received data and compare received RND.IFD with generated RND.IFD \(binToHexRep(self.ksmac))" )
        
        let response = tripleDESDecrypt(key: self.ksenc, message: [UInt8](data[0..<32]), iv: [0,0,0,0,0,0,0,0] )

        let response_kicc = [UInt8](response[16..<32])
        let Kseed = xor(self.kifd, response_kicc)
        Log.verbose("Calculate XOR of Kifd and Kicc")
        Log.verbose("\tKseed: \(binToHexRep(Kseed))" )
        
        let smskg = SecureMessagingSessionKeyGenerator()
        let KSenc = try smskg.deriveKey(keySeed: Kseed, mode: .ENC_MODE)
        let KSmac = try smskg.deriveKey(keySeed: Kseed, mode: .MAC_MODE)
        
        Log.verbose("Calculate Session Keys (KSenc and KSmac) using Appendix 5.1")
        Log.verbose("\tKSenc: \(binToHexRep(KSenc))" )
        Log.verbose("\tKSmac: \(binToHexRep(KSmac))" )
        
        
        let ssc = [UInt8](self.rnd_icc.suffix(4) + self.rnd_ifd.suffix(4))
        Log.verbose("Calculate Send Sequence Counter")
        Log.verbose("\tSSC: \(binToHexRep(ssc))" )
        return (KSenc, KSmac, ssc)
    }
    
}
#endif
