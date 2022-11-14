//
//  PokemonCell.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import UIKit

final class PokemonCell: UITableViewCell {
    
    // MARK: - Properties
    static var cellIdentifier: String = "PokemonCell"
    
    
    // MARK: - Private properties
    private let topRibbon: UILabel = UILabel()
    private let name: UILabel = UILabel()
    private let icon: UIImageView = UIImageView()
    private let innerContentView: UIView = UIView()
    private let cellHeight: CGFloat = 104
    private typealias Constants = PokedexMainConstants
    
    // MARK: - Initializers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
        setupTopRibbon()
        setupName()
        setupIcon()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        return
    }
    
    // MARK: - Protocol methods
    func setup(with data: PokemonCellModel?) {
        guard let model: PokemonCellModel = data else {
            name.text = "Loading..."
            icon.image = UIImage(named: "pokemon_default")
            return
        }
        name.text = model.name
        icon.image = model.icon
        (topRibbon.subviews.last as? UILabel)?.text = "No. \(model.id)"
    }
    
    // MARK: - Private functions
    
    private func setupLayout() {
        [topRibbon, innerContentView, name, icon].forEach({
            $0.translatesAutoresizingMaskIntoConstraints = false
        })
        contentView.addSubview(innerContentView)
        innerContentView.addSubview(topRibbon)
        innerContentView.addSubview(name)
        innerContentView.addSubview(icon)
        
        innerContentView.heightAnchor.constraint(equalToConstant: cellHeight).isActive = true
        
        NSLayoutConstraint.activate([
            innerContentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.commonCellPadding),
            innerContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.commonCellPadding),
            innerContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.commonCellPadding),
            innerContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        ShadowStyler.apply(to: innerContentView)
    }
    
    private func setupTopRibbon() {
        NSLayoutConstraint.activate([
            topRibbon.topAnchor.constraint(equalTo: innerContentView.topAnchor),
            topRibbon.leadingAnchor.constraint(equalTo: innerContentView.leadingAnchor),
            topRibbon.trailingAnchor.constraint(equalTo: innerContentView.trailingAnchor),
            topRibbon.heightAnchor.constraint(equalTo: innerContentView.heightAnchor, multiplier: 0.24)
        ])
        
        topRibbon.layer.cornerRadius = Constants.commonCornerRadius
        topRibbon.backgroundColor = UIColor(red: 186/256, green: 164/256, blue: 222/256, alpha: 1)
        topRibbon.clipsToBounds = true
        topRibbon.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        displayTopRibbonIcon()
        displayTopRibbonTitle()
    }
    
    private func setupName() {
        NSLayoutConstraint.activate([
            name.topAnchor.constraint(equalTo: topRibbon.bottomAnchor),
            name.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: Constants.commonCellPadding),
            name.bottomAnchor.constraint(equalTo: innerContentView.bottomAnchor, constant: -Constants.commonCellPadding),
            name.trailingAnchor.constraint(equalTo: innerContentView.trailingAnchor, constant: -Constants.commonCellPadding)
        ])
        
        name.font = .systemFont(ofSize: 16)
        name.textColor = .gray
    }
    
    private func setupIcon() {
        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: topRibbon.bottomAnchor, constant: Constants.commonCellPadding),
            icon.leadingAnchor.constraint(equalTo: innerContentView.leadingAnchor, constant: Constants.commonCellPadding),
            icon.bottomAnchor.constraint(equalTo: innerContentView.bottomAnchor, constant: -Constants.commonCellPadding),
            icon.widthAnchor.constraint(equalTo: icon.heightAnchor)
        ])
        icon.sizeToFit()
    }
    
    private func displayTopRibbonIcon() {
        let image: UIImage = UIImage(named: "pokeballColoured") ?? UIImage()
        let icon: UIImageView = UIImageView(image: image)
        icon.translatesAutoresizingMaskIntoConstraints = false
        topRibbon.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.heightAnchor.constraint(equalTo: topRibbon.heightAnchor, multiplier: 0.8),
            icon.widthAnchor.constraint(equalTo: icon.heightAnchor),
            icon.centerYAnchor.constraint(equalTo: topRibbon.centerYAnchor),
            icon.leadingAnchor.constraint(equalTo: topRibbon.leadingAnchor,constant: Constants.commonPadding),

        ])
        icon.sizeToFit()
    }
    
    private func displayTopRibbonTitle() {
        let title: UILabel = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        topRibbon.addSubview(title)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: topRibbon.topAnchor),
            title.leadingAnchor.constraint(equalTo: topRibbon.leadingAnchor),
            title.bottomAnchor.constraint(equalTo: topRibbon.bottomAnchor),
            title.trailingAnchor.constraint(equalTo: topRibbon.trailingAnchor)
        ])
        title.textAlignment = .center
        title.font = .systemFont(ofSize: 12)
    }
}
