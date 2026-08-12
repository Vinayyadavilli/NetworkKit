//
//  MultipartFile.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

/// Represents a single file to be included in a multipart/form-data request.
public struct MultipartFile: Sendable {

    /// The name of the form field (e.g., "profile_image", "document").
    public let fieldName: String

    /// The original filename (e.g., "photo.jpg", "resume.pdf").
    public let fileName: String

    /// The MIME type of the file (e.g., "image/jpeg", "application/pdf").
    public let mimeType: String

    /// The raw binary data of the file.
    public let data: Data

    public init(
        fieldName: String,
        fileName: String,
        mimeType: String,
        data: Data
    ) {
        self.fieldName = fieldName
        self.fileName = fileName
        self.mimeType = mimeType
        self.data = data
    }
}
