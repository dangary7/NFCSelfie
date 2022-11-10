//
//  PassportReader.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 19/10/22.
//

import Foundation

#if !os(macOS)
import UIKit
import CoreNFC

@available(iOS 15, *)
public class PassportReader : NSObject {
    private typealias NFCCheckedContinuation = CheckedContinuation<NFCPassportModel, Error>
    private var nfcContinuation: NFCCheckedContinuation?

    private var passport : NFCPassportModel = NFCPassportModel()
    
    private var readerSession: NFCTagReaderSession?
    private var currentlyReadingDataGroup : DataGroupId?
    
    private var dataGroupsToRead : [DataGroupId] = []
    private var readAllDatagroups = false
    private var skipSecureElements = true
    private var skipCA = false
    private var skipPACE = false

    private var bacHandler : BACHandler?
    private var caHandler : ChipAuthenticationHandler?
    private var paceHandler : PACEHandler?
    private var mrzKey : String = ""
    private var dataAmountToReadOverride : Int? = nil
    
    private var scanCompletedHandler: ((NFCPassportModel?, NFCPassportReaderError?)->())!
    private var nfcViewDisplayMessageHandler: ((NFCViewDisplayMessage) -> String?)?
    private var masterListURL : URL?
    private var shouldNotReportNextReaderSessionInvalidationErrorUserCanceled : Bool = false

    public var passiveAuthenticationUsesOpenSSL : Bool = false

    public init( logLevel: LogLevel = .info, masterListURL: URL? = nil ) {
        super.init()
        
        Log.logLevel = logLevel
        self.masterListURL = masterListURL
    }
    
    public func setMasterListURL( _ masterListURL : URL ) {
        self.masterListURL = masterListURL
    }
    
    public func overrideNFCDataAmountToRead( amount: Int ) {
        dataAmountToReadOverride = amount
    }
    
    public func readPassport( mrzKey : String, tags : [DataGroupId] = [], skipSecureElements : Bool = true, skipCA : Bool = false, skipPACE : Bool = false, customDisplayMessage : ((NFCViewDisplayMessage) -> String?)? = nil) async throws -> NFCPassportModel {
        
        self.passport = NFCPassportModel()
        self.mrzKey = mrzKey
        self.skipCA = skipCA
        self.skipPACE = skipPACE
        
        self.dataGroupsToRead.removeAll()
        self.dataGroupsToRead.append( contentsOf:tags)
        self.nfcViewDisplayMessageHandler = customDisplayMessage
        self.skipSecureElements = skipSecureElements
        self.currentlyReadingDataGroup = nil
        self.bacHandler = nil
        self.caHandler = nil
        self.paceHandler = nil
        
        if self.dataGroupsToRead.count == 0 {
            self.dataGroupsToRead.append(contentsOf:[.COM, .SOD] )
            self.readAllDatagroups = true
        } else {
            self.readAllDatagroups = false
        }
        
        guard NFCNDEFReaderSession.readingAvailable else {
            throw NFCPassportReaderError.NFCNotSupported
        }
        
        if NFCTagReaderSession.readingAvailable {
            readerSession = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: nil)
            
            self.updateReaderSessionMessage( alertMessage: NFCViewDisplayMessage.requestPresentPassport )
            readerSession?.begin()
        }
        
        return try await withCheckedThrowingContinuation({ (continuation: NFCCheckedContinuation) in
            self.nfcContinuation = continuation
        })
    }
}

@available(iOS 15, *)
extension PassportReader : NFCTagReaderSessionDelegate {
    // MARK: - NFCTagReaderSessionDelegate
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        Log.debug( "tagReaderSessionDidBecomeActive" )
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Log.debug( "tagReaderSession:didInvalidateWithError - \(error.localizedDescription)" )
        self.readerSession?.invalidate()
        self.readerSession = nil

        if let readerError = error as? NFCReaderError, readerError.code == NFCReaderError.readerSessionInvalidationErrorUserCanceled
            && self.shouldNotReportNextReaderSessionInvalidationErrorUserCanceled {
            
            self.shouldNotReportNextReaderSessionInvalidationErrorUserCanceled = false
        } else {
            var userError = NFCPassportReaderError.UnexpectedError
            if let readerError = error as? NFCReaderError {
                Log.error( "tagReaderSession:didInvalidateWithError - Got NFCReaderError - \(readerError.localizedDescription)" )
                switch (readerError.code) {
                case NFCReaderError.readerSessionInvalidationErrorUserCanceled:
                    Log.error( "     - User cancelled session" )
                    userError = NFCPassportReaderError.UserCanceled
                default:
                    Log.error( "     - some other error - \(readerError.localizedDescription)" )
                    userError = NFCPassportReaderError.UnexpectedError
                }
            } else {
                Log.error( "tagReaderSession:didInvalidateWithError - Received error - \(error.localizedDescription)" )
            }
            nfcContinuation?.resume(throwing: userError)
            nfcContinuation = nil
        }
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        Log.debug( "tagReaderSession:didDetect - \(tags[0])" )
        if tags.count > 1 {
            Log.debug( "tagReaderSession:more than 1 tag detected! - \(tags)" )

            let errorMessage = NFCViewDisplayMessage.error(.MoreThanOneTagFound)
            self.invalidateSession(errorMessage: errorMessage, error: NFCPassportReaderError.MoreThanOneTagFound)
            return
        }

