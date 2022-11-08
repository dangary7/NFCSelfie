//
//  FileManagerExt.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 24/10/22.
//

import SwiftUI

extension FileManager {
    static var cachesFolder : URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
}
