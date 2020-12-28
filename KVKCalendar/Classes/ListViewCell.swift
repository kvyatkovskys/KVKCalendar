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
    
    private let dotView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        return view
    }()
    
    var txt: String? {
        didSet {
            txtLabel.text = txt
        }
    }
    
    var dotColor: UIColor? {
        didSet {
            dotView.backgroundColor = dotColor
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(txtLabel)
        contentView.addSubview(dotView)
        dotView.translatesAutoresizingMaskIntoConstraints = false
        txtLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let leftDot: NSLayoutConstraint
        if #available(iOS 11.0, *) {
            leftDot = dotView.leftAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leftAnchor)
        } else {
            leftDot = dotView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15)
        }
        let centerYDot = dotView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        let widthDot = dotView.widthAnchor.constraint(equalToConstant: 20)
        let heightDot = dotView.heightAnchor.constraint(equalToConstant: 20)
        NSLayoutConstraint.activate([leftDot, centerYDot, widthDot, heightDot])
        
        let topTxt = txtLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15)
        let bottomTxt = txtLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15)
        let leftTxt = txtLabel.leftAnchor.constraint(equalTo: dotView.rightAnchor, constant: 10)
        let rightTxt = txtLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15)
        NSLayoutConstraint.activate([topTxt, bottomTxt, leftTxt, rightTxt])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