        let tag = tags.first!
        var passportTag: NFCISO7816Tag
        switch tags.first! {
        case let .iso7816(tag):
            passportTag = tag
        default:
            Log.debug( "tagReaderSession:invalid tag detected!!!" )

            let errorMessage = NFCViewDisplayMessage.error(NFCPassportReaderError.TagNotValid)
            self.invalidateSession(errorMessage:errorMessage, error: NFCPassportReaderError.TagNotValid)
            return
        }
        
        Task { [passportTag] in
            do {
                try await session.connect(to: tag)
                
                Log.debug( "tagReaderSession:connected to tag - starting authentication" )
                self.updateReaderSessionMessage( alertMessage: NFCViewDisplayMessage.authenticatingWithPassport(0) )
                
                let tagReader = TagReader(tag:passportTag)
                
                if let newAmount = self.dataAmountToReadOverride {
                    tagReader.overrideDataAmountToRead(newAmount: newAmount)
                }
                
                tagReader.progress = { [unowned self] (progress) in
                    if let dgId = self.currentlyReadingDataGroup {
                        self.updateReaderSessionMessage( alertMessage: NFCViewDisplayMessage.readingDataGroupProgress(dgId, progress) )
                    } else {
                        self.updateReaderSessionMessage( alertMessage: NFCViewDisplayMessage.authenticatingWithPassport(progress) )
                    }
                }
                
                let passportModel = try await self.startReading( tagReader : tagReader)
                nfcContinuation?.resume(returning: passportModel)
                nfcContinuation = nil

                
            } catch let error as NFCPassportReaderError {
                let errorMessage = NFCViewDisplayMessage.error(error)
                self.invalidateSession(errorMessage: errorMessage, error: error)
            } catch let error {

                nfcContinuation?.resume(throwing: error)
                nfcContinuation = nil
                Log.debug( "tagReaderSession:failed to connect to tag - \(error.localizedDescription)" )
                let errorMessage = NFCViewDisplayMessage.error(NFCPassportReaderError.ConnectionError)
                self.invalidateSession(errorMessage: errorMessage, error: NFCPassportReaderError.ConnectionError)
            }
        }
    }
    
    func updateReaderSessionMessage(alertMessage: NFCViewDisplayMessage ) {
        self.readerSession?.alertMessage = self.nfcViewDisplayMessageHandler?(alertMessage) ?? alertMessage.description
    }
}

@available(iOS 15, *)
extension PassportReader {
    
    func startReading(tagReader : TagReader) async throws -> NFCPassportModel {

        if !skipPACE {
            do {
                let data = try await tagReader.readCardAccess()
                Log.verbose( "Read CardAccess - data \(binToHexRep(data))" )
                let cardAccess = try CardAccess(data)
                passport.cardAccess = cardAccess
     
                Log.info( "Starting Password Authenticated Connection Establishment (PACE)" )
                 
                let paceHandler = try PACEHandler( cardAccess: cardAccess, tagReader: tagReader )
                try await paceHandler.doPACE(mrzKey: mrzKey )
                passport.PACEStatus = .success
                Log.debug( "PACE Succeeded" )
            } catch {
                passport.PACEStatus = .failed
                Log.error( "PACE Failed - falling back to BAC" )
            }
            
            _ = try await tagReader.selectPassportApplication()
        }
        
        if passport.PACEStatus != .success {
            try await doBACAuthentication(tagReader : tagReader)
        }
        
        try await readDataGroups(tagReader: tagReader)
        
        self.updateReaderSessionMessage(alertMessage: NFCViewDisplayMessage.successfulRead)

        try await doActiveAuthenticationIfNeccessary(tagReader : tagReader)
        self.shouldNotReportNextReaderSessionInvalidationErrorUserCanceled = true
        self.readerSession?.invalidate()

        self.passport.verifyPassport(masterListURL: self.masterListURL, useCMSVerification: self.passiveAuthenticationUsesOpenSSL)

        return self.passport
    }
    
    
    func doActiveAuthenticationIfNeccessary( tagReader : TagReader) async throws {
        guard self.passport.activeAuthenticationSupported else {
            return
        }
        
        Log.info( "Performing Active Authentication" )
        
        let challenge = generateRandomUInt8Array(8)
        Log.verbose( "Generated Active Authentication challange - \(binToHexRep(challenge))")
        let response = try await tagReader.doInternalAuthentication(challenge: challenge)
        self.passport.verifyActiveAuthentication( challenge:challenge, signature:response.data )
    }
    

