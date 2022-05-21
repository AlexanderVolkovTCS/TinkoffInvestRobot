//
//  ViewController.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 20.05.2022.
//

import UIKit
import Combine
import TinkoffInvestSDK

class SettingsViewController: UIViewController {
    let padding = 16.0
    
    var modeDescriptionView: UITextView = UITextView()
    var profileListTitleView: UILabel = UILabel()
    var profileListView: UIPickerView = UIPickerView()
    
    var currentMode : BotMode = .Emu;
    var profileView: UIPickerView = UIPickerView()
    var profileLoader: ProfileListLoader = ProfileListLoader()
    var accountList: AccountList = AccountList()
    
    var activeAccount: Account = Account()
    
    var vizVC : VisualizationViewController? = nil
    var cancellables = Set<AnyCancellable>()
    
    func onNewProfileListData(data: AccountList) {
        self.accountList = data
        self.profileView.reloadAllComponents()
    }
    
    @objc
    func onModeChange(_ sender: UISegmentedControl) {
        let newMode = BotMode.fromIndex(sender.selectedSegmentIndex)
        
        // Leaving if mode has not been changed.
        if (newMode == currentMode) {
            return
        }
        
        // Trying to load new profile data
        switch newMode {
        case .Emu:
            profileLoader = EmuProfileListLoader(callback: onNewProfileListData)
        case .Sandbox:
            profileLoader = SandboxProfileListLoader(callback: onNewProfileListData)
        case .Tinkoff:
            profileLoader = TinkoffProfileListLoader(callback: onNewProfileListData)
        }

        self.modeDescriptionView.text = BotMode.descriptionFor(newMode)
        self.vizVC?.onModeChange(sender)
        currentMode = newMode
    }
    
    
    @objc
    func onBotStatus(_ sender: UISegmentedControl) {
        // We use split view, so VisualizationVC is 2 levels away, as views are wrapped into UINavigationController
        let label = self.toolbarItems?[0].customView as? UILabel
        label?.text = "Bot is running"
        self.toolbarItems?[2] = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(onBotStatus(_:)))
        
        GlobalBotConfig.account = self.activeAccount
        self.vizVC?.onBotStart()        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        self.navigationItem.title = "Invest Bot"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        self.navigationController?.isToolbarHidden = false
        var items = [UIBarButtonItem]()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        label.text = "Bot is stopped"
        label.center = CGPoint(x: view.frame.midX, y: view.frame.height)
        label.textAlignment = .left
        items.append(
            UIBarButtonItem(customView: label)
        )
        items.append(
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        )
        items.append(
            UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(onBotStatus(_:)))
        )
        
        self.navigationController?.toolbar.barStyle = .default
        self.navigationController?.toolbar.isTranslucent = true
        self.navigationController?.toolbar.barTintColor = .red
        self.toolbarItems = items

        let modePicker = UISegmentedControl()
        modePicker.insertSegment(withTitle: "Эмулятор", at: 0, animated: false)
        modePicker.insertSegment(withTitle: "Песочница", at: 1, animated: false)
        modePicker.insertSegment(withTitle: "Тинькофф", at: 2, animated: false)
        modePicker.selectedSegmentIndex = 0
        modePicker.addTarget(self, action: #selector(self.onModeChange(_:)), for: .valueChanged)
        modePicker.translatesAutoresizingMaskIntoConstraints = false
        let modePickerHC1 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left + self.padding)
        // TODO: This 128 and get size of navigationItem somehow.
        let modePickerHC2 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 128 + self.padding)
        let modePickerHC3 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: -2 * self.padding)
        let modePickerHC4 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 30)
        view.addSubview(modePicker)
        view.addConstraints([modePickerHC1, modePickerHC2, modePickerHC3, modePickerHC4])
        
        self.modeDescriptionView.translatesAutoresizingMaskIntoConstraints = false
        self.modeDescriptionView.text = ""
        let modeDescriptionViewHC1 = NSLayoutConstraint(item: self.modeDescriptionView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left + self.padding)
        let modeDescriptionViewHC2 = NSLayoutConstraint(item: self.modeDescriptionView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: modePicker, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: self.padding)
        let modeDescriptionViewHC3 = NSLayoutConstraint(item: self.modeDescriptionView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: -2 * self.padding)
        let modeDescriptionViewHC4 = NSLayoutConstraint(item: self.modeDescriptionView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 48)
        view.addSubview(self.modeDescriptionView)
        view.addConstraints([modeDescriptionViewHC1, modeDescriptionViewHC2, modeDescriptionViewHC3, modeDescriptionViewHC4])
        
        self.profileListTitleView.text = "Выберите аккаунт"
        self.profileListTitleView.translatesAutoresizingMaskIntoConstraints = false
        self.profileListTitleView.font = .preferredFont(forTextStyle: .title3, compatibleWith: .current)
        let profileListTitleViewHC1 = NSLayoutConstraint(item: self.profileListTitleView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left + self.padding)
        let profileListTitleViewHC2 = NSLayoutConstraint(item: self.profileListTitleView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.modeDescriptionView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: self.padding)
        let profileListTitleViewHC3 = NSLayoutConstraint(item: self.profileListTitleView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: -2 * self.padding)
//        let profileListTitleViewHC4 = NSLayoutConstraint(item: self.profileListTitleView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 70)
        view.addSubview(self.profileListTitleView)
        view.addConstraints([profileListTitleViewHC1, profileListTitleViewHC2, profileListTitleViewHC3])
        
        self.profileView.delegate = self
        self.profileView.dataSource = self
        self.profileView.translatesAutoresizingMaskIntoConstraints = false
        
        let profileViewHC1 = NSLayoutConstraint(item: self.profileView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left + self.padding)
        let profileViewHC2 = NSLayoutConstraint(item: self.profileView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.profileListTitleView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
        let profileViewHC3 = NSLayoutConstraint(item: self.profileView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: -2 * self.padding)
        let profileViewHC4 = NSLayoutConstraint(item: self.profileView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 70)
        view.addSubview(self.profileView)
        view.addConstraints([profileViewHC1, profileViewHC2, profileViewHC3, profileViewHC4])
    }
}

extension SettingsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return accountList.accounts.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return accountList.accounts[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        self.activeAccount = accountList.accounts[row]
    }
}
