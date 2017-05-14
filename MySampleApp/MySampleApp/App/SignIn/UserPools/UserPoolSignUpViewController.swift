//
//  UserPoolSignUpViewController.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.15
//
//

import Foundation
import UIKit
import AWSMobileHubHelper
import AWSCognitoIdentityProvider
import AWSCognitoUserPoolsSignIn

class UserPoolSignUpViewController: UIViewController {
    
    @IBOutlet weak var formView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var pool: AWSCognitoIdentityUserPool?
    var sentTo: String?
    
    var passwordRow : FormTableCell?
    var userNameRow : FormTableCell?
    var emailRow : FormTableCell?
    var phoneNumberRow: FormTableCell?
    var tableDelegate : FormTableDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUp()
        self.pool = AWSCognitoIdentityUserPool.init(forKey: AWSCognitoUserPoolsSignInProviderKey)
    }
    
    func setUp() {
        passwordRow = FormTableCell(placeHolder: "Password", type: InputType.password)
        userNameRow = FormTableCell(placeHolder: "User Name", type: InputType.text)
        emailRow = FormTableCell(placeHolder: "Email", type: InputType.text)
        phoneNumberRow = FormTableCell(placeHolder: "Phone number", type: InputType.text)
        
        tableDelegate = FormTableDelegate()
        tableDelegate?.add(cell: userNameRow!)
        tableDelegate?.add(cell: passwordRow!)
        tableDelegate?.add(cell: emailRow!)
        tableDelegate?.add(cell: phoneNumberRow!)
        tableView?.delegate = tableDelegate
        tableView?.dataSource = tableDelegate
        tableView.reloadData()
        
        UserPoolsUIHelper.setUpFormShadow(view: formView)
        
        self.setUpBackground()
    }
    
    
    func setUpBackground() {
        self.view.backgroundColor = UIColor.white
        let backgroundImageView = UIImageView(frame: CGRect(x: 0, y:0, width: self.view.frame.width, height: self.formView.center.y))
        backgroundImageView.backgroundColor = backgroundImageColor
        backgroundImageView.autoresizingMask = UIViewAutoresizing.flexibleWidth
        self.title = "Sign Up"
        self.view.insertSubview(backgroundImageView, at: 0)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let signUpConfirmationViewController = segue.destination as? UserPoolSignUpConfirmationViewController {
            signUpConfirmationViewController.sentTo = self.sentTo
            signUpConfirmationViewController.user = self.pool?.getUser((self.tableDelegate?.getValue(tableView, for: userNameRow!)!)!)
        }
    }
    
    @IBAction func onSignUpClicked(_ sender: Any) {

        guard let userNameValue = self.tableDelegate?.getValue(tableView, for: userNameRow!), !userNameValue.isEmpty,
            let passwordValue = self.tableDelegate?.getValue(tableView, for: passwordRow!), !passwordValue.isEmpty else {
                let alert = UIAlertController(title: "Missing Required Fields",
                                              message: "Username / Password are required for registration.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion:nil)
            return
        }
        
        var attributes = [AWSCognitoIdentityUserAttributeType]()
        
        if let phoneValue = self.tableDelegate?.getValue(tableView, for: phoneNumberRow!), !phoneValue.isEmpty {
            let phone = AWSCognitoIdentityUserAttributeType()
            phone?.name = "phone_number"
            phone?.value = phoneValue
            attributes.append(phone!)
        }
        
        if let emailValue = self.tableDelegate?.getValue(tableView, for: emailRow!), !emailValue.isEmpty {
            let email = AWSCognitoIdentityUserAttributeType()
            email?.name = "email"
            email?.value = emailValue
            attributes.append(email!)
        }
        
        //sign up the user
        self.pool?.signUp(userNameValue, password: passwordValue, userAttributes: attributes, validationData: nil).continueWith {[weak self] (task: AWSTask<AWSCognitoIdentityUserPoolSignUpResponse>) -> AnyObject? in
            guard let strongSelf = self else { return nil }
            DispatchQueue.main.async(execute: { 
                if let error = task.error as? NSError {
                    let alert = UIAlertController(title: error.userInfo["__type"] as? String,
                                                  message:error.userInfo["message"] as? String,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    strongSelf.present(alert, animated: true, completion:nil)
                    return
                }
                
                if let result = task.result as AWSCognitoIdentityUserPoolSignUpResponse! {
                    // handle the case where user has to confirm his identity via email / SMS
                    if (result.user.confirmedStatus != AWSCognitoIdentityUserStatus.confirmed) {
                        strongSelf.sentTo = result.codeDeliveryDetails?.destination
                        strongSelf.performSegue(withIdentifier: "SignUpConfirmSegue", sender:sender)
                    } else {
                        let alert = UIAlertController(title: "Registration Complete",
                                                      message: "Registration was successful.",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(action) in
                            _ = strongSelf.navigationController?.popToRootViewController(animated: true)
                        }))
                        strongSelf.present(alert, animated: true, completion: nil)
                    }
                }
                
            })
            return nil
        }
    }
}
