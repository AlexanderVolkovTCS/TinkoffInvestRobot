////
////  ProfileView.swift
////  Tinkoff2
////
////  Created by Никита Мелехин on 21.05.2022.
////
//
//import UIKit
//
//class ProfileView: UIView {
//    fileprivate var nameLabel: UILabel = UILabel()
//    fileprivate var _data: ProfileListData = ProfileListData()
//    public var data: ProfileListData {
//        get { return _data }
//        set { onDataSet(newValue) }
//    }
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.addCustomView()
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func onDataSet(_ newData : ProfileListData) {
////        nameLabel.text = newData.name
//    }
//
//    func addCustomView() {
//        backgroundColor = .red
//        nameLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 30)
//        nameLabel.backgroundColor = .white
//        nameLabel.textAlignment = .left
//        nameLabel.font = .boldSystemFont(ofSize: 20)
//        nameLabel.text = ""
//        self.addSubview(nameLabel)
//    }
//}
