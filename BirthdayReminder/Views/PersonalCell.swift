//
//  PersonalCell.swift
//  BirthdayReminder
//
//  Created by Jacky Yu on 16/09/2017.
//  Copyright © 2017 CaptainYukinoshitaHachiman. All rights reserved.
//

import UIKit

class PersonalCell: RoundCornerTableViewCell {

    @IBOutlet weak var picView: UIImageViewRoundCorner!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var birthLabel: UILabel!

    weak var picPack: PicPack? {
        didSet {
            picView.image = picPack?.pic
        }
    }
    weak var delegate: CopyrightViewing?

    override func awakeFromNib() {
        super.awakeFromNib()
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(showCopyright(_:)))
        addGestureRecognizer(recognizer)
        backgroundColor = .clear
        nameLabel.textColor = .label
        birthLabel.textColor = .label
        picView.radius = 10
        picView.corners = .init(arrayLiteral: .topLeft, .bottomLeft)
        layer.cornerRadius = 10
        layer.masksToBounds = true
        nameLabel.text = ""
        picPack = nil
    }

    @objc func showCopyright(_ sender: UIGestureRecognizer) {
        let location = sender.location(in: self)
        if let copyright = picPack?.copyright,
            picView.frame.contains(location),
            sender.state == .began {
            delegate?.showCopyrightInfo(copyright)
        }
    }

}
