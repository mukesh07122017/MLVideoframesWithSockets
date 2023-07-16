//
//  ExerciseListVC.swift
//  T2DML
//
//  Created by Mahi Sharma on 06/12/21.
//

import UIKit

class ExerciseListVC: UIViewController,UITableViewDataSource,UITableViewDelegate {

    var arrayxercise = [AnyObject]()
    @IBOutlet weak var tbl_exe: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let exerciseID1 :[String : Any] = ["Name": "Left elbow flexion", "Id" : "PTG001"]
        self.arrayxercise.append(exerciseID1 as AnyObject)
        
        let exerciseID2 :[String : Any] = ["Name": "Right elbow flexion", "Id" : "PTG002"]
        self.arrayxercise.append(exerciseID2 as AnyObject)
        
        let exerciseID3 :[String : Any] = ["Name": "Left shoulder flexion", "Id" : "PTG003"]
        self.arrayxercise.append(exerciseID3 as AnyObject)
        
        let exerciseID4 :[String : Any] = ["Name": "Right shoulder flexion", "Id" : "PTG004"]
        self.arrayxercise.append(exerciseID4 as AnyObject)
        
        let exerciseID5 :[String : Any] = ["Name": "Left Hip arom flexion", "Id" : "PTG005"]
        self.arrayxercise.append(exerciseID5 as AnyObject)
        
        let exerciseID6 :[String : Any] = ["Name": "Right Hip arom flexion", "Id" : "PTG006"]
        self.arrayxercise.append(exerciseID6 as AnyObject)
        
          
        // Do any additional setup after loading the view.
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return arrayxercise.count
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tbl_exe.dequeueReusableCell(withIdentifier: "ExerciseListCell_ID", for: indexPath) as! ExerciseListCell
        let obj = arrayxercise[indexPath.row] as! [String : AnyObject]
        cell.lbl_exe.text = obj["Name"] as? String
           
        
        return cell
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        
        return 70
        
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tbl_exe.deselectRow(at: indexPath, animated: true)
        let exerciseView = self.storyboard?.instantiateViewController(withIdentifier: "ViewController_ID") as! ViewController
        let obj = arrayxercise[indexPath.row] as! [String : AnyObject]
        exerciseView.exerciseID = obj["Id"] as? String
        self.navigationController?.pushViewController(exerciseView, animated: true)
        
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
