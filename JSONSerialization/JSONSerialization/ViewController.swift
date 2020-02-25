//
//  ViewController.swift
//  JSONSerialization
//
//  Created by test on 2/25/20.
//  Copyright © 2020 test. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

       guard let path = Bundle.main.path(forResource: "VOR1", ofType: "JSON") else {
           return
       }
       guard let str = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue ) else {
           return
       }
       guard let jsonObject = try? JSONSerialization.jsonObject(with: str.data(using: String.Encoding.utf8.rawValue)!, options: []) else {
           return
       }

       if let dictionary = jsonObject as? [String:Any] {
           if let trajectories = dictionary["trajectory"] as? [Any] {

               let trajectory = trajectories[1]
               
               if let stao = trajectory as? [String:[Float]] {
                   print("end")
               }
               
               for trajectory in trajectories {
                   if let cols = trajectory as? [String:[Float]] {
                       guard let col0 = cols["c0"], let col1 = cols["c1"], let col2 = cols["c2"], let col3 = cols["c3"] else {
                           return
                       }

                       guard col0.count == 4 && col1.count == 4 && col2.count == 4 && col3.count == 4 else {
                           return
                       }

                       print(col0)
                       print(col1)
                       print(col2)
                       print(col3)
                   }
               }

               
               
               print("end")
           }
           
           
           print("end")
       }
       
       
       print("end")
        
        
        
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

