//
//  SchoolDetailsViewController.swift
//  StamfordSchoolFinder
//
//  Created by Michael Ramos on 9/19/15.
//  Copyright © 2015 Michael Ramos. All rights reserved.
//

import UIKit

class SchoolDetailsViewController: UIViewController {
    
    var currentSchool:String!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = currentSchool
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
