//
//  ShadowStyler.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 04/11/22.
//

import UIKit

struct ShadowStyler {
    
    // MARK: - Properties
    private typealias Constants = PokedexMainConstants
    
    // MARK: - Methods
    
    static func apply(to view: UIView) {
        view.layer.cornerRadius = Constants.commonCornerRadius
        view.backgroundColor = view.backgroundColor ?? .white
        // Border
        view.layer.borderWidth = Constants.commonCellBorderWidth
        view.layer.borderColor = UIColor.white.cgColor

        // Shadow
        view.layer.shadowColor = Constants.commonCellShadowColor
        view.layer.shadowOffset = Constants.commonCellShadowOffset
        view.layer.shadowOpacity = Constants.commonCellShadowOpacity
        view.layer.shadowRadius = Constants.commonCellShadowRadius
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.scale
    }
}
