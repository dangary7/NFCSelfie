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
                return "Manten tu iPhone cerca de tu pasaporte."
            case .authenticatingWithPassport(let progress):
                let progressString = handleProgress(percentualProgress: progress)
                return "Autenticando con pasaporte.....\n\n\(progressString)"
            case .readingDataGroupProgress(let dataGroup, let progress):
                let progressString = handleProgress(percentualProgress: progress)
                return "Leyendo \(dataGroup)...\n\n\(progressString)"
            case .error(let tagError):
                switch tagError {
                    case NFCPassportReaderError.TagNotValid:
                        return "Tag no valido."
                    case NFCPassportReaderError.MoreThanOneTagFound:
                        return "Mas de 1 tag encontrado. Presenta unicamente 1 tag."
                    case NFCPassportReaderError.ConnectionError:
                        return "Error de conexión. Intenta nuevamente."
                    case NFCPassportReaderError.InvalidMRZKey:
                        return "Llave MRZ no válida para este documento."
                    case NFCPassportReaderError.ResponseError(let description, let sw1, let sw2):
                        return "Hubo un problema leyendo el pasaporte. \(description) - (0x\(sw1), 0x\(sw2)"
                    default:
                        return "Hubo un problema leyendo el pasaporte. Intenta nuevamente"
                }
            case .successfulRead:
                return "Pasaporte leído correctamente"
        }
    }
    
    func handleProgress(percentualProgress: Int) -> String {
        let p = (percentualProgress/20)
        let full = String(repeating: "🟢 ", count: p)
        let empty = String(repeating: "⚪️ ", count: 5-p)
        return "\(full)\(empty)"
    }
}
