//
//  Utilities.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 22/12/25.
//

import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func pngData(from cgImage: CGImage) -> Data? {
    let data = NSMutableData()
    guard
        let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        )
    else { return nil }

    CGImageDestinationAddImage(destination, cgImage, nil)
    CGImageDestinationFinalize(destination)

    return data as Data
}