    func doBACAuthentication(tagReader : TagReader) async throws {
        self.currentlyReadingDataGroup = nil
        
        Log.info( "Starting Basic Access Control (BAC)" )
        
        self.passport.BACStatus = .failed

        self.bacHandler = BACHandler( tagReader: tagReader )
        try await bacHandler?.performBACAndGetSessionKeys( mrzKey: mrzKey )
        Log.info( "Basic Access Control (BAC) - SUCCESS!" )

        self.passport.BACStatus = .success
    }

    func readDataGroups( tagReader: TagReader ) async throws {
        
        var DGsToRead = [DataGroupId]()

        self.updateReaderSessionMessage( alertMessage: NFCViewDisplayMessage.readingDataGroupProgress(.COM, 0) )
        if let com = try await readDataGroup(tagReader:tagReader, dgId:.COM) as? COM {
            self.passport.addDataGroup( .COM, dataGroup:com )
        
            DGsToRead = [.SOD] + com.dataGroupsPresent.map { DataGroupId.getIDFromName(name:$0) }
            DGsToRead.removeAll { $0 == .COM }
        }
        
        if DGsToRead.contains( .DG14 ) {
            DGsToRead.removeAll { $0 == .DG14 }
            
            if !skipCA {
                if let dg14 = try await readDataGroup(tagReader:tagReader, dgId:.DG14) as? DataGroup14 {
                    self.passport.addDataGroup( .DG14, dataGroup:dg14 )
                    let caHandler = ChipAuthenticationHandler(dg14: dg14, tagReader: tagReader)
                     
                    if caHandler.isChipAuthenticationSupported {
                        do {
                            try await caHandler.doChipAuthentication()
                            self.passport.chipAuthenticationStatus = .success
                        } catch {
                            Log.info( "Chip Authentication failed - re-establishing BAC")
                            self.passport.chipAuthenticationStatus = .failed
                            
                            try await doBACAuthentication(tagReader: tagReader)
                        }
                    }
                }
            }
        }

        if self.skipSecureElements {
            DGsToRead = DGsToRead.filter { $0 != .DG3 && $0 != .DG4 }
        }

        if self.readAllDatagroups != true {
            DGsToRead = DGsToRead.filter { dataGroupsToRead.contains($0) }
        }
        for dgId in DGsToRead {
            self.updateReaderSessionMessage( alertMessage: NFCViewDisplayMessage.readingDataGroupProgress(dgId, 0) )
            if let dg = try await readDataGroup(tagReader:tagReader, dgId:dgId) {
                self.passport.addDataGroup( dgId, dataGroup:dg )
            }
        }
    }
    
    func readDataGroup( tagReader : TagReader, dgId : DataGroupId ) async throws -> DataGroup?  {

        self.currentlyReadingDataGroup = dgId
        Log.info( "Reading tag - \(dgId)" )
        var readAttempts = 0
        
        self.updateReaderSessionMessage( alertMessage: NFCViewDisplayMessage.readingDataGroupProgress(dgId, 0) )

        repeat {
            do {
                let response = try await tagReader.readDataGroup(dataGroup:dgId)
                let dg = try DataGroupParser().parseDG(data: response)
                return dg
            } catch let error as NFCPassportReaderError {
                Log.error( "TagError reading tag - \(error)" )

                let errMsg = error.value
                Log.error( "ERROR - \(errMsg)" )
                
                var redoBAC = false
                if errMsg == "Session invalidated" || errMsg == "Class not supported" || errMsg == "Tag connection lost"  {
                    if self.caHandler != nil {
                        self.caHandler = nil
                        redoBAC = true
                    } else {
                        throw error
                    }
                } else if errMsg == "Security status not satisfied" || errMsg == "File not found" {
                    self.dataGroupsToRead.removeFirst()
                    redoBAC = true
                } else if errMsg == "SM data objects incorrect" || errMsg == "Class not supported" {
                    redoBAC = true
                } else if errMsg.hasPrefix( "Wrong length" ) || errMsg.hasPrefix( "End of file" ) {
                    tagReader.reduceDataReadingAmount()
                    redoBAC = true
                }
                
                if redoBAC {
                    try await doBACAuthentication(tagReader : tagReader)
                } else {
                }
            }
            readAttempts += 1
        } while ( readAttempts < 2 )
        
        return nil
    }

    func invalidateSession(errorMessage: NFCViewDisplayMessage, error: NFCPassportReaderError) {
        self.shouldNotReportNextReaderSessionInvalidationErrorUserCanceled = true
        self.readerSession?.invalidate(errorMessage: self.nfcViewDisplayMessageHandler?(errorMessage) ?? errorMessage.description)
        nfcContinuation?.resume(throwing: error)
        nfcContinuation = nil
    }
}
#endif
