//
//  URLSession+Extensions.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/5/23.
//

import UIKit

extension URLSession {
    func loadImageFromUrl(url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            let image = UIImage(data: data)
//                            .sd_resizedImage(with: .size(400, 400), scaleMode: .aspectFill)
            completion(image)
        }.resume()
    }
}
