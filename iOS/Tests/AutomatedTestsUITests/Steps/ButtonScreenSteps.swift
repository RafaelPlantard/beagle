//
//  ButtonScreenSteps.swift
//  AutomatedTestsUITests
//
//  Created by Debliane Sousa on 7/20/20.
//  Copyright © 2020 ZUP IT SERVICOS EM TECNOLOGIA E INOVACAO SA. All rights reserved.
//

import Foundation
import XCTest

class ButtonScreenSteps: NSObject {
    
    func ButtonScreenSteps() {
    
        let screen = ScreenRobot()
                
        MatchAll("^App is running$") { (args, userInfo) -> Void in
            XCTAssertTrue(ScreenElements.MAIN_HEADER.element.exists)
        }
        
        Given("^Given the app will load http://localhost:8080/button$") { (args, userInfo) -> Void in
            XCTAssertTrue(ScreenElements.MAIN_HEADER.element.exists)
            XCTAssertTrue(ScreenElements.BUTTON_SCREEN_HEADER.element.exists)
        }
        
        When("I click on a component with a valid style attribute configured$") { (args, userInfo) -> Void in
            screen.clickOnButtonWithStyle()
        }

        When("I click on a component with a valid action attribute configured$") { (args, userInfo) -> Void in
            screen.clickOnButtonWithAction()
         }

         Then("all my button components should render their respective text attributes correctly$") { (args, userInfo) -> Void in
            screen.renderTextAttributeCorrectly()
         }

         Then("component should render the action attribute correctly$") { (args, userInfo) -> Void in
            screen.renderActionAttributeCorrectly()
         }
        
    }

}
