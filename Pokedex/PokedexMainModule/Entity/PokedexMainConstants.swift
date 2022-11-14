//
//  PokedexMainConstants.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import UIKit

enum PokedexMainConstants {
    
    static let pokeballIcon: UIImage = UIImage(named: "pokeball") ?? UIImage()
    
    // MARK: - Common
    static let commonPadding: CGFloat = 8.0
    static let commonCornerRadius: CGFloat = 8.0
    static let commonCellBorderWidth: CGFloat = 0.05
    static let commonCellPadding: CGFloat = 4.0
    static let commonCellShadowOffset: CGSize = CGSize(width: .zero, height: 4)
    static let commonCellShadowOpacity: Float = 0.2
    static let commonCellShadowColor: CGColor = UIColor.gray.withAlphaComponent(1.0).cgColor
    static let commonCellShadowRadius: CGFloat = 2.5
    static let headerHeight: CGFloat = 48.0
    
    static let borderPadding: CGFloat = 16.0
}
