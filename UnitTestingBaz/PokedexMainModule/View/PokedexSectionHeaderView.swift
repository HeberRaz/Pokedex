//
//  PokedexSectionHeaderView.swift
//  UnitTestingBaz
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import UIKit

class PokedexSectionHeaderView: UITableViewHeaderFooterView {
    
    // MARK: - Properties
    
    static var reuseIdentifier: String = "MySectionHeaderView"
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20)
        label.textColor = .gray
        return label
    }()
    
    // MARK: - Initializers

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        return
    }
    
    // MARK: Methods
    
    func setup() {
        titleLabel.text = "Pokedex List"
    }
}
