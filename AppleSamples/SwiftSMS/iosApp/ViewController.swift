//
//  ViewController.swift
//  iosApp
//
//  Created by JazzG on 8/16/20.
//

import UIKit
import MessageUI
import Alamofire


/**********************************************

REPLACE "staotemp" with correct info.

 ********************************************* */

class ViewController: UIViewController, MFMessageComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func OnSend(_ sender: Any) {
        print("here")

         let accountSID = "staotemp"
           let authToken = "staotemp"


          let url = "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Messages"
          let parameters = ["From": "staotemp", "To": "staotemp", "Body": "Hello from zephyr tao!"]

          Alamofire.request(url, method: .post, parameters: parameters)
            .authenticate(user: accountSID, password: authToken)
            .responseJSON { response in
              debugPrint(response)
          }

          RunLoop.main.run()


    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {

        dismiss(animated: true, completion: nil)

    }


}

