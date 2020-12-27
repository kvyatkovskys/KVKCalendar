//
//  ListViewCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 27.12.2020.
//

import UIKit

final class ListViewCell: UITableViewCell {
    
    private let txtLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.numberOfLines = 0
        return label
    }()
    
    var txt: String? {
        didSet {
            txtLabel.text = txt
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(txtLabel)
        txtLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let top = txtLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15)
        let bottom = txtLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15)
        let left = txtLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15)
        let right = txtLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15)
        NSLayoutConstraint.activate([top, bottom, left, right])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
