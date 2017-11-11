//
//  PersonFormController.swift
//  BirthdayReminder
//
//  Created by Jacky Yu on 16/09/2017.
//  Copyright © 2017 CaptainYukinoshitaHachiman. All rights reserved.
//

import UIKit
import Eureka
import ImageRow
import CoreData
import StoreKit
import CFNotify

class PersonFormController: FormViewController {
    
    private var formMode = Mode.new
    
    private var newPerson: People?
    private var persistentPerson: PeopleToSave?
    
    
    public func setup(with mode: Mode, person: Any?) {
        switch mode {
        case .new:
            newPerson = person as? People
        case .edit:
            persistentPerson = person as? PeopleToSave
        }
        formMode = mode
    }
    
    enum Mode {
        case edit
        case new
    }
    
    private let context: NSManagedObjectContext = {
        let app = UIApplication.shared
        let delegate = app.delegate as! AppDelegate
        return delegate.context
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section(NSLocalizedString("name", comment: "name"))
            <<< NameRow() { row in
                row.tag = "name"
                row.title = NSLocalizedString("name", comment: "name")
                row.placeholder = NSLocalizedString("name", comment: "name")
                row.value = newPerson?.name ?? persistentPerson?.name
            }
            +++ Section(NSLocalizedString("birth", comment: "Birth"))
            <<< DatePickingRow() { row in
                row.tag = "birth"
                row.title = NSLocalizedString("birth", comment: "Birth")
                row.value = (newPerson?.stringedBirth ?? persistentPerson?.birth) ?? "01-01"
                
            }
            +++ Section(NSLocalizedString("image", comment: "Image"))
            <<< ImageRow() { row in
                row.tag = "image"
                row.title = NSLocalizedString("image", comment: "Image")
                row.value = UIImage(data: (newPerson?.picData ?? persistentPerson?.picData) ?? Data())
        }
        +++ Section()
            <<< SwitchRow() { row in
                    row.tag = "shouldSync"
                    row.title = NSLocalizedString("syncWithAW", comment: "syncWithAW")
                    row.value = persistentPerson?.shouldSync ?? false
            }
        +++ Section()
            <<< ButtonRow() {row in
                row.title = NSLocalizedString("done",comment: "done")
            }
    }
    
    private func save() {
        let values = form.values()
        let name = values["name"] as! String?
        let birth = values["birth"] as! String?
        let image = values["image"] as! UIImage?
        let imageData = UIImagePNGRepresentation(image ?? UIImage())
        let shouldSync = values["shouldSync"] as! Bool?
        
        switch formMode {
        case .new:
            PeopleToSave.insert(into: context, name: name ?? "", birth: birth ?? "01-01", picData: imageData, shouldSync: shouldSync ?? false)
        case .edit:
            do {
                persistentPerson?.name = name ?? ""
                persistentPerson?.birth = birth ?? "01-01"
                persistentPerson?.picData = imageData
                persistentPerson?.shouldSync = shouldSync ?? false
                try context.save()
                
                // Remember to modify the notifications
                
            } catch {
                let cfView = CFNotifyView.cyberWith(title: NSLocalizedString("failedToSave", comment: "FailedToSave"), body: error.localizedDescription, theme: .fail(.light))
                var config = CFNotify.Config()
                config.initPosition = .top(.center)
                config.appearPosition = .top
                CFNotify.present(config: config, view: cfView)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        if indexPath.section == 4 {
            save()
            navigationController?.popViewController(animated: true)
            SKStoreReviewController.requestReview()
        }
    }
    
}
