//
//  MyChoresViewController.swift
//  IntelliKitchen_Myfood
//
//  Created by D.WANG on 5/16/20.
//  Copyright © 2020 D.WANG. All rights reserved.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore
import UIKit

class MyChoresViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var choresList: UITableView!
    
    
    var ref: DatabaseReference?
    var databaseHandle: DatabaseHandle?
    var choreName = [String]()
    var lastDone = [String]()
    var frequency = [String]()
    var chores = [String]()
    var remindDates = [String]()
    var remindOrNot = [Bool]()
    var editTaskName: UITextField?
    var editLastDoneDate: UITextField?
    var editFrequency: UITextField?
    private var datePicker: UIDatePicker?
    private var pickerView: UIPickerView?
    let db = Firestore.firestore()
    var remindDate: String = ""
    var row: Int = 0
    var currentUid = Auth.auth().currentUser!.uid
    
    let frequencyStr = ["Once a day", "Twice a day", "Once a week", "Twice a week", "Once a month", "Twice a month"]
    
    override func viewDidLoad() {
        /*ref = Database.database().reference()
        databaseHandle = ref?.child("Chores").observe(.childAdded, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            self.choreName.append(value?.value(forKey: "ChoreName") as! String)
            self.lastDone.append(value?.value(forKey: "LastDone") as? String ?? "")
            self.frequency.append(value?.value(forKey: "Frequency") as? String ?? "")
        })*/

        db.collection("users").document(currentUid).collection("chores").getDocuments { (snapshot, error) in
            for document in snapshot!.documents{
                let data = document.data()
                let name = data["choreName"] as? String ?? ""
                let ldDate = data["lastDone"] as? String ?? ""
                let freq = data["frequency"] as? String ?? ""
                let rDate = data["remindDate"] as? String ?? ""
                let rOrNot = data["remindOrNot"] as? Bool ?? false
                self.choreName.append(name)
                self.lastDone.append(ldDate)
                self.frequency.append(freq)
                self.remindDates.append(rDate)
                self.remindOrNot.append(rOrNot)
            }
            self.choresList.reloadData()
            print(self.remindDates)
        }
        
        pickerView = UIPickerView()
        pickerView?.dataSource = self
        pickerView?.delegate = self
        datePicker = UIDatePicker()
        datePicker?.datePickerMode = .date
        datePicker?.addTarget(self, action: #selector(self.dateChanged(datePicker:)), for: .valueChanged)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MyChoresViewController.viewTapped(gestureRecognizer:)))
        
        view.addGestureRecognizer(tapGesture)
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer){
              view.endEditing(true)
    }
       
    @objc func dateChanged(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        if( NSDate.init().laterDate(datePicker.date) == datePicker.date){
            view.endEditing(true)
        } else {
            editLastDoneDate?.text = dateFormatter.string(from: datePicker.date)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return frequencyStr[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return frequencyStr.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        editFrequency?.text = frequencyStr[row]
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MyChoresViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                      trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
       {
           // Write action code for the trash
           let DeleteAction = UIContextualAction(style: .normal, title:  "Delete", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Update action ...")
            let currentUid = Auth.auth().currentUser!.uid
            var choreRef = self.db.collection("users").document(currentUid).collection("chores").document(self.choreName[indexPath.row])
            choreRef.getDocument { (document, error) in
                if error == nil {
                    if document != nil && document!.exists {
                        let documentData = document?.data()
                        let remindOrNot = documentData?["remindOrNot"] as! Bool
                        if remindOrNot{
                            let reminderID = documentData?["reminderID"] as! String
                            let center = UNUserNotificationCenter.current()
                            center.removePendingNotificationRequests(withIdentifiers: [reminderID])
                        }
                        self.db.collection("users").document(currentUid).collection("chores").document(self.choreName[indexPath.row]).delete()
                        self.choreName.remove(at: indexPath.row)
                        self.lastDone.remove(at: indexPath.row)
                        self.frequency.remove(at: indexPath.row)
                        self.choresList.reloadData()
                    }
                }
            }

            self.createAlert(title: "Delete success!", message: "Successfully delete the task")
               success(true)
           })
        DeleteAction.backgroundColor = UIColor.init(red: 253/255, green: 131/255, blue: 131/255, alpha: 0.9)

           // Write action code for the Flag
           let SkipAction = UIContextualAction(style: .normal, title:  "Skip", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Update action ...")
            
            var choreRef = self.db.collection("users").document(self.currentUid).collection("chores").document(self.choreName[indexPath.row])
            choreRef.getDocument { (document, error) in
                if error == nil {
                    if document != nil && document!.exists {
                        let documentData = document?.data()
                        let remindOrNot = documentData?["remindOrNot"] as! Bool
                        if remindOrNot{
                            let reminderID = documentData?["reminderID"] as! String
                            let center = UNUserNotificationCenter.current()
                            center.removePendingNotificationRequests(withIdentifiers: [reminderID])
                        }
                        let choreName = documentData?["choreName"] as! String
                        let lastDone = documentData?["lastDone"] as! String
                        let remindDate = documentData?["remindDate"] as! String
                        let frequency = documentData?["frequency"] as! String
                        let newRemindDate = self.updateRemindDate(date: remindDate, freq: frequency)
                        var newRequestID = ""
                        if remindOrNot{
                            newRequestID = self.pushNotification(chore: choreRef, choreName: choreName, frequency: frequency, lastDone: lastDone, remindDate: remindDate)
                        }
                        choreRef.setData(["choreName": choreName, "frequency": frequency, "lastDone": lastDone, "remindDate": newRemindDate, "remindOrNot": remindOrNot, "reminderID": newRequestID])
                        self.choresList.reloadData()
                    }
                }
            }
            
        
            self.createAlert(title: "Skip success!", message: "Successfully skip the task")
                success(true)
           })
        SkipAction.backgroundColor = UIColor.init(red: 255/255, green: 139/255, blue: 23/255, alpha: 0.75)

           // Write action code for the More
           let RemindAction = UIContextualAction(style: .normal, title:  "Remind", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
               print("Update action ...")
            var choreRef = self.db.collection("users").document(self.currentUid).collection("chores").document(self.choreName[indexPath.row])
            choreRef.getDocument { (document, error) in
                if error == nil {
                    if document != nil && document!.exists {
                        let documentData = document?.data()
                        let choreName = documentData?["choreName"] as! String
                        let lastDone = documentData?["lastDone"] as! String
                        var remindDate = documentData?["remindDate"] as! String
                        let frequency = documentData?["frequency"] as! String
                        var date = Date()
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MM/dd/yyyy"
                        let remindDateObj = formatter.date(from: remindDate)
                        print("----------------------------------")
                        print(formatter.string(from: remindDateObj!))
                        print(formatter.string(from: date))
                        let reChoose = remindDateObj ?? date < date
                        if reChoose {
                            date = date.addingTimeInterval(86400) // add a day
                            remindDate = formatter.string(from: date)
                            self.pushNotification(chore: choreRef, choreName: choreName, frequency: frequency, lastDone: lastDone, remindDate: remindDate)
                            self.createAlert(title: "Your remind date has passed", message: "We have successfully set your remind date to tomorrow (" + remindDate + ")!")
                            
                        } else {
                            remindDate = formatter.string(from: date)
                            self.pushNotification(chore: choreRef, choreName: choreName, frequency: frequency, lastDone: lastDone, remindDate: remindDate)
                            self.createAlert(title: "Remind success!", message: "Successfully set the reminder")
//                               success(true)
                        }
                        
                    }
                }
            }
//            print(choreName)
//            self.pushNotification(chore: thisChore)
//            print(indexPath.row)

           })
        RemindAction.backgroundColor = UIColor.init(red: 255/255, green: 211/255, blue: 0/255, alpha: 0.85)
        
           let FinishAction = UIContextualAction(style: .normal, title:  "Finish", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
               print("Update action ...")
            var choreRef = self.db.collection("users").document(self.currentUid).collection("chores").document(self.choreName[indexPath.row])
            choreRef.getDocument { (document, error) in
                if error == nil {
                    if document != nil && document!.exists {
                        let documentData = document?.data()
                        let remindOrNot = documentData?["remindOrNot"] as! Bool
                        if remindOrNot{
                             let reminderID = documentData?["reminderID"] as! String
                             let center = UNUserNotificationCenter.current()
                             center.removePendingNotificationRequests(withIdentifiers: [reminderID])
                         }
                        
                        // ---------------------------------
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MM/dd/yyyy"
                        if(self.frequency[indexPath.row] == "Once a day" || self.frequency[indexPath.row] == "Twice a day"){
                            var dateObj = dateFormatter.date(from: self.remindDates[indexPath.row])
                            print(indexPath.row)
                            dateObj = dateObj?.addingTimeInterval(86400)
                            self.remindDate = dateFormatter.string(from: dateObj!)
                        }
                        
                        if(self.frequency[indexPath.row] == "Once a week"){
                            var dateObj = dateFormatter.date(from: self.remindDates[indexPath.row])
                            print(indexPath.row)
                            dateObj = dateObj?.addingTimeInterval(604800)
                            self.remindDate = dateFormatter.string(from: dateObj!)
                        }
                        
                        if(self.frequency[indexPath.row] == "Twice a week"){
                            var dateObj = dateFormatter.date(from: self.remindDates[indexPath.row])
                            print(indexPath.row)
                            dateObj = dateObj?.addingTimeInterval(302400)
                            self.remindDate = dateFormatter.string(from: dateObj!)
                        }
                        
                        if(self.frequency[indexPath.row] == "Once a month"){
                            var dateObj = dateFormatter.date(from: self.remindDates[indexPath.row])
                            print(indexPath.row)
                            dateObj = dateObj?.addingTimeInterval(2592000)
                            self.remindDate = dateFormatter.string(from: dateObj!)
                           
                        }
                        
                        if(self.frequency[indexPath.row] == "Twice a month"){
                            var dateObj = dateFormatter.date(from: self.remindDates[indexPath.row])
                            print(indexPath.row)
                            dateObj = dateObj?.addingTimeInterval(1296000)
                            self.remindDate = dateFormatter.string(from: dateObj!)
                        }
                        // ---------------------------------
                        if remindOrNot {
                            let choreName = documentData?["choreName"] as! String
                            let lastDone = documentData?["lastDone"] as! String
                            let remindDate = documentData?["remindDate"] as! String
                            let frequency = documentData?["frequency"] as! String
                            let date = Date()
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MM/dd/yyyy"
                            self.lastDone[indexPath.row] = formatter.string(from: date)
                            let requestID = self.pushNotification(chore: choreRef, choreName: choreName, frequency: frequency, lastDone: lastDone, remindDate: remindDate)
                            self.db.collection("users").document(self.currentUid).collection("chores").document(self.choreName[indexPath.row]).setData(["choreName":self.choreName[indexPath.row], "lastDone": self.lastDone[indexPath.row], "frequency": self.frequency[indexPath.row], "remindDate": self.remindDate, "remindOrNot": self.remindOrNot[indexPath.row], "reminderID": requestID])
                        }
                        self.choresList.reloadData()
                    }
                }
            }
            
            
                self.createAlert(title: "Finish success!", message: "Successfully finish the task")
                success(true)
           })
        FinishAction.backgroundColor =  UIColor.init(red: 101/255, green: 154/255, blue: 65/255, alpha: 0.75)


           return UISwipeActionsConfiguration(actions: [DeleteAction,SkipAction,RemindAction,FinishAction])
       }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return choreName.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = choresList.dequeueReusableCell(withIdentifier: "cell") as! MyChoresTableViewCell
        //let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")
        /*chores.append(choreName[indexPath.row] + "       " + lastDone[indexPath.row] + "       " + frequency[indexPath.row])*/
        
        cell.taskNameLabel.text = choreName[indexPath.row]
        cell.frequencyLabel.text = frequency[indexPath.row]
        cell.lastDoneLabel.text = lastDone[indexPath.row]
        cell.taskNameLabel.adjustsFontSizeToFitWidth = true
        cell.frequencyLabel.adjustsFontSizeToFitWidth = true
        cell.lastDoneLabel.adjustsFontSizeToFitWidth = true
        //cell.textLabel?.adjustsFontSizeToFitWidth = true
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Edit task", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: editTaskName)
        alertController.addTextField(configurationHandler: editLastDoneDate)
        alertController.addTextField(configurationHandler: editFrequency)
        row = indexPath.row
        
        let okAction = UIAlertAction(title: "Save", style: .default, handler: self.okHandler)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true)
        print(indexPath.row)
    }
    
    func editTaskName(textField: UITextField!) {
        editTaskName = textField
        editTaskName?.placeholder = "Task name"
    }
    func editLastDoneDate(textField: UITextField!) {
        editLastDoneDate = textField
        editLastDoneDate?.inputView = datePicker
        editLastDoneDate?.placeholder = "Last Done Date"
    }
    func editFrequency(textField: UITextField!) {
        editFrequency = textField
        editFrequency?.inputView = pickerView
        editFrequency?.placeholder = "Frequency"
    }
    
    func okHandler(alert: UIAlertAction) {
        if(editTaskName?.text == "" || editFrequency?.text == "" || editLastDoneDate?.text == ""){
            print("error")
        } else {
            //backend deal with data change here
            db.collection("users").document(currentUid).collection("chores").document(choreName[row]).delete()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            if(editFrequency?.text == "Once a day" || editFrequency?.text == "Twice a day") {
                var dateObj = dateFormatter.date(from: editLastDoneDate?.text ?? "")
                dateObj = dateObj?.addingTimeInterval(86400)
                remindDate = dateFormatter.string(from: dateObj!)
            }
            if(editFrequency?.text == "Once a week") {
                var dateObj = dateFormatter.date(from: editLastDoneDate?.text ?? "")
                dateObj = dateObj?.addingTimeInterval(604800)
                remindDate = dateFormatter.string(from: dateObj!)
            }
            if(editFrequency?.text == "Twice a week") {
                var dateObj = dateFormatter.date(from: editLastDoneDate?.text ?? "")
                dateObj = dateObj?.addingTimeInterval(302400)
                remindDate = dateFormatter.string(from: dateObj!)
            }
            if(editFrequency?.text == "Once a month") {
                var dateObj = dateFormatter.date(from: editLastDoneDate?.text ?? "")
                dateObj = dateObj?.addingTimeInterval(2592000)
                remindDate = dateFormatter.string(from: dateObj!)
            }
            if(editFrequency?.text == "Twice a month") {
                var dateObj = dateFormatter.date(from: editLastDoneDate?.text ?? "")
                dateObj = dateObj?.addingTimeInterval(1296000)
                remindDate = dateFormatter.string(from: dateObj!)
            }
            db.collection("users").document(currentUid).collection("chores").document(editTaskName?.text ?? "").setData(["choreName":editTaskName?.text ?? "", "lastDone":editLastDoneDate?.text ?? "", "frequency":editFrequency?.text ?? "", "remindDate":remindDate, "remindOrNot": false])
            
            //data change appear in frontend
            choreName.remove(at: row)
            lastDone.remove(at: row)
            frequency.remove(at: row)
            remindOrNot.remove(at: row)
            remindDates.remove(at: row)
            choreName.append(editTaskName?.text ?? "")
            lastDone.append(editLastDoneDate?.text ?? "")
            frequency.append(editFrequency?.text ?? "")
            remindOrNot.append(false)
            remindDates.append(remindDate)
            choresList.reloadData()
        
        }
    }
    
    func createAlert(title:String, message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {(action) in alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func pushNotification (chore:  DocumentReference, choreName: String, frequency:String, lastDone:String, remindDate:String) -> String{
        let choreRemindingDate = remindDate
        let year = Int(choreRemindingDate.split(separator: "/")[2])
        let day = Int(choreRemindingDate.split(separator: "/")[1])
        let month = Int(choreRemindingDate.split(separator: "/")[0])
        
        
        // Notification
        // Step 1: Ask for permission
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
        }

        
        // Step 2: Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Chores Reminder from IntelliKitchen"
        content.body = "You have to do " + choreName + " on " + remindDate

        // Step 3: Create the notification trigger
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.timeZone = TimeZone(abbreviation: "PST")
        dateComponents.hour = 15
        dateComponents.minute = 27

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // Step 4: Create the request

        let uuidString = UUID().uuidString

        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        let requestID = request.identifier // Need to save to Firebase
        print("after request")

        // Step 5: Register the request
        center.add(request) { (error) in
            // Check the error parameter and handle any errors
        }
        
        // update information in databse
        chore.setData(["choreName": choreName, "frequency": frequency, "lastDone": lastDone, "remindDate": remindDate, "remindOrNot": true, "reminderID": requestID])
        return requestID
    }
    
    func updateRemindDate(date: String, freq: String) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        if(freq == "Once a day" || freq == "Twice a day"){
            var dateObj = dateFormatter.date(from: date)
            dateObj = dateObj?.addingTimeInterval(86400)
            let remindDate = dateFormatter.string(from: dateObj!)
            return remindDate
        }
        else if(freq == "Once a week"){
            print(date)
            print(freq)
            var dateObj = dateFormatter.date(from: date)
            dateObj = dateObj?.addingTimeInterval(604800)
            let remindDate = dateFormatter.string(from: dateObj!)
            return remindDate
        }
        else if(freq == "Twice a week"){
            var dateObj = dateFormatter.date(from: date)
            dateObj = dateObj?.addingTimeInterval(302400)
            let remindDate = dateFormatter.string(from: dateObj!)
            return remindDate
        }
        else if(freq == "Once a month"){
            var dateObj = dateFormatter.date(from: date)
            dateObj = dateObj?.addingTimeInterval(2592000)
            let remindDate = dateFormatter.string(from: dateObj!)
            return remindDate
        }
        else{
            var dateObj = dateFormatter.date(from: date)
            dateObj = dateObj?.addingTimeInterval(1296000)
            let remindDate = dateFormatter.string(from: dateObj!)
            return remindDate
        }
    }
    
    
}
