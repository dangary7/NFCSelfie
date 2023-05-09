//
//  NFCDisplayMenuMessage.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 20/10/22.
//

import Foundation

@available(iOS 13, macOS 10.15, *)
public enum NFCViewDisplayMessage {
    case requestPresentPassport
    case authenticatingWithPassport(Int)
    case readingDataGroupProgress(DataGroupId, Int)
    case error(NFCPassportReaderError)
    case successfulRead
}

@available(iOS 13, macOS 10.15, *)
extension NFCViewDisplayMessage {
    public var description: String {
        switch self {
            case .requestPresentPassport:
                return NSLocalizedString("reques_present_passport", comment: "")
            case .authenticatingWithPassport(let progress):
                let progressString = handleProgress(percentualProgress: progress)
                let temp = NSLocalizedString("authenticating_with_passport", comment: "")
                return "\(temp)\n\n\(progressString)"
            case .readingDataGroupProgress(let dataGroup, let progress):
                let progressString = handleProgress(percentualProgress: progress)
                let temp = NSLocalizedString("reading_data_group_progress", comment: "")
                return "\(temp) \(dataGroup)...\n\n\(progressString)"
            case .error(let tagError):
                switch tagError {
                    case NFCPassportReaderError.TagNotValid:
                        return NSLocalizedString("tag_not_valid_error", comment: "")
                    case NFCPassportReaderError.MoreThanOneTagFound:
                        return NSLocalizedString("more_than_one_tag_found_error", comment: "")
                    case NFCPassportReaderError.ConnectionError:
                        return NSLocalizedString("connection_error", comment: "")
                    case NFCPassportReaderError.InvalidMRZKey:
                        return NSLocalizedString("invalid_mrz_key_error", comment: "")
                    case NFCPassportReaderError.ResponseError(let description, let sw1, let sw2):
                        let temp = NSLocalizedString("response_error", comment: "")
                        return "\(temp). \(description) - (0x\(sw1), 0x\(sw2)"
                    default:
                        return NSLocalizedString("generic_response_error", comment: "")
                }
            case .successfulRead:
                return NSLocalizedString("successful_read", comment: "")
        }
    }
    
    func handleProgress(percentualProgress: Int) -> String {
        let p = (percentualProgress/20)
        let full = String(repeating: "🟢 ", count: p)
        let empty = String(repeating: "⚪️ ", count: 5-p)
        return "\(full)\(empty)"
    }
}
